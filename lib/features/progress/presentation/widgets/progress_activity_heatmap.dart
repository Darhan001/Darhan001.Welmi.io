import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_card.dart';
import 'package:lumina/features/progress/domain/progress_metrics.dart';
import 'package:lumina/features/progress/presentation/widgets/progress_common.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Тепловая карта дней с записями за последние 4 недели (с понедельника).
class ProgressActivityHeatmap extends StatelessWidget {
  const ProgressActivityHeatmap({
    super.key,
    required this.activeDays,
    required this.onDayTap,
  });

  /// Дни с записями, каждая дата — полночь (см. UserDataService.activeDays).
  final Set<DateTime> activeDays;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final locale = AppLocalizations.of(context)!.localeName;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = heatmapDays(now: now);
    final activeCount = activeDays.where((d) => !d.isBefore(days.first)).length;
    final monthFormat = DateFormat.MMM(locale);
    final weekdayFormat = DateFormat.E(locale);
    final hintStyle = TextStyle(
      fontSize: 9,
      color: tc.textHint,
      fontWeight: FontWeight.w700,
    );

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressCardHeader(
            title: AppLocalizations.of(context)!.progressLast28Days,
            fontSize: 14,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ProgressColors.weight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context)!.weightEntries(activeCount),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ProgressColors.weight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Названия месяцев над первой ячейкой каждого месяца.
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    _isMonthStart(days, i) ? monthFormat.format(days[i]) : '',
                    style: hintStyle,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    weekdayFormat.format(days[i]).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: hintStyle.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _HeatCell(
                        day: days[row * 7 + col],
                        isActive: activeDays.contains(days[row * 7 + col]),
                        isToday: days[row * 7 + col] == today,
                        onTap: onDayTap,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendItem(
                color: ProgressColors.weight,
                label: AppLocalizations.of(context)!.legendHasEntry,
              ),
              const SizedBox(width: 14),
              _LegendItem(
                color: tc.primary,
                label: AppLocalizations.of(context)!.legendToday,
              ),
              const Spacer(),
              Icon(Icons.touch_app_outlined, size: 12, color: tc.textHint),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.legendTapDay,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: tc.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Подпись месяца — над колонкой первой недели, где начался месяц
  /// (раньше подписи строились для 28 колонок в ряду из 7 и почти не
  /// попадали в нужные места).
  static bool _isMonthStart(List<DateTime> days, int col) {
    if (col == 0) return true;
    for (var row = 0; row < 4; row++) {
      final i = row * 7 + col;
      if (days[i].day == 1) return true;
    }
    return false;
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool isActive;
  final bool isToday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(day),
      child: Container(
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isToday
              ? tc.primary
              : isActive
              ? ProgressColors.weight.withValues(alpha: 0.75)
              : tc.text.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: tc.text.withValues(alpha: 0.6), width: 1.5)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isToday || isActive ? Colors.white : tc.textHint,
            fontSize: 8,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: tc.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
