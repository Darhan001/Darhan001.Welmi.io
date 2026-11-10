import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lumina/app/lock_screen.dart';
import 'package:lumina/app/push_routes.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/biometric_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/services/push_notification_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/core/theme/locale_provider.dart';
import 'package:lumina/core/theme/theme_mode_controller.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/core/widgets/splash_screen.dart';
import 'package:lumina/features/main/presentation/pages/main_shell.dart';
import 'package:lumina/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/core/services/notifications/notification_service.dart';

/// Корневой виджет: тема, язык, авторизация, блокировка по отпечатку.
class WelmiApp extends StatefulWidget {
  const WelmiApp({super.key, required this.themeMode});

  final ThemeModeController themeMode;

  @override
  State<WelmiApp> createState() => _WelmiAppState();
}

class _WelmiAppState extends State<WelmiApp> with WidgetsBindingObserver {
  final AuthService _auth = AuthService();
  final BiometricService _biometric = BiometricService();
  StreamSubscription<AuthState>? _authSub;

  bool _isCheckingAuth = true;
  bool _onboardingComplete = false;
  bool _isLocked = false;
  bool _widgetLaunchHandled = false;

  /// Пользователь, для которого уже выполнена стартовая загрузка.
  String? _startedForUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthState();
    PushNotificationService().onRouteTap = openPushRoute;

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final session = data.session;
      if (session != null) {
        _auth.syncFromSession(session.user);
        // Полная загрузка — только при смене пользователя. initialSession
        // дублировал запуск, а tokenRefreshed (примерно раз в час) заново
        // грузил все данные и повторно блокировал экран отпечатком.
        if (session.user.id != _startedForUserId) _checkAuthState();
      } else {
        // Токен устройства отвязывается в confirmAndSignOut до выхода:
        // здесь сессии уже нет, и удаление отклонил бы RLS.
        setState(() {
          _auth.reset();
          _startedForUserId = null;
          _onboardingComplete = false;
          _isCheckingAuth = false;
          _isLocked = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Возвращаясь в приложение, заново ставим напоминания в AlarmManager:
  /// некоторые прошивки сбрасывают будильники при агрессивном энергосбережении,
  /// а пользователь мог выдать разрешение в системных настройках.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || kIsWeb) return;
    if (!_auth.isSignedIn) return;
    if (_isLocked) return;
    // На холодном старте инициализация ещё может идти — расписание
    // восстановит сама bootstrap(), повторно инициализировать не нужно.
    if (!NotificationService().isInitialized) return;
    final tracker = DailyTracker();
    final reached =
        tracker.goalWaterMl > 0 && tracker.totalWaterMl >= tracker.goalWaterMl;
    NotificationService().rescheduleAll(waterGoalReached: reached);
  }

  Future<void> _checkAuthState() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) _auth.syncFromSession(session.user);
    _startedForUserId = session?.user.id;

    if (_auth.isSignedIn && _auth.userId != null) {
      await UserDataService().loadAll();
      await UnitsService.instance.adoptFromProfile(
        UserDataService().profile?.unitsSystem,
      );
      await DailyTracker().loadToday();

      if (!kIsWeb) await PushNotificationService().registerTokenIfNeeded();

      if (!kIsWeb) {
        HealthSyncService().checkAuth().then((authorized) {
          if (authorized) {
            HealthSyncService().syncToday();
          }
        });
      }

      if (!kIsWeb) {
        final bioEnabled = await _biometric.isEnabled();
        if (bioEnabled) {
          if (mounted) setState(() => _isLocked = true);
          if (!await _unlock()) return;
        }
      }
    }

    await _finishStartup();
  }

  /// Запрашивает отпечаток. Корневой виджет находится выше MaterialApp,
  /// поэтому тексты берём через lookupAppLocalizations, а не из context.
  Future<bool> _unlock() async {
    final loc = lookupAppLocalizations(localeProvider.locale);
    final authenticated = await _biometric.authenticateWith(loc);
    if (authenticated) {
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _isLocked = false);
    }
    return authenticated;
  }

  /// Повторная попытка с экрана блокировки: раньше кнопка заново
  /// запускала всю загрузку данных и синхронизацию здоровья.
  Future<void> _retryUnlock() async {
    if (await _unlock()) await _finishStartup();
  }

  Future<void> _finishStartup() async {
    var onboarded = await _auth.isOnboardingComplete();
    if (!onboarded && _auth.isSignedIn && _auth.userId != null) {
      try {
        final profile = await SupabaseService().getProfile(_auth.userId!);
        if (profile != null) {
          onboarded = true;
          await _auth.markOnboardingComplete();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Profile check failed: $e');
      }
    }

    await _handleWidgetLaunch();

    if (!mounted) return;
    setState(() {
      _onboardingComplete = onboarded;
      _isCheckingAuth = false;
    });
  }

  Future<void> _handleWidgetLaunch() async {
    if (kIsWeb || _widgetLaunchHandled) return;
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri == null) return;
      _widgetLaunchHandled = true;

      if (uri.host == 'add_water' && _auth.isSignedIn) {
        // Значение приходит из URI запуска — ограничиваем разумным объёмом
        // одного приёма, чтобы ссылка не записала произвольные литры.
        final ml = (int.tryParse(uri.queryParameters['ml'] ?? '') ?? 250).clamp(
          50,
          1000,
        );
        await DailyTracker().addWater(ml);
        HapticFeedback.mediumImpact();
        await WidgetService().updateAll();
      }
    } catch (e) {
      debugPrint('⚠️ Widget launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([localeProvider, widget.themeMode]),
      builder: (context, _) {
        final themeMode = widget.themeMode.mode;
        return ThemeProvider(
          themeMode: themeMode,
          onThemeChanged: widget.themeMode.setMode,
          child: MaterialApp(
            navigatorKey: PushNotificationService.navigatorKey,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (locale, supportedLocales) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == locale?.languageCode) {
                  return supported;
                }
              }
              return const Locale('ru');
            },
            builder: DevicePreview.appBuilder,
            debugShowCheckedModeBanner: false,
            title: 'Welmi',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: _buildHome(),
          ),
        );
      },
    );
  }

  Widget _buildHome() {
    if (_isCheckingAuth) return const SplashScreen();
    if (_isLocked) return LockScreen(onUnlock: _retryUnlock);

    if (_onboardingComplete) return const MainShell();
    return const OnboardingPage();
  }
}
