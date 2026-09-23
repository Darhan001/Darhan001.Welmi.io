import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class GoalSpeedStep extends StatefulWidget {
  final double goalSpeed;
  final ValueChanged<double> onSpeedChanged;

  const GoalSpeedStep({
    super.key,
    required this.goalSpeed,
    required this.onSpeedChanged,
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

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'Как быстро хочешь достичь\nцели?',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Выбери комфортный для себя темп',
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
                  '-${_currentValue.toStringAsFixed(1)} кг/нед',
                  style: GoogleFonts.inter(
                      fontSize: 32, fontWeight: FontWeight.w900, color: tc.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'Оптимально',
                  style: TextStyle(
                      color: tc.text, fontWeight: FontWeight.w700),
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
                        enabledThumbRadius: 10),
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
                      Text('Медленно',
                          style:
                              TextStyle(color: tc.textSecondary, fontSize: 12)),
                      Text('Быстро',
                          style:
                              TextStyle(color: tc.textSecondary, fontSize: 12)),
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
