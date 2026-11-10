import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/progress/domain/progress_metrics.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Открывает шторку записи % жира. Возвращает `true`, если значение сохранено.
///
/// [initialPercent]/[initialMethod] — последняя запись (null, если её нет);
/// [onSave] должен бросить исключение при ошибке.
Future<bool> showRecordBodyFatSheet(
  BuildContext context, {
  required double? initialPercent,
  required String? initialMethod,
  required Future<void> Function(double percent, String method) onSave,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => RecordBodyFatSheet(
      initialPercent: initialPercent,
      initialMethod: initialMethod,
      onSave: onSave,
    ),
  );
  return saved == true;
}

class RecordBodyFatSheet extends StatefulWidget {
  const RecordBodyFatSheet({
    super.key,
    required this.initialPercent,
    required this.initialMethod,
    required this.onSave,
  });

  final double? initialPercent;
  final String? initialMethod;
  final Future<void> Function(double percent, String method) onSave;

  @override
  State<RecordBodyFatSheet> createState() => _RecordBodyFatSheetState();
}

class _RecordBodyFatSheetState extends State<RecordBodyFatSheet> {
  static const _methods = [
    ('caliper', Icons.monitor_weight_outlined),
    ('scale', Icons.monitor_heart_outlined),
    ('manual', Icons.edit),
  ];

  late final TextEditingController _controller;
  late String _method;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Без истории поле пустое: подставлять выдуманные «20 %» нельзя.
    final initial = widget.initialPercent;
    _controller = TextEditingController(
      text: initial != null ? initial.toStringAsFixed(1) : '',
    );
    final m = widget.initialMethod;
    // «Оценка» ставится только расчётом, вручную её не выбирают.
    _method = _methods.any((e) => e.$1 == m) ? m! : 'manual';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final loc = AppLocalizations.of(context)!;
    final pct = parseDecimalInput(_controller.text);
    if (pct == null || !isPlausibleBodyFat(pct)) {
      setState(() => _error = AppLocalizations.of(context)!.bfRangeError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(pct, _method);
    } catch (e) {
      debugPrint('⚠️ Save body fat error: $e');
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

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.recordBodyFat,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _controller,
                  autofocus: widget.initialPercent == null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: tc.surface,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tc.textSecondary,
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
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
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, icon) in _methods)
                _MethodChip(
                  label: switch (value) {
                    'caliper' => loc.bfChipCaliper,
                    'scale' => loc.bfChipScale,
                    _ => loc.bfChipManual,
                  },
                  icon: icon,
                  selected: _method == value,
                  onTap: () => setState(() => _method = value),
                ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(text: loc.save, loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final fg = selected ? tc.textOnPrimary : tc.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tc.primary : tc.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected ? null : Border.all(color: tc.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
