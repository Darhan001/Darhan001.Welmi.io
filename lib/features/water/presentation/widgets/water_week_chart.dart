import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/core/widgets/app_chip.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Вода за последние 7 дней: столбики от старого дня к сегодняшнему.
class WaterWeekChart extends StatelessWidget {
  const WaterWeekChart({super.key, required this.days});

  /// Ровно 7 дней по порядку, последний — сегодня.
  final List<({DateTime day, int ml})> days;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final weekday = DateFormat.E(loc.localeName);
    final maxVal = days.fold<int>(1, (m, d) => d.ml > m ? d.ml : m).toDouble();
    final total = days.fold<int>(0, (sum, d) => sum + d.ml);

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.waterWeekTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: tc.text,
                ),
              ),
              AppBadge(
                text: loc.litersValue((total / 1000).toStringAsFixed(1)),
                icon: Icons.water_drop,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < days.length; i++)
                _Bar(
                  ml: days[i].ml,
                  height: (days[i].ml / maxVal * 120).clamp(4.0, 120.0),
                  // Подпись — реальный день столбика; раньше стояли
                  // фиксированные «ПН…ВС» при скользящих 7 днях.
                  label: weekday.format(days[i].day),
                  isToday: i == days.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.ml,
    required this.height,
    required this.label,
    required this.isToday,
  });

  final int ml;
  final double height;
  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$ml',
          style: TextStyle(
            fontSize: 9,
            color: tc.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [tc.green, tc.greenDark.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(color: tc.green, width: 2) : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? tc.green : tc.textHint,
          ),
        ),
      ],
    );
  }
}
