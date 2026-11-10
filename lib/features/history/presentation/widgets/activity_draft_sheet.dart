import 'package:flutter/material.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/history/presentation/widgets/history_form_parts.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Введённая активность до сохранения.
class ActivityDraft {
  const ActivityDraft({
    required this.steps,
    required this.minutes,
    required this.distanceDisplay,
  });

  final int steps;
  final int minutes;

  /// Расстояние в единицах пользователя (переводится в км на экране).
  final double distanceDisplay;
}

/// Запись шагов за день.
Future<ActivityDraft?> showActivityDraftSheet(BuildContext context) =>
    showHistorySheet<ActivityDraft>(
      context,
      (_) => const _ActivityDraftSheet(),
    );

class _ActivityDraftSheet extends StatefulWidget {
  const _ActivityDraftSheet();

  @override
  State<_ActivityDraftSheet> createState() => _ActivityDraftSheetState();
}

class _ActivityDraftSheetState extends State<_ActivityDraftSheet> {
  // Контроллеры живут в состоянии шторки и освобождаются при закрытии.
  final _steps = TextEditingController();
  final _minutes = TextEditingController();
  final _distance = TextEditingController();

  @override
  void dispose() {
    _steps.dispose();
    _minutes.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return HistorySheetFrame(
      title: loc.logActivity,
      submitLabel: loc.save,
      onSubmit: () => Navigator.pop(
        context,
        ActivityDraft(
          steps: int.tryParse(_steps.text.trim()) ?? 0,
          minutes: parseDecimalInput(_minutes.text)?.round() ?? 0,
          distanceDisplay: parseDecimalInput(_distance.text) ?? 0,
        ),
      ),
      children: [
        HistoryFormField(
          controller: _steps,
          label: loc.stepsLabel,
          hint: loc.stepsHint,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: HistoryFormField(
                controller: _minutes,
                label: loc.minutesLabel,
                hint: '30',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HistoryFormField(
                controller: _distance,
                label: loc.distanceUnitLabel,
                hint: '3,5',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
