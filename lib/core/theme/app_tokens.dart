import 'package:flutter/material.dart';

/// Размеры одной высоты кнопки: отступы и кегль подписи.
@immutable
class ButtonSizeSpec {
  const ButtonSizeSpec({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.fontSize,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;

  EdgeInsets get padding => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );
}

/// Геометрия компонентов: скругления, размеры кнопок, отступы.
///
/// Подключается к теме в `AppTheme`. Изменение значения здесь меняет
/// все `AppButton`, `AppCard`, `AppTextField` и стандартные Material-кнопки.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    this.buttonRadius = 30,
    this.buttonSmall = const ButtonSizeSpec(
      horizontalPadding: 16,
      verticalPadding: 8,
      fontSize: 13,
    ),
    this.buttonMedium = const ButtonSizeSpec(
      horizontalPadding: 24,
      verticalPadding: 14,
      fontSize: 15,
    ),
    this.buttonLarge = const ButtonSizeSpec(
      horizontalPadding: 28,
      verticalPadding: 18,
      fontSize: 17,
    ),
    this.buttonFontWeight = FontWeight.w700,
    this.iconButtonSize = 48,
    this.cardRadius = 24,
    this.cardPadding = const EdgeInsets.all(20),
    this.inputRadius = 16,
    this.dialogRadius = 24,
    this.sheetRadius = 28,
  });

  final double buttonRadius;
  final ButtonSizeSpec buttonSmall;
  final ButtonSizeSpec buttonMedium;
  final ButtonSizeSpec buttonLarge;
  final FontWeight buttonFontWeight;

  /// Минимальная зона нажатия иконочной кнопки (рекомендация доступности).
  final double iconButtonSize;

  final double cardRadius;
  final EdgeInsets cardPadding;
  final double inputRadius;
  final double dialogRadius;
  final double sheetRadius;

  static const standard = AppTokens();

  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? standard;

  @override
  AppTokens copyWith({
    double? buttonRadius,
    ButtonSizeSpec? buttonSmall,
    ButtonSizeSpec? buttonMedium,
    ButtonSizeSpec? buttonLarge,
    FontWeight? buttonFontWeight,
    double? iconButtonSize,
    double? cardRadius,
    EdgeInsets? cardPadding,
    double? inputRadius,
    double? dialogRadius,
    double? sheetRadius,
  }) {
    return AppTokens(
      buttonRadius: buttonRadius ?? this.buttonRadius,
      buttonSmall: buttonSmall ?? this.buttonSmall,
      buttonMedium: buttonMedium ?? this.buttonMedium,
      buttonLarge: buttonLarge ?? this.buttonLarge,
      buttonFontWeight: buttonFontWeight ?? this.buttonFontWeight,
      iconButtonSize: iconButtonSize ?? this.iconButtonSize,
      cardRadius: cardRadius ?? this.cardRadius,
      cardPadding: cardPadding ?? this.cardPadding,
      inputRadius: inputRadius ?? this.inputRadius,
      dialogRadius: dialogRadius ?? this.dialogRadius,
      sheetRadius: sheetRadius ?? this.sheetRadius,
    );
  }

  // Геометрия между темами не анимируется — светлая и тёмная её разделяют.
  @override
  AppTokens lerp(AppTokens? other, double t) =>
      t < 0.5 || other == null ? this : other;
}
