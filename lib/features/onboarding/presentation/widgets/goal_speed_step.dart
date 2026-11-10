import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

class GoalSpeedStep extends StatefulWidget {
  final double goalSpeed;
  final ValueChanged<double> onSpeedChanged;

  /// Цель — набор веса: темп показывается со знаком «+».
  final bool isGain;

  const GoalSpeedStep({
    super.key,
    required this.goalSpeed,
    required this.onSpeedChanged,
    this.isGain = false,
  });

  @override
  State<GoalSpeedStep> createState() => _GoalSpeedStepState();
}

class _GoalSpeedStepState extends State<GoalSpeedStep> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.goalSpeed;
  }

  @override
  void didUpdateWidget(GoalSpeedStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goalSpeed != widget.goalSpeed) {
      _currentValue = widget.goalSpeed;
    }
  }

  /// Оценка выбранного темпа: раньше подпись всегда была «Оптимально»,
  /// даже на максимальном 1 кг в неделю.
  String _paceLabel(AppLocalizations loc) {
    if (_currentValue < 0.4) return loc.slow;
    if (_currentValue <= 0.7) return loc.optimal;
    return loc.fast;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            AppLocalizations.of(context)!.onboardingSpeedTitle,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.onboardingSpeedSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: tc.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 60),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.isGain ? '+' : '−'}${_currentValue.toStringAsFixed(1)} ${AppLocalizations.of(context)!.kgPerWeek}',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: tc.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _paceLabel(AppLocalizations.of(context)!),
                  style: TextStyle(color: tc.text, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 40),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: tc.primary,
                    inactiveTrackColor: tc.divider,
                    thumbColor: tc.primary,
                    overlayColor: tc.shadow(0.1),
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: _currentValue,
                    min: 0.2,
                    max: 1.0,
                    divisions: 8,
                    onChanged: (value) {
                      setState(() {
                        _currentValue = value;
                      });
                      widget.onSpeedChanged(value);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.slow,
                        style: TextStyle(color: tc.textSecondary, fontSize: 12),
                      ),
                      Text(
                        AppLocalizations.of(context)!.fast,
                        style: TextStyle(color: tc.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
