import 'package:timezone/timezone.dart' as tz;

/// Чистые расчёты моментов срабатывания напоминаний.
///
/// [now] передаётся явно, чтобы логику можно было проверить тестами.

/// Ближайший момент [hour]:[minute] в часовом поясе [now]
/// (сегодня, если время ещё не прошло, иначе — завтра).
tz.TZDateTime nextInstanceOf(int hour, int minute, tz.TZDateTime now) {
  var when = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!when.isAfter(now)) {
    when = when.add(const Duration(days: 1));
  }
  return when;
}

/// Ближайший «слот» повторяющегося напоминания: окно [startMin; endMin]
/// делится на шаги [intervalMinutes]. Берём следующий слот после текущего
/// момента; если следующего слота в окне нет — первый слот завтра
/// (время вычисляется от начала дня, поэтому id остаётся стабильным).
tz.TZDateTime currentOrNextSlot(
  int intervalMinutes,
  int startMin,
  int endMin,
  tz.TZDateTime now,
) {
  final nowMin = now.hour * 60 + now.minute;
  final window = endMin - startMin;
  final step = intervalMinutes.clamp(1, window <= 0 ? 1 : window);

  var slotMin = startMin;
  // Первый слот строго ПОСЛЕ текущего момента.
  while (slotMin <= nowMin) {
    slotMin += step;
  }
  if (slotMin > endMin) {
    // Окно на сегодня закончилось → первый слот завтра.
    final tomorrow = now.add(const Duration(days: 1));
    return tz.TZDateTime(
      now.location,
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      startMin ~/ 60,
      startMin % 60,
    );
  }
  return tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    slotMin ~/ 60,
    slotMin % 60,
  );
}
