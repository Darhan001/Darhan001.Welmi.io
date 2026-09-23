import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/onboarding_data.dart' show OnboardingData, Gender;
import 'package:lumina/core/services/ai_service.dart';
import 'package:lumina/core/services/user_data_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Глобально сохраняем последний результат AI для использования на главной
AiNutritionPlan? lastAiPlan;

class CalculationStep extends StatefulWidget {
  final VoidCallback onComplete;
  final OnboardingData data;

  const CalculationStep({
    super.key,
    required this.onComplete,
    required this.data,
  });

  @override
  State<CalculationStep> createState() => _CalculationStepState();
}

class _CalculationStepState extends State<CalculationStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  String _statusText = 'Анализируем твои данные...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startCalculation();
  }

  Future<void> _startCalculation() async {
    final data = widget.data;

    // Анимированные статусы
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _statusText = 'Рассчитываем метаболизм...');

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _statusText = 'Считаем калории и БЖУ...');

    // Сначала сохраняем профиль в Supabase (даже если AI упадёт)
    try {
      await UserDataService().saveOnboardingProfile(data);
      debugPrint('✅ Профиль сохранён в Supabase');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения профиля: $e');
    }

    // Запускаем AI расчёт
    try {
      final plan = await AiService().calculateNutrition(
        heightCm: data.height,
        currentWeightKg: data.currentWeight,
        targetWeightKg: data.targetWeight,
        age: data.age,
        gender: data.gender == Gender.male ? 'male' : 'female',
        goal: data.goal?.name ?? 'maintainWeight',
        activityLevel: data.activityLevel?.name ?? 'sedentary',
        goalSpeedKgPerWeek: data.goalSpeed,
      );

      if (!mounted) return;

      // Сохраняем результат глобально
      lastAiPlan = plan;
      setState(() => _statusText = 'Персональный план готов! ✅');

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      // Даже если AI упал — переходим дальше
      setState(() => _statusText = 'План готов! ✅');
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      width: double.infinity,
      color: tc.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Анимированные круги
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildPulseRing(120, 0.1, 1.2, tc),
                      _buildPulseRing(150, 0.05, 1.4, tc),
                      _buildPulseRing(180, 0.02, 1.6, tc),
                    ],
                  );
                },
              ),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: tc.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tc.shadow(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: tc.textOnPrimary,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 54),
          Text(
            'Welmi',
            style: GoogleFonts.notoSerif(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _statusText,
              key: ValueKey(_statusText),
              style: GoogleFonts.notoSerif(
                fontSize: 14,
                color: tc.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (lastAiPlan != null) ...[
            const SizedBox(height: 24),
            // Показываем результат
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: tc.shadow(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultStat('${lastAiPlan!.dailyCalories}', 'ккал', tc),
                  _buildResultStat('${lastAiPlan!.proteinGrams}', 'белки', tc),
                  _buildResultStat('${lastAiPlan!.fatGrams}', 'жиры', tc),
                  _buildResultStat('${lastAiPlan!.carbGrams}', 'углев.', tc),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultStat(String value, String label, ThemeColors tc) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: tc.green,
          ),
        ),
        Text(label,
          style: TextStyle(
            fontSize: 10,
            color: tc.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPulseRing(double size, double opacity, double maxScale, ThemeColors tc) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * (maxScale - 1.0));
        final currentOpacity = opacity * (1.0 - _controller.value);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: tc.green.withValues(alpha:currentOpacity.clamp(0, 1)),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
