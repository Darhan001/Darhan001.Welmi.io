/// Публичный API AI-сервиса. Реализация разнесена по `services/ai/`:
/// модели и исключения, промпты, сетевой клиент, планы, чат, сканер еды,
/// распознавание речи и запасные данные.
library;

export 'ai/ai_chat_message.dart';
export 'ai/ai_exceptions.dart';
export 'ai/ai_facade.dart' show AiService;
export 'ai/ai_food_models.dart';
export 'ai/ai_nutrition_plan.dart';
