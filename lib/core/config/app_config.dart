/// Централизованная конфигурация приложения.
///
/// Значения читаются из compile-time окружения через [String.fromEnvironment]
/// и подаются файлом `env.json`, который лежит в корне проекта рядом с
/// `pubspec.yaml` и в git не коммитится:
///
/// ```bash
/// flutter run --dart-define-from-file=env.json
/// ```
///
/// Обязательными считаются только те параметры, без которых приложение
/// реально не может работать (Supabase — вход и данные). Остальные ключи
/// (AI, сканер, Sentry) опциональны: без них приложение запускается, а
/// соответствующие функции либо отключаются, либо используют fallback.
library;

// ─────────────────────────────────────────────────────────────
// Значения из окружения (env.json → --dart-define-from-file)
// ─────────────────────────────────────────────────────────────

// Обязательные — без них нет авторизации и данных.
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

// Необязательные — приложение работает и без них.
const String geminiNutritionApiKey =
    String.fromEnvironment('GEMINI_NUTRITION_API_KEY');
const String openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
const String scannerApiKey = String.fromEnvironment('SCANNER_API_KEY');
const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

// ─────────────────────────────────────────────────────────────
// Описание требований (имена ДОЛЖНЫ совпадать с ключами env.json)
// ─────────────────────────────────────────────────────────────

/// Переменные, без которых запуск приложения невозможен.
const List<String> kRequiredEnvKeys = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];

/// Переменные, отсутствие которых НЕ блокирует запуск приложения.
const List<String> kOptionalEnvKeys = [
  'GEMINI_NUTRITION_API_KEY',
  'OPENROUTER_API_KEY',
  'SCANNER_API_KEY',
  'SENTRY_DSN',
];

bool get hasSupabaseUrl => supabaseUrl.trim().isNotEmpty;
bool get hasSupabaseAnonKey => supabaseAnonKey.trim().isNotEmpty;

/// Настроена ли обязательная часть конфигурации (Supabase).
bool get isSupabaseConfigured => hasSupabaseUrl && hasSupabaseAnonKey;

/// Отсутствующие обязательные переменные (пустой список — всё на месте).
List<String> get missingRequiredEnvKeys => [
  if (!hasSupabaseUrl) 'SUPABASE_URL',
  if (!hasSupabaseAnonKey) 'SUPABASE_ANON_KEY',
];

/// Отсутствующие необязательные переменные — запуск не блокируют.
List<String> get missingOptionalEnvKeys => [
  if (geminiNutritionApiKey.trim().isEmpty) 'GEMINI_NUTRITION_API_KEY',
  if (openRouterApiKey.trim().isEmpty) 'OPENROUTER_API_KEY',
  if (scannerApiKey.trim().isEmpty) 'SCANNER_API_KEY',
  if (sentryDsn.trim().isEmpty) 'SENTRY_DSN',
];

/// Диагностическая строка БЕЗ секретов — удобно печатать в лог при старте.
String configDiagnostics() {
  final required = missingRequiredEnvKeys;
  final optional = missingOptionalEnvKeys;
  return 'Supabase: ${required.isEmpty ? 'OK' : 'нет ${required.join(', ')}'}; '
      'опциональные: ${optional.isEmpty ? 'все заданы' : 'нет ${optional.join(', ')}'}';
}
