import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/app_tokens.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/pressable.dart';

/// Плитка статистики: значение, подпись и цвет иконки.
class HomeStatTile extends StatelessWidget {
  const HomeStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final radius = BorderRadius.circular(AppTokens.of(context).cardRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: tc.shadow(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Pressable(
        onTap: onTap,
        borderRadius: radius,
        semanticLabel: '$label: $value',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ExcludeSemantics(child: _content(tc)),
        ),
      ),
    );
  }

  Widget _content(ThemeColors tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: tc.textHint.withValues(alpha: 0.6),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: tc.text,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: tc.textHint,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
