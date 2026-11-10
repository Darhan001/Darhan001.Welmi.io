import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_card.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Раздел «Единицы измерения»: метрическая и имперская системы.
class SettingsUnitsSection extends StatelessWidget {
  const SettingsUnitsSection({
    super.key,
    required this.isDark,
    required this.onSelect,
  });

  final bool isDark;

  /// Выбор системы: значение и его подпись для снекбара.
  final void Function(UnitSystem system, String title) onSelect;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(title: loc.measurementUnits, isDark: isDark),
        const SizedBox(height: 12),
        SettingsCard(
          isDark: isDark,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _UnitTile(
                title: loc.metricUnits,
                value: UnitSystem.metric,
                isDark: isDark,
                onSelect: onSelect,
              ),
              Divider(
                height: 1,
                indent: 52,
                endIndent: 16,
                color: SettingsDesign.hairline(isDark),
              ),
              _UnitTile(
                title: loc.imperialUnits,
                value: UnitSystem.imperial,
                isDark: isDark,
                onSelect: onSelect,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.title,
    required this.value,
    required this.isDark,
    required this.onSelect,
  });

  final String title;
  final UnitSystem value;
  final bool isDark;
  final void Function(UnitSystem system, String title) onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = UnitsService.instance.value == value;

    return ListTile(
      onTap: () => onSelect(value, title),
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? SettingsDesign.green
                : (isDark ? Colors.white24 : Colors.black26),
            width: 2,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: SettingsDesign.green,
                  ),
                ),
              )
            : null,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isSelected
              ? SettingsDesign.text(isDark)
              : (isDark ? Colors.white38 : Colors.black54),
        ),
      ),
    );
  }
}
