import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lumina/core/models/workout_plan.dart';
import 'package:lumina/core/services/ai/ai_chat_message.dart';
import 'package:lumina/core/services/ai/ai_chat_session.dart';
import 'package:lumina/core/services/ai/ai_exceptions.dart';
import 'package:lumina/core/services/ai/ai_food_models.dart';
import 'package:lumina/core/services/ai/ai_food_recognizer.dart';
import 'package:lumina/core/services/ai/ai_nutrition_plan.dart';
import 'package:lumina/core/services/ai/ai_plan_generator.dart';
import 'package:lumina/core/services/ai/ai_provider_client.dart';
import 'package:lumina/core/services/ai/ai_transcriber.dart';
import 'package:lumina/core/services/auth_service.dart';

/// Единая точка доступа к AI: планы, чат, сканер еды, распознавание речи.
///
/// Сам сервис только раздаёт работу модулям из `services/ai/`; общее
/// состояние (ключи, последняя причина отказа) живёт в [AiProviderClient].
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  AiService._internal() : _client = AiProviderClient() {
    _plans = AiPlanGenerator(_client);
    _chat = AiChatSession(_client, () => AuthService().userId);
    _food = AiFoodRecognizer(_client);
    _transcriber = AiTranscriber(_client);
  }

  final AiProviderClient _client;
  late final AiPlanGenerator _plans;
  late final AiChatSession _chat;
  late final AiFoodRecognizer _food;
  late final AiTranscriber _transcriber;

  void initialize({
    required String nutritionApiKey,
    String? chatApiKey,
    String? scannerApiKey,
  }) {
    if (nutritionApiKey.startsWith('AIza')) {
      _plans.nutritionModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: nutritionApiKey,
      );
    }
    _client
      ..openRouterKey =
          chatApiKey ??
          (nutritionApiKey.startsWith('sk-or-') ? nutritionApiKey : null)
      ..scannerApiKey = scannerApiKey
      // Ключ Google AI Studio годится и для облачного распознавания речи.
      ..geminiKey =
          nutritionApiKey.isEmpty || nutritionApiKey.startsWith('sk-or-')
          ? null
          : nutritionApiKey;
  }

  // --- ПЛАНЫ ---

  /// Рассчитать персональный план питания.
  /// Сначала пробуем Gemini, при ошибке — fallback на формулы Mifflin-St Jeor.
  Future<AiNutritionPlan?> calculateNutrition({
    required double heightCm,
    required double currentWeightKg,
    required double targetWeightKg,
    required int age,
    required String gender,
    required String goal,
    required String activityLevel,
    required double goalSpeedKgPerWeek,
  }) => _plans.calculateNutrition(
    heightCm: heightCm,
    currentWeightKg: currentWeightKg,
    targetWeightKg: targetWeightKg,
    age: age,
    gender: gender,
    goal: goal,
    activityLevel: activityLevel,
    goalSpeedKgPerWeek: goalSpeedKgPerWeek,
  );

  /// Сгенерировать план питания на неделю. При ошибке — fallback.
  /// [country] — страна/регион пользователя, чтобы AI предлагал
  /// блюда местной кухни (манты, лагман, борщ и т.д.).
  /// Возвращает план и флаг `isFallback` (true — использован запасной).
  Future<({List<Map<String, dynamic>> days, bool isFallback})>
  generateMealPlan({
    required double currentWeightKg,
    required double targetWeightKg,
    required int dailyCalories,
    required String goal,
    required int proteinGrams,
    String country = '',
  }) => _plans.generateMealPlan(
    currentWeightKg: currentWeightKg,
    targetWeightKg: targetWeightKg,
    dailyCalories: dailyCalories,
    goal: goal,
    proteinGrams: proteinGrams,
    country: country,
  );

  /// Сгенерировать недельный план тренировок через AI.
  /// При ошибке или нехватке баланса — готовый запасной план по инвентарю.
  Future<WorkoutPlan> generateWorkoutPlan({
    required String goal,
    required String gender,
    required double heightCm,
    required double currentWeightKg,
    required int age,
    required String activityLevel,
    required String equipment,
  }) => _plans.generateWorkoutPlan(
    goal: goal,
    gender: gender,
    heightCm: heightCm,
    currentWeightKg: currentWeightKg,
    age: age,
    activityLevel: activityLevel,
    equipment: equipment,
  );

  // --- ЧАТ ---

  /// Возвращает ответ AI. Если ни один провайдер не ответил, бросает
  /// [AiUnavailableException]: ошибка не попадает в историю как ответ AI.
  Future<String> sendChatMessage(String message) => _chat.send(message);

  List<AiChatMessage> get chatHistory => _chat.history;

  void startNewChat() => _chat.startNew();

  /// Очищает переписку в памяти при выходе из аккаунта, не удаляя её
  /// с устройства: после повторного входа история вернётся.
  void clearInMemory() => _chat.clearInMemory();

  Future<void> saveChatHistory() => _chat.save();

  /// Загружает историю текущего пользователя. Если она уже в памяти
  /// (тот же пользователь в этой сессии) — ничего не делает.
  Future<void> loadChatHistory() => _chat.load();

  // --- ГОЛОС ---

  /// Распознаёт голосовое сообщение в текст (speech-to-text).
  ///
  /// [format] — формат записи без точки (`m4a`, `wav`, `mp3`, `ogg`).
  /// [language] — подсказка языка по ISO-639-1 (`ru`, `en`);
  ///   если null, провайдер определяет язык сам.
  /// Бросает [VoiceTranscriptionException] с причиной, если текст не получен.
  Future<String> transcribeAudio(
    Uint8List audioBytes, {
    String format = 'm4a',
    String? language,
  }) => _transcriber.transcribe(audioBytes, format: format, language: language);

  // --- ЕДА ---

  /// Сканер: КБЖУ по фото. null — распознать не удалось.
  Future<FoodAnalysisResult?> analyzeFoodImage(Uint8List imageBytes) =>
      _food.analyzeImage(imageBytes);

  /// AI-анализ распознанного текста о съеденной пище (для голосового ввода в дневник)
  Future<VoiceFoodAnalysisResult?> analyzeFoodText(String text) =>
      _food.analyzeText(text);
}
