import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Форматирование веса и расстояния в выбранных пользователем единицах.
///
/// Значения на входе всегда метрические (кг, км), как они хранятся в БД.
extension UnitsFormat on AppLocalizations {
  UnitsService get _units => UnitsService.instance;

  /// Обозначение единицы веса: «кг» или «lb».
  String get weightUnitLabel => _units.weightUnit(kg: unitKg, lb: unitLb);

  /// Обозначение единицы расстояния: «км» или «mi».
  String get distanceUnitLabel => _units.distanceUnit(km: unitKm, mi: unitMi);

  /// «72.5 кг» / «159.8 lb». Не `weight`: это имя уже занято подписью «Вес».
  String formatWeight(double kg, {int decimals = 1, bool signed = false}) =>
      _units.formatWeight(
        kg,
        kgLabel: unitKg,
        lbLabel: unitLb,
        decimals: decimals,
        signed: signed,
      );

  /// Только число без единицы — для крупных цифр с подписью рядом.
  String weightValue(double kg, {int decimals = 1}) =>
      _units.weightToDisplay(kg).toStringAsFixed(decimals);

  /// «5.2 км» / «3.2 mi».
  String formatDistance(double km, {int decimals = 1}) =>
      '${_units.distanceToDisplay(km).toStringAsFixed(decimals)} $distanceUnitLabel';

  /// Только число расстояния.
  String distanceValue(double km, {int decimals = 1}) =>
      _units.distanceToDisplay(km).toStringAsFixed(decimals);
}
