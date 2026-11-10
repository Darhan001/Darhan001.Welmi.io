import 'package:flutter/material.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/supabase_service.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Лист ручной записи активности за сегодня.
///
/// Возвращает `true`, если запись сохранена. Контроллеры принадлежат
/// состоянию листа и освобождаются при закрытии (раньше создавались в
/// методе страницы и не освобождались).
class LogActivitySheet extends StatefulWidget {
  const LogActivitySheet({
    super.key,
    required this.steps,
    required this.minutes,
    required this.distanceKm,
  });

  final int steps;
  final double minutes;
  final double distanceKm;

  static Future<bool?> show(
    BuildContext context, {
    required int steps,
    required double minutes,
    required double distanceKm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogActivitySheet(
        steps: steps,
        minutes: minutes,
        distanceKm: distanceKm,
      ),
    );
  }

  @override
  State<LogActivitySheet> createState() => _LogActivitySheetState();
}

class _LogActivitySheetState extends State<LogActivitySheet> {
  late final TextEditingController _steps;
  late final TextEditingController _minutes;
  late final TextEditingController _distance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _steps = TextEditingController(
      text: widget.steps > 0 ? '${widget.steps}' : '',
    );
    _minutes = TextEditingController(
      text: widget.minutes > 0 ? '${widget.minutes.toInt()}' : '',
    );
    _distance = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_distance.text.isEmpty && widget.distanceKm > 0) {
      _distance.text = AppLocalizations.of(
        context,
      )!.distanceValue(widget.distanceKm);
    }
  }

  @override
  void dispose() {
    _steps.dispose();
    _minutes.dispose();
    _distance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final userId = AuthService().userId;
    // Без входа запись некуда сохранить — не делаем вид, что сохранили.
    if (userId == null) {
      showWelmiSnackbar(context, loc.signInRequired, icon: Icons.lock_outline);
      return;
    }
    final steps = int.tryParse(_steps.text.trim()) ?? 0;
    final minutes = parseDecimalInput(_minutes.text) ?? 0;
    final distance = UnitsService.instance.distanceFromDisplay(
      parseDecimalInput(_distance.text) ?? 0,
    );

    setState(() => _saving = true);
    try {
      await SupabaseService().saveActivityLog(
        ActivityLog(
          userId: userId,
          steps: steps,
          caloriesBurned: steps * 0.045,
          activeMinutes: minutes,
          distanceKm: distance > 0 ? distance : null,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Save activity error: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showWelmiSnackbar(context, loc.saveError, icon: Icons.error_outline);
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
        bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tc.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.logActivity,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 20),
          _field(tc, _steps, loc.stepsLabel, loc.stepsHint, decimal: false),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(tc, _minutes, loc.minutesLabel, '30')),
              const SizedBox(width: 12),
              Expanded(
                child: _field(tc, _distance, loc.distanceUnitLabel, '3,5'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(
            text: loc.save,
            size: AppButtonSize.lg,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _field(
    ThemeColors tc,
    TextEditingController controller,
    String label,
    String hint, {
    bool decimal = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: tc.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: tc.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
