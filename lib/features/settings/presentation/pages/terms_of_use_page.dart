import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/core/theme/theme_provider.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.isDark(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F7F2),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
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
                  Expanded(
                    child: Text(loc.termsOfUse,
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: isDark ? Colors.white : Colors.black,
                      )),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(loc.termsIntro, isDark),
                    const SizedBox(height: 20),
                    _buildSection(loc.termsAcceptanceTitle, loc.termsAcceptanceContent, isDark),
                    _buildSection(loc.termsServiceTitle, loc.termsServiceContent, isDark),
                    _buildSection(loc.termsAccountTitle, loc.termsAccountContent, isDark),
                    _buildSection(loc.termsSubscriptionTitle, loc.termsSubscriptionContent, isDark),
                    _buildSection(loc.termsContentTitle, loc.termsContentContent, isDark),
                    _buildSection(loc.termsProhibitedTitle, loc.termsProhibitedContent, isDark),
                    _buildSection(loc.termsDisclaimerTitle, loc.termsDisclaimerContent, isDark),
                    _buildSection(loc.termsLiabilityTitle, loc.termsLiabilityContent, isDark),
                    _buildSection(loc.termsTerminationTitle, loc.termsTerminationContent, isDark),
                    _buildSection(loc.termsChangesTitle, loc.termsChangesContent, isDark),
                    const SizedBox(height: 20),
                    _buildSection(loc.contactTitle, loc.termsContactContent, isDark),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        loc.termsLastUpdated,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: isDark ? Colors.white54 : Colors.black45,
        fontWeight: FontWeight.w500,
        height: 1.6,
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
