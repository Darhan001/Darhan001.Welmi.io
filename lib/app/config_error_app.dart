import 'package:flutter/material.dart';
import 'package:lumina/core/config/app_config.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/core/theme/theme_colors.dart';

/// Экран, показываемый если обязательная конфигурация (Supabase) не передана.
/// Показывается только когда отсутствует SUPABASE_URL / SUPABASE_ANON_KEY —
/// отсутствие необязательных ключей (AI, Sentry) приложение не блокирует.
///
/// Тексты не локализованы намеренно: экран адресован разработчику и
/// показывается до инициализации локализации.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.missingKeys});

  /// Имена отсутствующих обязательных переменных окружения.
  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) {
    final missing = missingKeys.isEmpty
        ? kRequiredEnvKeys.join(', ')
        : missingKeys.join(', ');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Welmi',
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) {
          final tc = ThemeColors.of(context);
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings_remote_rounded,
                      size: 72,
                      color: tc.greenDark,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Не передана конфигурация',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Не заданы обязательные параметры:\n\n$missing\n\n'
                      'Запустите приложение с параметром:\n\n'
                      'flutter run --dart-define-from-file=env.json\n\n'
                      'Файл env.json должен лежать в корне проекта рядом с pubspec.yaml.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: tc.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Остальные ключи (Gemini, OpenRouter, сканер, Sentry) — '
                      'необязательные: без них приложение запустится, но часть '
                      'AI-функций будет недоступна.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: tc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
