import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/onboarding_data.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class GoalStep extends StatelessWidget {
  final GoalType? selectedGoal;
  final ValueChanged<GoalType> onGoalChanged;

  const GoalStep({
    super.key,
    required this.selectedGoal,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'Какая у тебя цель?',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Выбери главное направление, чтобы мы могли\nнастроить план питания.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tc.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 40),
          _buildOptionCard(
            'Похудеть',
            'Снижение веса за счет создания\nбезопасного дефицита калорий',
            Icons.trending_down,
            GoalType.loseWeight,
            tc,
          ),
          _buildOptionCard(
            'Набрать массу',
            'Профицит калорий и фокус на\nбазис для роста мышц',
            Icons.fitness_center,
            GoalType.gainWeight,
            tc,
          ),
          _buildOptionCard(
            'Поддерживать вес',
            'Баланс энергии для сохранения\nтекущей формы и здоровья',
            Icons.balance,
            GoalType.maintainWeight,
            tc,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
      String title, String subtitle, IconData icon, GoalType goal, ThemeColors tc) {
    final isSelected = selectedGoal == goal;
    return GestureDetector(
      onTap: () => onGoalChanged(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: tc.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? tc.primary
                    : tc.green.withValues(alpha: tc.isDark ? 0.2 : 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? tc.textOnPrimary : tc.green,
                  size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800, fontSize: 18, color: tc.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                        color: tc.textSecondary, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
