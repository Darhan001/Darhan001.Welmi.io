import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/config/app_config.dart' as cfg;

void main() {
  test('isSupabaseConfigured согласован со списком обязательных ключей', () {
    expect(cfg.isSupabaseConfigured, cfg.missingRequiredEnvKeys.isEmpty);
  });

  test('необязательные ключи не попадают в обязательные', () {
    expect(cfg.missingRequiredEnvKeys, isNot(contains('SENTRY_DSN')));
    expect(cfg.missingRequiredEnvKeys, isNot(contains('OPENROUTER_API_KEY')));
    for (final key in cfg.kOptionalEnvKeys) {
      expect(cfg.missingRequiredEnvKeys, isNot(contains(key)));
    }
  });

  test('диагностика не раскрывает значения секретов', () {
    final report = cfg.configDiagnostics();
    expect(report, contains('Supabase'));
    if (cfg.supabaseAnonKey.isNotEmpty) {
      expect(report.contains(cfg.supabaseAnonKey), isFalse);
    }
    if (cfg.openRouterApiKey.isNotEmpty) {
      expect(report.contains(cfg.openRouterApiKey), isFalse);
    }
  });
}
