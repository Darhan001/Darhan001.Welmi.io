import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/core/services/user_data_service.dart';

void main() {
  final service = UserDataService();

  setUp(() {
    AuthService().reset();
    service.reset();
  });

  test('без загрузки данные не считаются свежими', () {
    expect(service.isFresh(), isFalse);
  });

  test('без входа загрузка не падает и не помечает данные свежими', () async {
    await service.ensureLoaded();
    expect(service.isFresh(), isFalse);
    expect(service.profile, isNull);
    expect(service.error, isNotNull);
  });

  test('параллельные вызовы loadAll делят одну загрузку', () async {
    final first = service.loadAll();
    final second = service.loadAll();
    expect(identical(first, second), isTrue);
    await first;

    // После завершения следующий вызов начинает новую загрузку.
    final third = service.loadAll();
    expect(identical(first, third), isFalse);
    await third;
  });
}
