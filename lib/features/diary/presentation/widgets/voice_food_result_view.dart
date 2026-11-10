import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/ai/ai_food_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/features/diary/presentation/widgets/voice_food_items_card.dart';

/// Результат распознавания: что услышали, что нашёл AI и что попадёт
/// в дневник. Значения можно поправить вручную перед сохранением.
class VoiceFoodResultView extends StatelessWidget {
  const VoiceFoodResultView({
    super.key,
    required this.result,
    required this.recognizedText,
    required this.isEditing,
    required this.isSaving,
    required this.nameController,
    required this.kcalController,
    required this.proteinController,
    required this.fatController,
    required this.carbsController,
    required this.clarifyController,
    required this.onToggleEditing,
    required this.onSubmitClarification,
    required this.onRestart,
    required this.onSave,
  });

  final VoiceFoodAnalysisResult result;
  final String recognizedText;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController nameController;
  final TextEditingController kcalController;
  final TextEditingController proteinController;
  final TextEditingController fatController;
  final TextEditingController carbsController;
  final TextEditingController clarifyController;
  final VoidCallback onToggleEditing;
  final VoidCallback onSubmitClarification;
  final VoidCallback onRestart;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final needsClarification = result.clarificationNeeded?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RecognizedQuote(text: recognizedText),
        const SizedBox(height: 14),
        Text(
          'Распознано:',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: tc.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        VoiceFoodItemsCard(items: result.items),
        if (needsClarification) ...[
          const SizedBox(height: 12),
          VoiceFoodClarifyCard(
            question: result.clarificationNeeded!,
            controller: clarifyController,
            onSubmit: onSubmitClarification,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Примерная оценка:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tc.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: onToggleEditing,
              child: Text(
                isEditing ? 'Скрыть правку' : 'Изменить данные',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tc.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isEditing)
          _EditFields(
            nameController: nameController,
            kcalController: kcalController,
            proteinController: proteinController,
            fatController: fatController,
            carbsController: carbsController,
          )
        else
          _MacroSummary(
            kcal: kcalController.text,
            protein: proteinController.text,
            fat: fatController.text,
            carbs: carbsController.text,
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: AppLocalizations.of(context)!.voiceSayAgain,
                variant: AppButtonVariant.outline,
                onPressed: onRestart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppButton(
                text: AppLocalizations.of(context)!.addToDiary,
                loading: isSaving,
                onPressed: needsClarification ? null : onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Распознанный текст — что именно услышали.
class _RecognizedQuote extends StatelessWidget {
  const _RecognizedQuote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, size: 18, color: tc.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: tc.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Компактные макросы без полей ввода.
class _MacroSummary extends StatelessWidget {
  const _MacroSummary({
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final String kcal;
  final String protein;
  final String fat;
  final String carbs;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tc.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MacroColumn(label: 'Калории', value: '$kcal ккал', color: tc.text),
          _MacroColumn(
            label: 'Белки',
            value: '$protein г',
            color: const Color(0xFF75A47F),
          ),
          _MacroColumn(
            label: 'Жиры',
            value: '$fat г',
            color: const Color(0xFFFFB347),
          ),
          _MacroColumn(
            label: 'Углеводы',
            value: '$carbs г',
            color: const Color(0xFF4A90E2),
          ),
        ],
      ),
    );
  }
}

/// Поля ручной правки значений перед сохранением.
class _EditFields extends StatelessWidget {
  const _EditFields({
    required this.nameController,
    required this.kcalController,
    required this.proteinController,
    required this.fatController,
    required this.carbsController,
  });

  final TextEditingController nameController;
  final TextEditingController kcalController;
  final TextEditingController proteinController;
  final TextEditingController fatController;
  final TextEditingController carbsController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EditField(label: 'Название', controller: nameController),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _EditField(
                label: 'Калории',
                controller: kcalController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _EditField(
                label: 'Белки (г)',
                controller: proteinController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _EditField(
                label: 'Жиры (г)',
                controller: fatController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _EditField(
                label: 'Углеводы (г)',
                controller: carbsController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: tc.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: tc.textSecondary),
        isDense: true,
        filled: true,
        fillColor: tc.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tc.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tc.divider),
        ),
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  const _MacroColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: tc.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
