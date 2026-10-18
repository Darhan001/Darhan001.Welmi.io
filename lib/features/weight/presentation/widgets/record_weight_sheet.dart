import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Открывает шторку записи веса. Возвращает `true`, если вес сохранён.
///
/// [initialKg] — последний вес в кг (null, если истории нет);
/// [onSave] получает вес в кг и должен бросить исключение при ошибке.
Future<bool> showRecordWeightSheet(
  BuildContext context, {
  required double? initialKg,
  required Future<void> Function(double kg) onSave,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecordWeightSheet(initialKg: initialKg, onSave: onSave),
  );
  return saved == true;
}

/// Шторка записи веса. Владеет контроллером поля, поэтому он
/// освобождается вместе с виджетом, после анимации закрытия.
///
/// Возвращает `true` через [Navigator.pop], если вес сохранён.
class RecordWeightSheet extends StatefulWidget {
  const RecordWeightSheet({
    super.key,
    required this.initialKg,
    required this.onSave,
  });

  /// Последний сохранённый вес в кг или null, если истории ещё нет.
  final double? initialKg;
  final Future<void> Function(double kg) onSave;

  @override
  State<RecordWeightSheet> createState() => _RecordWeightSheetState();
}

class _RecordWeightSheetState extends State<RecordWeightSheet> {
  late final TextEditingController _controller;
  String? _error;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final initial = widget.initialKg;
    // Без истории поле пустое: подставлять выдуманный вес нельзя.
    if (initial != null) {
      _controller.text = AppLocalizations.of(context)!.weightValue(initial);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final loc = AppLocalizations.of(context)!;
    final entered = parseDecimalInput(_controller.text);
    final kg = entered == null
        ? null
        : UnitsService.instance.weightFromDisplay(entered);
    if (kg == null || !isPlausibleWeightKg(kg)) {
      setState(() => _error = loc.weightInvalid);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.onSave(kg);
    } catch (e) {
      debugPrint('⚠️ Save weight error: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = loc.weightSaveError;
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

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tc.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.recordWeight,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: tc.text,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    autofocus: widget.initialKg == null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    controller: _controller,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: tc.text,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.0',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: tc.textHint,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: tc.divider),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF75A47F),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  loc.weightUnitLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tc.textHint,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tc.error,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 32),
            AppButton(text: loc.save, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
