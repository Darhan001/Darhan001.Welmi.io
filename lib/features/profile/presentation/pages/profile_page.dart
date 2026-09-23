import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:lumina/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:lumina/features/profile/presentation/pages/subscription_page.dart';
import 'package:lumina/features/settings/presentation/pages/settings_page.dart';
import 'package:lumina/features/support/presentation/pages/support_page.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserDataService _userData = UserDataService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _userData.loadAll();
    if (mounted) setState(() => _isLoading = false);
  }

  void _showUnitsSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String selectedUnit = 'Метрические (кг, см)';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Единицы измерения',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Метрические (кг, см)'),
                    trailing: selectedUnit == 'Метрические (кг, см)'
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                    onTap: () => setSheetState(() => selectedUnit = 'Метрические (кг, см)'),
                  ),
                  ListTile(
                    title: const Text('Имперские (фунты, футы)'),
                    trailing: selectedUnit == 'Имперские (фунты, футы)'
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                    onTap: () => setSheetState(() => selectedUnit = 'Имперские (фунты, футы)'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final auth = AuthService();
    // Приоритет — сохранённому профилю (имя/фото можно менять в редактировании)
    final profile = _userData.profile;
    final name = profile?.displayName ?? auth.displayName ?? 'Пользователь';
    final email = auth.email ?? 'email@example.com';
    final photoUrl = profile?.photoUrl ?? auth.photoUrl;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Real data from Supabase
    final currentWeight = _userData.latestWeight ?? 72.0;
    final targetWeight = _userData.goalWeight ?? 70.0;
    final weightDiff = (currentWeight - targetWeight).abs();
    final isLosing = targetWeight < currentWeight;
    final weightDiffStr = weightDiff.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListenableBuilder(
                listenable: _userData,
                builder: (context, _) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              smoothPageRoute(const SettingsPage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tc.card,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: tc.shadow(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.settings_outlined,
                                size: 22, color: tc.text),
                          ),
                        ),
                        Text('Мой профиль',
                            style: GoogleFonts.notoSerif(
                                fontWeight: FontWeight.w900, fontSize: 18, color: tc.text)),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              smoothPageRoute(const EditProfilePage()),
                            );
                            if (result == true && mounted) {
                              _loadData();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tc.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.edit_outlined,
                                size: 18, color: tc.textOnPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Profile Header — реальные данные из Google
                    photoUrl != null
                        ? CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(photoUrl),
                          )
                        : CircleAvatar(
                            radius: 50,
                            backgroundColor: tc.primary,
                            child: Text(initial,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                          ),
                    const SizedBox(height: 16),
                    Text(name,
                        style: GoogleFonts.notoSerif(
                            fontSize: 22, fontWeight: FontWeight.w900, color: tc.text)),
                    Text(email,
                        style: TextStyle(color: tc.textHint, fontSize: 12)),
                    const SizedBox(height: 40),
                    // Weight Goal Card — реальные данные из Supabase
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: tc.card,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Цель веса',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: tc.text)),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildWeightInfo('Текущий', '${currentWeight.toStringAsFixed(1)} кг', tc),
                              _buildWeightInfo(
                                isLosing ? 'Осталось сбросить' : 'Осталось набрать',
                                '$weightDiffStr кг',
                                tc,
                                isHighlight: true,
                              ),
                              _buildWeightInfo('Целевой', '${targetWeight.toStringAsFixed(1)} кг', tc),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Settings List
                    _buildProfileItem(
                        Icons.settings_outlined, 'Настройки', tc, onTap: () {
                      hapticTap();
                      Navigator.push(
                          context, smoothPageRoute(const SettingsPage()));
                    }),
                    _buildProfileItem(Icons.straighten_outlined, 'Единицы измерения', tc,
                        onTap: () => _showUnitsSettings(context)),
                    _buildProfileItem(Icons.star_outline, 'Подписка', tc,
                        trailing: 'PRO', onTap: () {
                      hapticTap();
                      Navigator.push(
                          context, smoothPageRoute(const SubscriptionPage()));
                    }),
                    _buildProfileItem(Icons.help_outline, 'Поддержка', tc,
                        onTap: () {
                          hapticTap();
                          Navigator.push(
                              context, smoothPageRoute(const SupportPage()));
                        }),
                    const SizedBox(height: 40),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Выйти'),
                            content: const Text('Вы уверены, что хотите выйти?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  _userData.reset();
                                  await AuthService().signOut();
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => const OnboardingPage(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                child: const Text('Выйти',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Выйти',
                          style: TextStyle(
                              color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
          ),
        ),
    );
  }

  Widget _buildWeightInfo(String label, String val, ThemeColors tc, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, color: tc.textHint, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(val,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isHighlight ? const Color(0xFF75A47F) : tc.text,
            )),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title, ThemeColors tc,
      {String? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: tc.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: tc.text)),
            ),
            if (trailing != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(trailing,
                    style: const TextStyle(
                        color: Color(0xFF75A47F), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            Icon(Icons.chevron_right, size: 20, color: tc.textHint),
          ],
        ),
      ),
    );
  }
}
