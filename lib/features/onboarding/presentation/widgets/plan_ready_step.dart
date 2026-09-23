import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/onboarding_data.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class PlanReadyStep extends StatelessWidget {
  final OnboardingData data;

  const PlanReadyStep({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final calories = data.dailyCalories;
    final protein = data.proteinGrams;
    final fat = data.fatGrams;
    final carbs = data.carbGrams;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welmi',
                style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.w900, fontSize: 18, color: tc.text),
              ),
              Icon(Icons.check_circle, color: tc.divider, size: 24),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tc.isDark ? tc.green.withValues(alpha: 0.2) : const Color(0xFFE8F3E5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco, color: tc.green, size: 24),
          ),
          const SizedBox(height: 24),
          Text(
            'Твой персональный план готов!',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
                fontSize: 22, fontWeight: FontWeight.w900, color: tc.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Мы рассчитали идеальный баланс для\nдостижения твоей цели.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: tc.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 32),
          _buildCalorieCard(calories, tc),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildMacroCard(
                      '$protein г', 'белки', const Color(0xFFE8F3F5), tc)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMacroCard(
                      '$fat г', 'жиры', const Color(0xFFFDF5E6), tc)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMacroCard(
                      '$carbs г', 'углеводы', const Color(0xFFF0F0F0), tc)),
            ],
          ),
          const SizedBox(height: 24),
          _buildWeightChartCard(data, tc),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(int calories, ThemeColors tc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'ДНЕВНАЯ НОРМА',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: tc.textSecondary,
                letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$calories',
                  style: GoogleFonts.inter(
                      fontSize: 36, fontWeight: FontWeight.w900, color: tc.text)),
              const SizedBox(width: 4),
              Text('ккал',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: tc.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String val, String label, Color color, ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(width: 20, height: 2, color: color),
          const SizedBox(height: 8),
          Text(val,
              style:
                  TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: tc.text)),
          Text(label,
              style: TextStyle(color: tc.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildWeightChartCard(OnboardingData data, ThemeColors tc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.goal == GoalType.loseWeight ? 'Снижение веса'
                    : data.goal == GoalType.gainWeight ? 'Набор веса'
                    : 'Поддержание веса',
                style: TextStyle(fontWeight: FontWeight.w800, color: tc.text),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tc.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${data.goalSpeed.toStringAsFixed(1)} кг / нед',
                  style:
                      TextStyle(fontSize: 10, color: tc.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: tc.isDark ? tc.green.withValues(alpha: 0.15) : const Color(0xFFE8F3E5).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(painter: ChartPainter(isDark: tc.isDark)),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final bool isDark;
  ChartPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF75A47F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, 20);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.5, size.width, size.height - 20);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = isDark ? Colors.white70 : Colors.black;
    canvas.drawCircle(
        Offset(size.width, size.height - 20), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
