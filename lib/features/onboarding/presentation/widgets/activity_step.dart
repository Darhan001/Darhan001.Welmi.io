import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/onboarding_data.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class ActivityStep extends StatelessWidget {
  final ActivityLevel? selectedActivity;
  final ValueChanged<ActivityLevel> onActivityChanged;

  const ActivityStep({
    super.key,
    required this.selectedActivity,
    required this.onActivityChanged,
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
            'Насколько ты активен?',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Это поможет нам точнее рассчитать твою\nнорму калорий',
            textAlign: TextAlign.center,
            style: TextStyle(color: tc.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 40),
          _buildActivityCard(
            'Малоподвижный',
            'Офисная работа, почти без спорта.',
            Icons.person_outline,
            ActivityLevel.sedentary,
            tc,
          ),
          _buildActivityCard(
            'Лёгкая активность',
            '1-2 тренировки в неделю или прогулки.',
            Icons.directions_walk,
            ActivityLevel.light,
            tc,
          ),
          _buildActivityCard(
            'Средняя активность',
            '3-5 тренировок в неделю, активный образ жизни.',
            Icons.directions_run,
            ActivityLevel.moderate,
            tc,
          ),
          _buildActivityCard(
            'Высокая активность',
            'Ежедневные интенсивные тренировки.',
            Icons.fitness_center,
            ActivityLevel.high,
            tc,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
      String title, String subtitle, IconData icon, ActivityLevel level, ThemeColors tc) {
    final isSelected = selectedActivity == level;
    return GestureDetector(
      onTap: () => onActivityChanged(level),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: tc.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? tc.primary
                    : (tc.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? tc.textOnPrimary : tc.textSecondary,
                  size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 15, color: tc.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        GoogleFonts.inter(color: tc.textSecondary, fontSize: 12),
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
