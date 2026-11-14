import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lumina/core/services/ai/ai_provider_client.dart';

http.Response _ok(String text) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'choices': [
        {
          'message': {'content': text},
        },
      ],
    }),
  ),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

String _model(http.Request request) =>
    (jsonDecode(request.body) as Map)['model'] as String;

void main() {
  test('isFreeModel: суффикс :free и маршрутизатор', () {
    expect(AiProviderClient.isFreeModel('vendor/model:free'), isTrue);
    expect(AiProviderClient.isFreeModel(AiProviderClient.freeRouter), isTrue);
    expect(AiProviderClient.isFreeModel('google/gemini-2.5-flash'), isFalse);
  });

  test('список текстовых моделей заканчивается бесплатным маршрутизатором', () {
    expect(
      AiProviderClient.openRouterTextModels.last,
      AiProviderClient.freeRouter,
    );
  });

  test(
    'нет кредитов (402): платные пропускаются, отвечает бесплатная',
    () async {
      final asked = <String>[];
      final client = AiProviderClient(
        httpClient: MockClient((request) async {
          final model = _model(request);
          asked.add(model);
          return AiProviderClient.isFreeModel(model)
              ? _ok('Привет')
              : http.Response('{"error":{"message":"no credits"}}', 402);
        }),
      )..openRouterKey = 'sk-or-test';

      final text = await client.complete(systemPrompt: 's', userPrompt: 'u');

      expect(text, 'Привет');
      // Первая платная вернула 402 — вторую платную не спрашиваем.
      expect(
        asked.where((m) => !AiProviderClient.isFreeModel(m)),
        hasLength(1),
      );
      expect(AiProviderClient.isFreeModel(asked.last), isTrue);
    },
  );

  test('снятая с публикации бесплатная модель (404) не ломает чат', () async {
    final client = AiProviderClient(
      httpClient: MockClient((request) async {
        final model = _model(request);
        if (model == AiProviderClient.freeRouter) return _ok('Ответ');
        return http.Response(
          '{}',
          AiProviderClient.isFreeModel(model) ? 404 : 402,
        );
      }),
    )..openRouterKey = 'sk-or-test';

    expect(await client.complete(systemPrompt: 's', userPrompt: 'u'), 'Ответ');
  });

  test('все провайдеры отказали — null и понятная причина', () async {
    final client = AiProviderClient(
      httpClient: MockClient((_) async => http.Response('{}', 429)),
    )..openRouterKey = 'sk-or-test';

    expect(await client.complete(systemPrompt: 's', userPrompt: 'u'), isNull);
    expect(client.lastIssue, isNotNull);
  });

  test('ключ Gemini используется как запасной путь без OpenRouter', () async {
    final hosts = <String>[];
    final client = AiProviderClient(
      httpClient: MockClient((request) async {
        hosts.add(request.url.host);
        expect(request.headers['x-goog-api-key'], 'gemini-test-key');
        expect(request.url.query, isEmpty); // ключ не попадает в адрес
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Готово'},
                    ],
                  },
                },
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    )..geminiKey = 'gemini-test-key';

    expect(await client.complete(systemPrompt: 's', userPrompt: 'u'), 'Готово');
    expect(hosts, ['generativelanguage.googleapis.com']);
  });

  test('без ключей запросы не отправляются', () async {
    var calls = 0;
    final client = AiProviderClient(
      httpClient: MockClient((_) async {
        calls++;
        return http.Response('{}', 500);
      }),
    );
    expect(await client.complete(systemPrompt: 's', userPrompt: 'u'), isNull);
    expect(calls, 0);
  });
}
