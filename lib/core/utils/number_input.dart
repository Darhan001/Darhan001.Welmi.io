/// Разбирает число, введённое пользователем.
///
/// Принимает и точку, и запятую как десятичный разделитель (на русской и
/// кыргызской раскладке по умолчанию стоит запятая), игнорирует пробелы.
/// Возвращает null для пустой строки и некорректного ввода.
double? parseDecimalInput(String input) {
  final normalized = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return value;
}

/// Допустимый диапазон веса взрослого человека в килограммах.
/// Отсекает опечатки вроде «725» вместо «72.5».
const double minWeightKg = 20;
const double maxWeightKg = 400;

bool isPlausibleWeightKg(double kg) => kg >= minWeightKg && kg <= maxWeightKg;

/// Допустимый рост в сантиметрах.
const double minHeightCm = 100;
const double maxHeightCm = 250;

bool isPlausibleHeightCm(double cm) => cm >= minHeightCm && cm <= maxHeightCm;
