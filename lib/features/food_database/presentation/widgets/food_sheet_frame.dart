import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Оформление нижних листов питания: скруглённый фон, «ручка» сверху,
/// отступ под клавиатуру и прокрутка, если содержимое не помещается.
class FoodSheetFrame extends StatelessWidget {
  final List<Widget> children;

  /// Отступ под «ручкой».
  final double handleGap;

  const FoodSheetFrame({
    super.key,
    required this.children,
    this.handleGap = 20,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final bottomInset = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.paddingOf(context).bottom,
    );

    return Container(
      decoration: BoxDecoration(
        color: tc.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: handleGap),
                  decoration: BoxDecoration(
                    color: tc.inactive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Поле ввода в листах питания (название, калории, БЖУ).
class NutritionTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? hint;

  const NutritionTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.hint,
  });

  /// Клавиатура и фильтр для дробных чисел: точка или запятая
  /// (на ru/ky-раскладке разделитель — запятая).
  static const decimalKeyboard = TextInputType.numberWithOptions(decimal: true);
  static final decimalFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  ];

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: tc.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: hint == null ? null : TextStyle(color: tc.textHint),
        filled: true,
        fillColor: tc.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: tc.textSecondary,
        ),
      ),
    );
  }
}
