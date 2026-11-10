import 'dart:math' as math;

import 'package:lumina/core/models/supabase_models.dart';

/// Вкладки экрана «Прогресс».
enum ProgressTab { all, measurements, bodyFat }

/// Доступные интервалы графиков, дней.
const List<int> progressRangeOptions = [7, 28, 90];

/// Замер, который можно показать на графике во вкладке «Замеры».
enum MeasureMetric {
  waist,
  chest,
  hips,
  arm,
  thigh,
  neck;

  /// Значение замера в записи (null, если он не заполнен).
  /// Для рук и бёдер берётся левая сторона, а при её отсутствии — правая.
  double? valueOf(BodyMeasurement m) => switch (this) {
    MeasureMetric.waist => m.waistCm,
    MeasureMetric.chest => m.chestCm,
    MeasureMetric.hips => m.hipsCm,
    MeasureMetric.arm => m.leftArmCm ?? m.rightArmCm,
    MeasureMetric.thigh => m.leftThighCm ?? m.rightThighCm,
    MeasureMetric.neck => m.neckCm,
  };
}

/// Точка графика: дата записи и значение.
typedef ProgressPoint = ({DateTime date, double value});

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Начало интервала из [days] дней, включая сегодняшний (от полуночи).
DateTime rangeStart(int days, {DateTime? now}) {
  final today = _dayOf(now ?? DateTime.now());
  return DateTime(today.year, today.month, today.day - (days - 1));
}

/// Точки графика из записей, попавших в интервал с [from] (включительно),
/// по возрастанию даты. Записи без значения ([valueOf] вернул null или ≤ 0)
/// пропускаются — график строится только по настоящим данным.
List<ProgressPoint> seriesSince<T>(
  Iterable<T> entries, {
  required DateTime from,
  required DateTime Function(T) dateOf,
  required double? Function(T) valueOf,
}) {
  final points = <ProgressPoint>[];
  for (final e in entries) {
    final date = dateOf(e);
    if (_dayOf(date).isBefore(from)) continue;
    final v = valueOf(e);
    if (v == null || v <= 0) continue;
    points.add((date: date, value: v));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

/// Оценка % жира по методу ВМФ США (Navy formula).
///
/// Нужны рост, обхваты талии и шеи, для женщин ещё бёдра. Возвращает null,
/// если данных недостаточно или они противоречивы.
double? estimateNavyBodyFat({
  required Gender? gender,
  required double heightCm,
  required double? waistCm,
  required double? neckCm,
  required double? hipsCm,
}) {
  if (gender == null || heightCm <= 0 || waistCm == null || neckCm == null) {
    return null;
  }
  double log10(double v) => math.log(v) / math.ln10;

  if (gender == Gender.male) {
    final diff = waistCm - neckCm;
    if (diff <= 0) return null;
    return 495 / (1.0324 - 0.19077 * log10(diff) + 0.15456 * log10(heightCm)) -
        450;
  }

  if (hipsCm == null) return null;
  final circumference = waistCm + hipsCm - neckCm;
  if (circumference <= 0) return null;
  return 495 /
          (1.29579 -
              0.35004 * log10(circumference) +
              0.22100 * log10(heightCm)) -
      450;
}

/// Категория % жира для подписи под значением.
enum BodyFatCategory { extremelyLow, athletic, normal, aboveNormal, high }

BodyFatCategory bodyFatCategory(double percent) {
  if (percent < 10) return BodyFatCategory.extremelyLow;
  if (percent < 15) return BodyFatCategory.athletic;
  if (percent < 20) return BodyFatCategory.normal;
  if (percent < 25) return BodyFatCategory.aboveNormal;
  return BodyFatCategory.high;
}

/// Допустимый ввод % жира.
bool isPlausibleBodyFat(double percent) => percent >= 2 && percent <= 70;

/// 28 дней тепловой карты: последние 4 недели, начиная с понедельника,
/// каждая дата — полночь по местному времени.
List<DateTime> heatmapDays({DateTime? now}) {
  final today = _dayOf(now ?? DateTime.now());
  final start = DateTime(
    today.year,
    today.month,
    today.day - (today.weekday - 1) - 21,
  );
  return List.generate(
    28,
    (i) => DateTime(start.year, start.month, start.day + i),
  );
}
