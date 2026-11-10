import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/biometric_service.dart';
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/core/widgets/units_picker_sheet.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:lumina/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_about_section.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_appearance_section.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_card.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_language_picker.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_nav_tile.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_profile_card.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_units_section.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final BiometricService _biometric = BiometricService();

  bool _biometricEnabled = false;
  bool _isBiometricSupported = false;
  bool _healthConnected = false;
  bool _healthSyncing = false;

  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  /// Версия берётся из сборки (pubspec), а не из захардкоженной строки.
  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (e) {
      debugPrint('⚠️ PackageInfo error: $e');
    }
  }

  Future<void> _loadSettings() async {
    final bioEnabled = await _biometric.isEnabled();
    final bioSupported = await _biometric.isBiometricAvailable();
    // Показываем реальный статус подключения к Health Connect
    final healthOk = await HealthSyncService().checkAuth();

    if (!mounted) return;
    setState(() {
      _biometricEnabled = bioEnabled;
      _isBiometricSupported = bioSupported;
      _healthConnected = healthOk;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    HapticFeedback.mediumImpact();
    final loc = AppLocalizations.of(context)!;
    if (value) {
      // Если включает, пробуем аутентифицировать сразу для проверки
      final authenticated = await _biometric.authenticateWith(loc);
      if (!mounted) return;
      if (!authenticated) {
        showWelmiSnackbar(
          context,
          loc.biometricFailed,
          icon: Icons.fingerprint_sharp,
        );
        return;
      }
    }

    await _biometric.setEnabled(value);
    if (!mounted) return;
    setState(() => _biometricEnabled = value);

    showWelmiSnackbar(
      context,
      value ? loc.biometricEnabled : loc.biometricDisabled,
      icon: Icons.security,
    );
  }

  /// Подключить Google Fit / Apple Health (запрос разрешений)
  Future<void> _connectHealth() async {
    final health = HealthSyncService();
    setState(() => _healthSyncing = true);

    // На Android нужен установленный Health Connect (Google Fit).
    if (!await health.isHealthConnectAvailable()) {
      if (mounted) {
        setState(() => _healthSyncing = false);
        showWelmiSnackbar(
          context,
          AppLocalizations.of(context)!.healthInstallPrompt,
          icon: Icons.monitor_heart_outlined,
          actionLabel: AppLocalizations.of(context)!.healthInstall,
          onAction: () => health.installHealthConnect(),
        );
      }
      return;
    }

    // Если разрешения уже выданы — не открываем окно повторно
    var granted = await health.checkAuth();
    if (!granted) {
      granted = await health.requestAuthorization();
      // На iOS HealthKit не раскрывает фактические READ-разрешения
      // (hasPermissions возвращает null) — доверяем результату запроса.
      // На Android перепроверяем, что пользователь действительно всё выдал.
      if (Platform.isAndroid) {
        granted = await health.checkAuth();
      }
    }

    if (!mounted) return;
    setState(() {
      _healthSyncing = false;
      _healthConnected = granted;
    });

    if (granted) {
      // Сразу подтягиваем сегодняшние шаги и калории
      final result = await health.syncToday();
      if (!mounted) return;
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.healthConnectedSuccess(result.steps),
        icon: Icons.check_circle,
      );
    } else {
      showWelmiSnackbar(
        context,
        AppLocalizations.of(context)!.healthNoAccess,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _openEditProfile() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<bool>(
      context,
      smoothPageRoute(const EditProfilePage()),
    );
    if (result != true || !mounted) return;
    // Пересобираем карточку профиля — фото/имя обновились
    setState(() {});
    showWelmiSnackbar(
      context,
      AppLocalizations.of(context)!.profileUpdated,
      icon: Icons.check_circle,
    );
  }

  Future<void> _selectUnits(UnitSystem system, String title) async {
    if (UnitsService.instance.value == system) return;
    HapticFeedback.selectionClick();
    final loc = AppLocalizations.of(context)!;
    await applyUnitSystem(system);
    if (!mounted) return;
    setState(() {});
    showWelmiSnackbar(context, loc.unitsChanged(title), icon: Icons.check);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.isDark(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: SettingsDesign.background(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _header(isDark, loc),
              const SizedBox(height: 32),
              SettingsProfileCard(isDark: isDark, onTap: _openEditProfile),
              const SizedBox(height: 28),
              if (_isBiometricSupported) ...[
                SettingsSectionTitle(title: loc.security, isDark: isDark),
                const SizedBox(height: 12),
                SettingsSwitchTile(
                  icon: Icons.fingerprint,
                  title: loc.biometricLogin,
                  subtitle: loc.biometricSubtitle,
                  value: _biometricEnabled,
                  onChanged: _toggleBiometrics,
                  isDark: isDark,
                ),
                const SizedBox(height: 28),
              ],
              SettingsSectionTitle(title: loc.sync, isDark: isDark),
              const SizedBox(height: 12),
              SettingsNavTile(
                icon: Icons.monitor_heart_outlined,
                title: loc.googleFitAppleHealth,
                subtitle: _healthConnected
                    ? loc.healthConnected
                    : loc.healthDisconnected,
                isDark: isDark,
                onTap: _healthSyncing ? null : _connectHealth,
                trailing: _healthSyncing
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : SettingsStatusBadge(
                        connected: _healthConnected,
                        connectedLabel: '✓',
                        actionLabel: loc.healthConnect,
                      ),
              ),
              const SizedBox(height: 28),
              SettingsSectionTitle(
                title: loc.notificationsTitle,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              SettingsNavTile(
                icon: Icons.notifications_outlined,
                title: loc.notificationsTitle,
                subtitle: loc.pushNotificationsSubtitle,
                isDark: isDark,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.push(
                    context,
                    smoothPageRoute(const NotificationSettingsPage()),
                  );
                },
              ),
              const SizedBox(height: 28),
              SettingsLanguageTile(isDark: isDark),
              const SizedBox(height: 28),
              SettingsAppearanceSection(isDark: isDark),
              const SizedBox(height: 28),
              SettingsUnitsSection(isDark: isDark, onSelect: _selectUnits),
              const SizedBox(height: 28),
              SettingsSectionTitle(title: loc.widgetTitle, isDark: isDark),
              const SizedBox(height: 12),
              SettingsNavTile(
                icon: Icons.widgets_outlined,
                title: loc.widgetWaterTitle,
                subtitle: loc.widgetWaterDescription,
                isDark: isDark,
                trailing: const SizedBox.shrink(),
              ),
              const SizedBox(height: 28),
              SettingsAboutSection(isDark: isDark, version: _appVersion),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  loc.madeWithLove,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// Шапка: назад, заголовок и симметричный отступ справа.
  Widget _header(bool isDark, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              size: 22,
              color: SettingsDesign.text(isDark),
            ),
          ),
        ),
        Text(
          loc.settingsTitle,
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: SettingsDesign.text(isDark),
          ),
        ),
        const SizedBox(width: 42),
      ],
    );
  }
}
