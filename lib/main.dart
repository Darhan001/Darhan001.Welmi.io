import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lumina/core/config/app_config.dart';
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/services/notification_service.dart';
import 'package:lumina/core/services/push_notification_service.dart';
import 'package:lumina/core/services/biometric_service.dart';
import 'package:lumina/core/services/widget_service.dart';
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/core/theme/locale_provider.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/core/widgets/splash_screen.dart';
import 'package:lumina/features/main/presentation/pages/main_shell.dart';
import 'package:lumina/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:lumina/features/water/presentation/pages/water_page.dart';
import 'package:lumina/features/diary/presentation/pages/diary_page.dart';
import 'package:lumina/features/progress/presentation/pages/progress_page.dart';
import 'package:lumina/features/weight/presentation/pages/weight_page.dart';

// Конфигурация приложения (ключи из env.json) вынесена в
// `lib/core/config/app_config.dart`. Ключи в коде не хранятся,
// а подставляются флагом --dart-define-from-file=env.json.

/// Global locale provider singleton
final localeProvider = LocaleProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  // Обязательна только конфигурация Supabase. Отсутствие AI/Sentry-ключей
  // запуск НЕ блокирует — приложение работает с fallback-логикой.
  if (!isSupabaseConfigured) {
    debugPrint('❌ Конфигурация Supabase не задана: '
        '${missingRequiredEnvKeys.join(', ')}. Запустите с '
        '--dart-define-from-file=env.json');
    runApp(_ConfigErrorApp(missingKeys: missingRequiredEnvKeys));
    return;
  }

  debugPrint('✅ Конфигурация: ${configDiagnostics()}');

  final useSentry = !kIsWeb && sentryDsn.isNotEmpty && sentryDsn.startsWith('https://');
  if (useSentry) {
    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = 0.1;
          options.environment = kReleaseMode ? 'production' : 'development';
        },
        appRunner: _bootstrapApp,
      );
    } catch (e) {
      debugPrint('❌ Sentry init error: $e');
      await _bootstrapApp();
    }
  } else {
    await _bootstrapApp();
  }
}

Future<void> _bootstrapApp() async {
  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
    await SupabaseService().initialize();
    AiService().initialize(
      nutritionApiKey: geminiNutritionApiKey,
      chatApiKey: openRouterApiKey,
      scannerApiKey: scannerApiKey,
    );

    try {
      final notifications = NotificationService();
      await notifications.initialize();
      if (!kIsWeb) {
        // Разрешение — только по требованию пользователя (настройки/онбординг).
        // Если разрешение уже выдано — восстанавливаем расписание
        // (стабильные id перезаписывают прежние, дубликаты не создаются).
        final granted = await notifications.checkPermissions();
        if (granted) await notifications.rescheduleAll();
      }
    } catch (e) {
      debugPrint('❌ Notification Error: $e');
    }

    if (!kIsWeb) {
      try {
        await PushNotificationService().initialize();
      } catch (e) {
        debugPrint('❌ Push Error: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ Ошибка инициализации: $e');
  }

  if (kReleaseMode) {
    runApp(const WelmiApp());
  } else {
    runApp(DevicePreview(enabled: true, builder: (context) => const WelmiApp()));
  }
}

/// Экран, показываемый если обязательная конфигурация (Supabase) не передана.
/// Показывается только когда отсутствует SUPABASE_URL / SUPABASE_ANON_KEY —
/// отсутствие необязательных ключей (AI, Sentry) приложение не блокирует.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.missingKeys});

  /// Имена отсутствующих обязательных переменных окружения.
  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) {
    final missing = missingKeys.isEmpty
        ? kRequiredEnvKeys.join(', ')
        : missingKeys.join(', ');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Welmi',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings_remote_rounded,
                    size: 72, color: Color(0xFF4A8C5C)),
                const SizedBox(height: 24),
                const Text(
                  'Не передана конфигурация',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  'Не заданы обязательные параметры:\n\n$missing\n\n'
                  'Запустите приложение с параметром:\n\n'
                  'flutter run --dart-define-from-file=env.json\n\n'
                  'Файл env.json должен лежать в корне проекта рядом с pubspec.yaml.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, height: 1.6, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Остальные ключи (Gemini, OpenRouter, сканер, Sentry) — '
                  'необязательные: без них приложение запустится, но часть '
                  'AI-функций будет недоступна.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, height: 1.5, color: Colors.black38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WelmiApp extends StatefulWidget {
  const WelmiApp({super.key});
  @override
  State<WelmiApp> createState() => _WelmiAppState();
}

class _WelmiAppState extends State<WelmiApp> {
  final AuthService _auth = AuthService();
  final BiometricService _biometric = BiometricService();
  static const String _themeModeKey = 'theme_mode';

  bool _isCheckingAuth = true;
  bool _onboardingComplete = false;
  bool _isLocked = false;
  bool _widgetLaunchHandled = false;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _checkAuthState();

    PushNotificationService().onRouteTap = (route) {
      final nav = PushNotificationService.navigatorKey.currentState;
      if (nav == null || nav.mounted == false) return;
      switch (route) {
        case 'water':
          nav.push(MaterialPageRoute(builder: (_) => const WaterPage()));
        case 'diary':
          nav.push(MaterialPageRoute(builder: (_) => const DiaryPage()));
        case 'progress':
          nav.push(MaterialPageRoute(builder: (_) => const ProgressPage()));
        case 'weight':
          nav.push(MaterialPageRoute(builder: (_) => const WeightPage()));
      }
    };

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.session != null) {
        _auth.syncFromSession(data.session!.user);
        _checkAuthState();
      } else {
        PushNotificationService().unregisterAllTokens();
        setState(() {
          _auth.reset();
          _onboardingComplete = false;
          _isCheckingAuth = false;
          _isLocked = false;
        });
      }
    });
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeModeKey);
      if (!mounted) return;
      setState(() {
        _themeMode = switch (saved) {
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          _ => ThemeMode.system,
        };
      });
    } catch (e) {
      debugPrint('⚠️ Theme load error: $e');
    }
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    SharedPreferences.getInstance().then((prefs) {
      final value = switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };
      prefs.setString(_themeModeKey, value);
    });
  }

  Future<void> _checkAuthState() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) _auth.syncFromSession(session.user);

    if (_auth.isSignedIn && _auth.userId != null) {
      await UserDataService().loadAll();
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
          setState(() => _isLocked = true);
          final authenticated = await _biometric.authenticate();
          if (authenticated) {
            HapticFeedback.mediumImpact();
            setState(() => _isLocked = false);
          } else {
            return;
          }
        }
      }
    }

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
        final ml = int.tryParse(uri.queryParameters['ml'] ?? '') ?? 250;
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
      listenable: localeProvider,
      builder: (context, _) {
        return ThemeProvider(
          themeMode: _themeMode,
          onThemeChanged: _setThemeMode,
          child: MaterialApp(
            navigatorKey: PushNotificationService.navigatorKey,
            locale: localeProvider.locale,              supportedLocales: AppLocalizations.supportedLocales,              localizationsDelegates: AppLocalizations.localizationsDelegates,
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
            themeMode: _themeMode,
            home: _buildHome(),
          ),
        );
      },
    );
  }

  Widget _buildHome() {
    if (_isCheckingAuth) return const SplashScreen();
    if (_isLocked) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F7F2),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 80, color: Color(0xFF4A8C5C)),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.accessRestricted, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.accessRestrictedSubtitle, style: const TextStyle(color: Colors.black45)),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _checkAuthState,
                icon: const Icon(Icons.fingerprint_rounded),
                label: Text(AppLocalizations.of(context)!.unlockButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A8C5C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_onboardingComplete) return const MainShell();
    return const OnboardingPage();
  }
}
