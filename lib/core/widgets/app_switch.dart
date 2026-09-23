import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Строка-переключатель с заголовком и подзаголовком (тема-aware).
class AppSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? leadingIcon;

  const AppSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tc.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, size: 20, color: tc.greenDark),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tc.text,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: tc.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: tc.isDark
                  ? tc.success.withValues(alpha: 0.5)
                  : tc.green.withValues(alpha: 0.5),
              activeThumbColor: tc.isDark ? tc.success : tc.greenDark,
            ),
          ],
        ),
      ),
    );
  }
}
