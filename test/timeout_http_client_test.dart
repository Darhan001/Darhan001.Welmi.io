import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lumina/core/network/timeout_http_client.dart';

void main() {
  final url = Uri.parse('https://example.supabase.co/rest/v1/profiles');

  test('быстрый ответ проходит без изменений', () async {
    final client = TimeoutHttpClient(
      inner: MockClient((_) async => http.Response('[]', 200)),
      timeout: const Duration(seconds: 1),
    );
    final response = await client.get(url);
    expect(response.statusCode, 200);
    expect(response.body, '[]');
  });

  test('зависший запрос завершается TimeoutException', () async {
    final never = Completer<http.Response>();
    final client = TimeoutHttpClient(
      inner: MockClient((_) => never.future),
      timeout: const Duration(milliseconds: 50),
    );
    await expectLater(client.get(url), throwsA(isA<TimeoutException>()));
  });

  test('ошибка сервера не превращается в тайм-аут', () async {
    final client = TimeoutHttpClient(
      inner: MockClient((_) async => http.Response('fail', 503)),
      timeout: const Duration(seconds: 1),
    );
    expect((await client.get(url)).statusCode, 503);
  });
}
