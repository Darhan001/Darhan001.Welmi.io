import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Система единиц, выбранная пользователем.
///
/// Значения совпадают с колонкой `profiles.units_system` в Supabase.
enum UnitSystem {
  metric('metric'),
  imperial('imperial');

  const UnitSystem(this.code);
  final String code;

  static UnitSystem fromCode(String? code) => code == UnitSystem.imperial.code
      ? UnitSystem.imperial
      : UnitSystem.metric;
}

/// Единицы измерения веса и расстояния.
///
/// Данные везде хранятся в метрике (кг, км) — меняется только отображение
/// и ввод. Поэтому переключение не трогает сохранённые записи пользователя.
class UnitsService extends ValueNotifier<UnitSystem> {
  UnitsService._() : super(UnitSystem.metric);

  static final UnitsService instance = UnitsService._();

  static const String _prefKey = 'units_system';
  static const double lbPerKg = 2.20462262185;
  static const double miPerKm = 0.621371192237;

  bool get isImperial => value == UnitSystem.imperial;

  /// Выбирал ли пользователь единицы на этом устройстве.
  bool _hasLocalChoice = false;

  /// Восстанавливает выбор, сохранённый на устройстве.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      _hasLocalChoice = code != null;
      value = UnitSystem.fromCode(code);
    } catch (e) {
      debugPrint('⚠️ Units load error: $e');
    }
  }

  /// Сохраняет выбор на устройстве. Синхронизацию с профилем делает
  /// вызывающий код (см. настройки), чтобы сервис не зависел от Supabase.
  Future<void> setSystem(UnitSystem system) async {
    value = system;
    _hasLocalChoice = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, system.code);
  }

  /// Подхватывает значение из профиля при первом входе на устройстве.
  /// Если пользователь уже выбирал единицы здесь, локальный выбор важнее:
  /// он мог быть сделан офлайн и ещё не дойти до профиля.
  Future<void> adoptFromProfile(String? code) async {
    if (code == null || _hasLocalChoice) return;
    final system = UnitSystem.fromCode(code);
    if (system != value) await setSystem(system);
  }

  // ─── Вес ───

  double weightToDisplay(double kg) => isImperial ? kg * lbPerKg : kg;

  /// Переводит введённое пользователем значение обратно в килограммы.
  double weightFromDisplay(double value) =>
      isImperial ? value / lbPerKg : value;

  String weightUnit({required String kg, required String lb}) =>
      isImperial ? lb : kg;

  /// «72.5 кг» / «159.8 lb». [signed] добавляет «+» к положительным значениям.
  String formatWeight(
    double kg, {
    required String kgLabel,
    required String lbLabel,
    int decimals = 1,
    bool signed = false,
  }) {
    final v = weightToDisplay(kg);
    final sign = signed && v > 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(decimals)} ${weightUnit(kg: kgLabel, lb: lbLabel)}';
  }

  // ─── Расстояние ───

  double distanceToDisplay(double km) => isImperial ? km * miPerKm : km;

  /// Переводит введённое расстояние обратно в километры.
  double distanceFromDisplay(double value) =>
      isImperial ? value / miPerKm : value;

  String distanceUnit({required String km, required String mi}) =>
      isImperial ? mi : km;
}
