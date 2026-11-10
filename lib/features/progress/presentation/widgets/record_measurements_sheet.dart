import 'package:flutter/material.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Открывает шторку записи замеров. Возвращает `true`, если замеры сохранены.
///
/// [latest] — последние замеры для предзаполнения; [onSave] получает новую
/// запись и должен бросить исключение при ошибке.
Future<bool> showRecordMeasurementsSheet(
  BuildContext context, {
  required String userId,
  required BodyMeasurement? latest,
  required Future<void> Function(BodyMeasurement) onSave,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        RecordMeasurementsSheet(userId: userId, latest: latest, onSave: onSave),
  );
  return saved == true;
}

/// Шторка записи замеров. Владеет контроллерами полей и освобождает их.
class RecordMeasurementsSheet extends StatefulWidget {
  const RecordMeasurementsSheet({
    super.key,
    required this.userId,
    required this.latest,
    required this.onSave,
  });

  final String userId;
  final BodyMeasurement? latest;
  final Future<void> Function(BodyMeasurement) onSave;

  @override
  State<RecordMeasurementsSheet> createState() =>
      _RecordMeasurementsSheetState();
}

class _RecordMeasurementsSheetState extends State<RecordMeasurementsSheet> {
  late final TextEditingController _chest;
  late final TextEditingController _waist;
  late final TextEditingController _hips;
  late final TextEditingController _arm;
  late final TextEditingController _thigh;
  late final TextEditingController _neck;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final m = widget.latest;
    TextEditingController ctl(double? v) => TextEditingController(
      text: v != null && v > 0 ? v.toStringAsFixed(0) : '',
    );
    _chest = ctl(m?.chestCm);
    _waist = ctl(m?.waistCm);
    _hips = ctl(m?.hipsCm);
    _arm = ctl(m?.leftArmCm ?? m?.rightArmCm);
    _thigh = ctl(m?.leftThighCm ?? m?.rightThighCm);
    _neck = ctl(m?.neckCm);
  }

  @override
  void dispose() {
    for (final c in [_chest, _waist, _hips, _arm, _thigh, _neck]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Положительное число из поля или null (пустое/некорректное поле).
  static double? _value(TextEditingController c) {
    final v = parseDecimalInput(c.text);
    return v != null && v > 0 ? v : null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final loc = AppLocalizations.of(context)!;
    final arm = _value(_arm);
    final thigh = _value(_thigh);
    final measurement = BodyMeasurement(
      userId: widget.userId,
      date: DateTime.now(),
      chestCm: _value(_chest),
      waistCm: _value(_waist),
      hipsCm: _value(_hips),
      leftArmCm: arm,
      rightArmCm: arm,
      leftThighCm: thigh,
      rightThighCm: thigh,
      neckCm: _value(_neck),
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(measurement);
    } catch (e) {
      debugPrint('⚠️ Save measurements error: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = loc.saveError;
        });
      }
      return;
    }
    hapticSuccess();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loc = AppLocalizations.of(context)!;
    final fields = [
      (loc.chestCm, _chest),
      (loc.waistCm, _waist),
      (loc.hipsCm, _hips),
      (loc.armCm, _arm),
      (loc.thighCm, _thigh),
      (loc.neckCm, _neck),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.recordMeasurements,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 20),
            for (final (label, controller) in fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MeasureField(
                  label: label,
                  hint: loc.unitCm,
                  controller: controller,
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tc.error,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            AppButton(text: loc.save, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _MeasureField extends StatelessWidget {
  const _MeasureField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: tc.text),
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(color: tc.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: tc.textHint),
              filled: true,
              fillColor: tc.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tc.divider),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
