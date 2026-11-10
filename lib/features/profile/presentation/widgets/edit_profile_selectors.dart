import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Выбор пола: две плашки «Мужской / Женский».
class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Gender? value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wc, size: 18, color: tc.textHint),
            const SizedBox(width: 8),
            Text(
              loc.genderLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tc.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _chip(context, Gender.male, loc.male, Icons.male)),
            const SizedBox(width: 12),
            Expanded(
              child: _chip(context, Gender.female, loc.female, Icons.female),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    Gender gender,
    String label,
    IconData icon,
  ) {
    final tc = ThemeColors.of(context);
    final selected = value == gender;
    final accent = tc.isDark ? tc.success : tc.greenDark;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => onChanged(gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? tc.successBg : tc.text.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? tc.greenDark : tc.text.withValues(alpha: 0.06),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? accent : tc.textHint),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                  color: selected ? accent : tc.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Поле «Дата рождения». Без даты показывает прочерк, а не 1 января 1995.
class BirthDateField extends StatelessWidget {
  const BirthDateField({super.key, required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    // Формат по языку приложения: раньше дата всегда выводилась по-русски.
    final df = DateFormat.yMMMMd(Localizations.localeOf(context).toString());
    final date = value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.text.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tc.text.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, size: 20, color: tc.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.birthDate,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tc.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date == null ? '—' : df.format(date),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tc.text,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tc.successBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_month, size: 18, color: tc.greenDark),
            ),
          ],
        ),
      ),
    );
  }
}
