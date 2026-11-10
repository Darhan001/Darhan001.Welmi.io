import 'dart:async';
import 'package:http/http.dart' as http;

/// HTTP-клиент, который обрывает запрос, если сервер не ответил вовремя.
///
/// Передаётся в `Supabase.initialize`: у клиента Supabase нет своего
/// тайм-аута, и при «подвисшей» сети `await` запроса к базе не завершался,
/// а экран оставался в состоянии загрузки. Теперь вызывающий код получает
/// [TimeoutException] и показывает ошибку с кнопкой «Повторить».
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 30),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;

  /// Время до получения заголовков ответа (включая отправку тела запроса).
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner
        .send(request)
        .timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'HTTP ${request.method} ${request.url.host} не ответил',
            timeout,
          ),
        );
  }

  @override
  void close() => _inner.close();
}
