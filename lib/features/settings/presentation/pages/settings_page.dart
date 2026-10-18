import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/biometric_service.dart'; // Добавлено
import 'package:lumina/core/services/health_sync_service.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/core/theme/locale_provider.dart';
import 'package:lumina/core/widgets/units_picker_sheet.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:lumina/features/settings/presentation/pages/about_page.dart';
import 'package:lumina/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:lumina/features/settings/presentation/pages/terms_of_use_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lumina/main.dart' show localeProvider;
import 'package:lumina/l10n/app_localizations.dart';

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
      final authenticated = await _biometric.authenticate();
      if (!mounted) return;
      if (!authenticated) {
        showWelmiSnackbar(context, loc.biometricFailed, icon: Icons.fingerprint_sharp);
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

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F7F2),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Header
                  Row(
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
                          child: Icon(Icons.arrow_back, size: 22, color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      Text(AppLocalizations.of(context)!.settingsTitle,
                        style: GoogleFonts.notoSerif(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: isDark ? Colors.white : Colors.black,
                        )),
                      const SizedBox(width: 42),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 👤 Profile card
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final result = await Navigator.push<bool>(
                        context,
                        smoothPageRoute(const EditProfilePage()),
                      );
                      if (result != true || !context.mounted) return;
                      // Пересобираем карточку профиля — фото/имя обновились
                      setState(() {});
                      showWelmiSnackbar(context, AppLocalizations.of(context)!.profileUpdated, icon: Icons.check_circle);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'profile_avatar',
                            child: Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : Colors.black,
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildProfileAvatar(isDark),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AuthService().displayName ?? 'Пользователь',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(AppLocalizations.of(context)!.editProfile,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF75A47F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.black12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 🔐 Безопасность (Новый раздел)
                  if (_isBiometricSupported) ...[
                    _buildSectionTitle(AppLocalizations.of(context)!.security.toUpperCase(), isDark),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      Icons.fingerprint,
                      AppLocalizations.of(context)!.biometricLogin,
                      _biometricEnabled,
                      _toggleBiometrics,
                      subtitle: AppLocalizations.of(context)!.biometricSubtitle,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 28),
                  ],

                  // 📲 Синхронизация со здоровьем
                  _buildSectionTitle(AppLocalizations.of(context)!.sync.toUpperCase(), isDark),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _healthSyncing ? null : _connectHealth,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3E5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.monitor_heart_outlined,
                                size: 22, color: Color(0xFF75A47F)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)!.googleFitAppleHealth,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : Colors.black)),
                                const SizedBox(height: 2),
                                Text(
                                    _healthConnected
                                        ? AppLocalizations.of(context)!.healthConnected
                                        : AppLocalizations.of(context)!.healthDisconnected,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          if (_healthSyncing)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _healthConnected
                                    ? const Color(0xFFE8F3E5)
                                    : Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _healthConnected ? '✓' : AppLocalizations.of(context)!.healthConnect,
                                style: TextStyle(
                                    color: _healthConnected
                                        ? const Color(0xFF75A47F)
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 🔔 Уведомления (локальные — см. NotificationService)
                  _buildSectionTitle(AppLocalizations.of(context)!.notificationsTitle.toUpperCase(), isDark),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await Navigator.push(
                        context,
                        smoothPageRoute(const NotificationSettingsPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3E5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                size: 22, color: Color(0xFF75A47F)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)!.notificationsTitle,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : Colors.black)),
                                const SizedBox(height: 2),
                                Text(AppLocalizations.of(context)!.pushNotificationsSubtitle,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white10 : Colors.black12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 🌍 Язык
                  _buildLanguageSelector(isDark),
                  const SizedBox(height: 28),

                  // 🎨 Внешний вид (Системная / Светлая / Тёмная)
                  _buildSectionTitle(AppLocalizations.of(context)!.appearance.toUpperCase(), isDark),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        _buildThemeOption(
                            AppLocalizations.of(context)!.themeSystem, ThemeMode.system, Icons.brightness_auto_outlined, isDark),
                        _buildThemeOption(
                            AppLocalizations.of(context)!.themeLight, ThemeMode.light, Icons.light_mode_outlined, isDark),
                        _buildThemeOption(
                            AppLocalizations.of(context)!.themeDark, ThemeMode.dark, Icons.dark_mode_outlined, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.themeSystemDescription,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 28),

                  // 📏 Единицы
                  _buildSectionTitle(AppLocalizations.of(context)!.measurementUnits.toUpperCase(), isDark),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildRadioTile(AppLocalizations.of(context)!.metricUnits, UnitSystem.metric, isDark),
                        Divider(height: 1, indent: 52, endIndent: 16, color: isDark ? Colors.white10 : Colors.black12),
                        _buildRadioTile(AppLocalizations.of(context)!.imperialUnits, UnitSystem.imperial, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 🏠 Виджет на рабочий стол
                  _buildSectionTitle(AppLocalizations.of(context)!.widgetTitle.toUpperCase(), isDark),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F3E5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.widgets_outlined,
                              size: 22, color: Color(0xFF75A47F)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.widgetWaterTitle,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black)),
                              const SizedBox(height: 2),
                              Text(
                                  AppLocalizations.of(context)!.widgetWaterDescription,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ℹ️ О приложении
                  _buildSectionTitle(AppLocalizations.of(context)!.aboutApp.toUpperCase(), isDark),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoTile(Icons.info_outline, AppLocalizations.of(context)!.version, _appVersion ?? '…', isDark),
                          Divider(height: 1, indent: 52, endIndent: 16, color: isDark ? Colors.white10 : Colors.black12),
                          _buildInfoTile(
                            Icons.description_outlined,
                            AppLocalizations.of(context)!.privacyPolicy,
                            '',
                            isDark,
                            onTap: () => Navigator.push(context, smoothPageRoute(const PrivacyPolicyPage())),
                          ),
                          Divider(height: 1, indent: 52, endIndent: 16, color: isDark ? Colors.white10 : Colors.black12),
                          _buildInfoTile(
                            Icons.gavel_outlined,
                            AppLocalizations.of(context)!.termsOfUse,
                            '',
                            isDark,
                            onTap: () => Navigator.push(context, smoothPageRoute(const TermsOfUsePage())),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Footer
                  Center(
                    child: Text(
                      AppLocalizations.of(context)!.madeWithLove,
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
          ],
        ),
      ),
    );
  }

  /// Аватар профиля: фото (если задано) или первая буква имени.
  Widget _buildProfileAvatar(bool isDark) {
    final photoUrl = UserDataService().profile?.photoUrl ??
        AuthService().photoUrl;
    final name = AuthService().displayName ?? 'П';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'П';

    Widget letter() => Center(
          child: Text(
            initial,
            style: TextStyle(
              color: isDark ? Colors.black : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

    return photoUrl != null
        ? Image.network(
            photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => letter(),
          )
        : letter();
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w900,
        fontSize: 12,
        color: isDark ? Colors.white38 : Colors.black.withValues(alpha: 0.35),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon, String title, bool value,
    ValueChanged<bool>? onChanged, {
    String? subtitle,
    bool indent = false,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.only(
        left: indent ? 52 : 16,
        right: 8,
        top: 10,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!indent) ...[
            Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w500,
                    )),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF75A47F),
            inactiveThumbColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
      String label, ThemeMode mode, IconData icon, bool isDark) {
    final selected = ThemeProvider.of(context).themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          hapticTap();
          ThemeProvider.of(context).onThemeChanged(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF75A47F) : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black45)),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54))),
            ],
          ),
        ),
      ),
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

  Widget _buildRadioTile(String title, UnitSystem value, bool isDark) {
    final isSelected = UnitsService.instance.value == value;
    return ListTile(
      onTap: () => _selectUnits(value, title),
      leading: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF75A47F) : (isDark ? Colors.white24 : Colors.black26),
            width: 2,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF75A47F),
                  ),
                ),
              )
            : null,
      ),
      title: Text(title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black54),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    final currentCode = localeProvider.locale.languageCode;
    final currentName = LocaleProvider.localeNames[currentCode] ?? currentCode;
    final currentFlag = currentCode == 'ru' ? '🇷🇺' : currentCode == 'ky' ? '🇰🇬' : '🇬🇧';

    return GestureDetector(
      onTap: () => _showLanguagePicker(isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3E5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.language, size: 22, color: Color(0xFF75A47F)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Язык / Тил',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 2),
                  Text('$currentFlag $currentName',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white10 : Colors.black12),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(bool isDark) {
    final currentCode = localeProvider.locale.languageCode;
    final languages = [
      {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
      {'code': 'ky', 'name': 'Кыргызча', 'flag': '🇰🇬'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Выбери язык',
                  style: GoogleFonts.notoSerif(
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final isSelected = currentCode == lang['code'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    localeProvider.setLocale(Locale(lang['code']!));
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8F3E5)
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9F7F2)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF75A47F) : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(lang['name']!,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15,
                                  color: isSelected ? const Color(0xFF4A8C5C) : (isDark ? Colors.white : Colors.black))),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, size: 20, color: Color(0xFF75A47F)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String trailing,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: trailing.isNotEmpty
          ? Text(trailing,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            )
          : Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white10 : Colors.black12),
    );
  }
}
