/// Безопасное чтение значений из JSON Supabase и локального кэша.
///
/// PostgREST отдаёт `numeric`/`real` как int или double в зависимости от
/// значения, а кэш мог быть записан старой версией приложения. Жёсткие
/// `as int` / `firstWhere` без `orElse` роняли разбор целого списка из-за
/// одной записи — эти функции вместо этого возвращают запасное значение.
library;

/// Целое число из int, double или строки; иначе [fallback].
int readInt(Object? value, [int fallback = 0]) {
  if (value is num) return value.round();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round() ?? fallback;
  }
  return fallback;
}

/// Дробное число из num или строки; иначе null.
double? readDoubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Дробное число; при отсутствии — [fallback].
double readDouble(Object? value, double fallback) =>
    readDoubleOrNull(value) ?? fallback;

/// Строка (для обязательных текстовых полей); null → пустая строка.
String readString(Object? value) => value?.toString() ?? '';

/// Строка или null.
String? readStringOrNull(Object? value) => value?.toString();

/// Дата из ISO-строки; null, если поле пустое или некорректное.
DateTime? readDateOrNull(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Дата из ISO-строки; при отсутствии — текущий момент (как и раньше).
DateTime readDateOrNow(Object? value) =>
    readDateOrNull(value) ?? DateTime.now();

/// Значение enum по имени; null для неизвестного или пустого значения.
T? enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
