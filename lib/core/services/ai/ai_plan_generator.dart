import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lumina/core/models/workout_plan.dart';
import 'package:lumina/core/services/ai/ai_json.dart';
import 'package:lumina/core/services/ai/ai_nutrition_plan.dart';
import 'package:lumina/core/services/ai/ai_prompts.dart';
import 'package:lumina/core/services/ai/ai_provider_client.dart';
import 'package:lumina/core/services/ai/meal_plan_fallback.dart';
import 'package:lumina/core/services/ai/workout_plan_fallback.dart';

/// Планы питания и тренировок. При недоступности AI — запасные варианты.
class AiPlanGenerator {
  AiPlanGenerator(this._client);

  final AiProviderClient _client;

  /// Модель Gemini SDK — только для валидного ключа Google AI Studio.
  GenerativeModel? nutritionModel;

  /// Сначала пробуем Gemini SDK, затем OpenRouter → Gemini REST,
  /// при ошибке — формулы Mifflin-St Jeor.
  Future<AiNutritionPlan> calculateNutrition({
    required double heightCm,
    required double currentWeightKg,
    required double targetWeightKg,
    required int age,
    required String gender,
    required String goal,
    required String activityLevel,
    required double goalSpeedKgPerWeek,
  }) async {
    final prompt = AiPrompts.nutrition(
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      age: age,
      gender: gender,
      goal: goal,
      activityLevel: activityLevel,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    );

    // 1) Сначала Gemini SDK, если ключ валиден
    final model = nutritionModel;
    if (model != null) {
      try {
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 30));
        final json = extractJsonObject(response.text ?? '');
        if (json != null) return AiNutritionPlan.fromJson(json);
      } catch (e) {
        debugPrint('⚠️ Gemini nutrition error: $e');
      }
    }

    // 2) Если не вышло — пробуем OpenRouter → Gemini REST
    try {
      final text = await _client.complete(
        systemPrompt: AiPrompts.nutritionistSystem,
        userPrompt: prompt,
        maxTokens: 800,
        budget: const Duration(seconds: 50),
      );
      final json = text == null ? null : extractJsonObject(text);
      if (json != null) return AiNutritionPlan.fromJson(json);
    } catch (e) {
      debugPrint('⚠️ Nutrition AI fallback error: $e');
    }

    return AiNutritionPlan.mifflinStJeor(
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      age: age,
      gender: gender,
      goal: goal,
      activityLevel: activityLevel,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    );
  }

  Future<({List<Map<String, dynamic>> days, bool isFallback})>
  generateMealPlan({
    required double currentWeightKg,
    required double targetWeightKg,
    required int dailyCalories,
    required String goal,
    required int proteinGrams,
    String country = '',
  }) async {
    try {
      // Пробуем все доступные AI-каналы: OpenRouter → Gemini REST.
      final text = await _client.complete(
        systemPrompt: AiPrompts.nutritionistSystem,
        userPrompt: AiPrompts.mealPlan(
          currentWeightKg: currentWeightKg,
          targetWeightKg: targetWeightKg,
          dailyCalories: dailyCalories,
          goal: goal,
          proteinGrams: proteinGrams,
          country: country,
        ),
        maxTokens: 1800,
        budget: const Duration(seconds: 55),
      );
      final parsed = text == null ? null : parseWeekPlan(text);
      if (parsed != null && parsed.isNotEmpty) {
        return (days: withCurrentWeekDates(parsed), isFallback: false);
      }
    } catch (e) {
      debugPrint('⚠️ Meal plan AI error: $e');
    }
    return (
      days: fallbackMealPlan(goal, dailyCalories, country),
      isFallback: true,
    );
  }

  Future<WorkoutPlan> generateWorkoutPlan({
    required String goal,
    required String gender,
    required double heightCm,
    required double currentWeightKg,
    required int age,
    required String activityLevel,
    required String equipment,
  }) async {
    try {
      // Если баланс закончился — переключится на другой ключ/провайдер.
      final text = await _client.complete(
        systemPrompt: AiPrompts.trainerSystem,
        userPrompt: AiPrompts.workoutPlan(
          goal: goal,
          gender: gender,
          heightCm: heightCm,
          currentWeightKg: currentWeightKg,
          age: age,
          activityLevel: activityLevel,
          equipment: equipment,
        ),
        maxTokens: 2000,
        budget: const Duration(seconds: 55),
      );
      final parsed = text == null ? null : parseWorkoutPlan(text);
      if (parsed != null && parsed.days.isNotEmpty) return parsed;
    } catch (e) {
      debugPrint('⚠️ Workout plan AI error: $e');
    }
    return fallbackWorkoutPlan(equipment);
  }
}
