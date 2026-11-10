import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/daily_tracker.dart';
import 'package:lumina/core/services/units_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/utils/number_input.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/app_snackbar.dart';
import 'package:lumina/core/widgets/units_format.dart';
import 'package:lumina/features/goal/domain/goal_profile_update.dart';
import 'package:lumina/features/goal/presentation/widgets/goal_choice_chip.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Шторка изменения цели. Возвращает true, если цель сохранена.
Future<bool?> showGoalEditSheet(BuildContext context, UserProfile profile) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GoalEditSheet(profile: profile),
  );
}

class GoalEditSheet extends StatefulWidget {
  const GoalEditSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends State<GoalEditSheet> {
  static const _speeds = [0.25, 0.5, 0.75, 1.0];

  // Контроллер живёт в State и освобождается в dispose: раньше он
  // создавался в методе страницы и не освобождался.
  late final TextEditingController _targetCtl;
  GoalType? _goal;
  late double _speed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.profile.goal;
    _speed = widget.profile.goalSpeedKgPerWeek;
    _targetCtl = TextEditingController(
      text: UnitsService.instance
          .weightToDisplay(widget.profile.targetWeightKg)
          .toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _targetCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final entered = parseDecimalInput(_targetCtl.text);
    final targetKg = entered == null
        ? null
        : UnitsService.instance.weightFromDisplay(entered);
    if (targetKg == null || !isPlausibleWeightKg(targetKg)) {
      AppSnackbar.error(context, loc.enterValidWeight);
      return;
    }
    final goal = _goal;
    if (goal == null) {
      AppSnackbar.error(context, loc.selectGoalType);
      return;
    }

    setState(() => _saving = true);
    try {
      await UserDataService().saveProfile(
        profileWithGoal(
          widget.profile,
          goal: goal,
          targetWeightKg: targetKg,
          goalSpeedKgPerWeek: _speed,
        ),
      );
      // loadToday пересчитывает цели калорий/БЖУ из профиля,
      // так что главная обновится сразу после изменения цели.
      await DailyTracker().loadToday();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('❌ Goal save error: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, loc.saveError);
    }
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
      child: SingleChildScrollView(
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
            Center(
              child: Text(
                loc.editGoal,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: tc.text,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel(loc.goalTypeLabel),
            const SizedBox(height: 12),
            Row(
              children: [
                _goalChip(GoalType.loseWeight, '🔥', loc.goalLoseWeight),
                const SizedBox(width: 8),
                _goalChip(
                  GoalType.maintainWeight,
                  '⚖️',
                  loc.goalMaintainWeight,
                ),
                const SizedBox(width: 8),
                _goalChip(GoalType.gainWeight, '💪', loc.goalGainWeight),
              ],
            ),
            const SizedBox(height: 24),
            _SectionLabel(loc.targetWeightLabel),
            const SizedBox(height: 12),
            _targetField(tc, loc),
            const SizedBox(height: 24),
            _SectionLabel(loc.goalSpeedLabel),
            const SizedBox(height: 12),
            Row(children: [for (final s in _speeds) _speedChip(tc, loc, s)]),
            const SizedBox(height: 32),
            AppButton(
              text: loc.save,
              size: AppButtonSize.lg,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalChip(GoalType goal, String emoji, String label) {
    final tc = ThemeColors.of(context);
    final selected = _goal == goal;
    return Expanded(
      child: GoalChoiceChip(
        selected: selected,
        onTap: () => setState(() => _goal = goal),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
                color: selected ? GoalChoiceChip.accent(tc) : tc.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetField(ThemeColors tc, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: _targetCtl,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: tc.text,
            ),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: tc.divider),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: tc.green, width: 2),
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
    );
  }

  Widget _speedChip(ThemeColors tc, AppLocalizations loc, double speed) {
    final selected = _speed == speed;
    final color = selected ? GoalChoiceChip.accent(tc) : null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GoalChoiceChip(
          selected: selected,
          radius: 14,
          padding: const EdgeInsets.symmetric(vertical: 12),
          onTap: () => setState(() => _speed = speed),
          child: Column(
            children: [
              Text(
                speed.toString(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: color ?? tc.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                loc.kgPerWeek,
                style: TextStyle(
                  fontSize: 9,
                  color: color ?? tc.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: ThemeColors.of(context).textHint,
      ),
    );
  }
}
