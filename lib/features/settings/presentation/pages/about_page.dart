import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:lumina/features/settings/presentation/pages/terms_of_use_page.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _info;
  bool _easterEgg = false;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.isDark(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F7F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Header
              Row(
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
                  const SizedBox(width: 16),
                  Text(loc.aboutApp,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: isDark ? Colors.white : Colors.black,
                    )),
                ],
              ),
              const SizedBox(height: 40),

              // App Icon + Name
              Center(
                child: GestureDetector(
                  onTap: () {
                    _tapCount++;
                    if (_tapCount >= 5) {
                      setState(() {
                        _easterEgg = !_easterEgg;
                        _tapCount = 0;
                      });
                      HapticFeedback.heavyImpact();
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF75A47F).withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _easterEgg ? '🎉' : 'W',
                        style: TextStyle(
                          fontSize: _easterEgg ? 48 : 42,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF75A47F),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Welmi',
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  loc.aiAssistantDesc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Version info card
              _buildCard(isDark, [
                _buildInfoRow(
                  Icons.info_outline,
                  loc.version,
                  _info?.version ?? '—',
                  isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  Icons.build_outlined,
                  loc.buildNumber,
                  _info?.buildNumber ?? '—',
                  isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  Icons.code_outlined,
                  loc.packageName,
                  _info?.packageName ?? '—',
                  isDark,
                ),
              ]),
              const SizedBox(height: 20),

              // Links card
              _buildCard(isDark, [
                _buildLinkRow(
                  Icons.description_outlined,
                  loc.privacyPolicy,
                  isDark,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyPage(),
                  )),
                ),
                _buildDivider(isDark),
                _buildLinkRow(
                  Icons.gavel_outlined,
                  loc.termsOfUse,
                  isDark,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const TermsOfUsePage(),
                  )),
                ),
              ]),
              const SizedBox(height: 20),

              // Features card
              _buildCard(isDark, [
                _buildFeatureRow(Icons.restaurant_outlined, loc.featureFoodScanner, isDark),
                _buildDivider(isDark),
                _buildFeatureRow(Icons.calendar_month_outlined, loc.featureMealPlans, isDark),
                _buildDivider(isDark),
                _buildFeatureRow(Icons.analytics_outlined, loc.featureMacroAnalytics, isDark),
                _buildDivider(isDark),
                _buildFeatureRow(Icons.block_outlined, loc.featureNoAds, isDark),
              ]),
              const SizedBox(height: 40),

              // Footer
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

  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.black38),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              )),
          ),
          Text(value,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white38 : Colors.black26,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
        ],
      ),
    );
  }

  Widget _buildLinkRow(IconData icon, String title, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.black38),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                )),
            ),
            Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white10 : Colors.black12),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF75A47F)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              )),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 52,
      endIndent: 16,
      color: isDark ? Colors.white10 : Colors.black12,
    );
  }
}
