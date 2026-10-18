# Lumina / Welmi — рабочие правила для Claude

Flutter-приложение (Dart SDK ^3.12.2) для питания, воды, активности, веса и тренировок.
Бэкенд — Supabase (БД, Auth, Edge Functions). Общение с пользователем — по-русски.

## Команды

- Запуск: `flutter run --dart-define-from-file=env.json` (`env.json` лежит в корне и не коммитится).
- Анализ: `flutter analyze` — цель: «No issues found!»; новых `info` не добавлять.
  Хук `rtk` сжимает вывод Bash и **скрывает строки `warning`**: перед отчётом
  сохраняй вывод в файл (`flutter analyze > <scratchpad>/analyze.txt 2>&1`) и читай его
  инструментами Read/Grep, а не `| grep` в shell.
- Тесты: `flutter test` (в том числе `test/voice_services_test.dart` и `test/exercise_muscles_test.dart`).
- Локализация: после правок `lib/l10n/app_*.arb` выполнить `flutter gen-l10n` (или `flutter pub get`).
  Ключи добавляются одновременно в `app_en.arb`, `app_ru.arb`, `app_ky.arb`.
- Сборка Android: `flutter build apk --debug --dart-define-from-file=env.json`.

## Структура

- `lib/core/` — конфиг (`config/app_config.dart`), сервисы (`services/`), общие виджеты и тема.
- `lib/features/<feature>/{data,domain,presentation}` — фичи. Новый код следует этой раскладке.
- `lib/services/` — локальные уведомления (`notification_service.dart`).
- `supabase/` — миграции (`migrations/`), Edge Functions (`functions/`).

## Правила кода

- Ключи API читаются только через `String.fromEnvironment` (см. `app_config.dart`). Не коммитить `env.json`, не печатать значения ключей в логи.
- Ошибки сервисов — типизированные исключения (`AiUnavailableException`, `VoiceTranscriptionException`, `VoiceRecordException`), а не строки или `null`. Сообщения пользователю строятся в UI из локализации.
- Голос: запись — `VoiceRecorderService`, озвучивание — `SpeechOutputService`. Не дублировать `AudioRecorder` в виджетах.
- Снекбары — только через `AppSnackbar`.
- Числа от пользователя — через `parseDecimalInput` (`core/utils/number_input.dart`): на ru/ky-клавиатуре разделитель — запятая.
- Вес и расстояние хранятся в метрике; показ и ввод — через `UnitsService` и расширение `UnitsFormat` (`loc.formatWeight`, `loc.weightUnitLabel`). Не писать `'… кг'` вручную.
- Выход из аккаунта — только `confirmAndSignOut` (`core/widgets/logout_flow.dart`).
- Шапка экрана — `AppAppBar`/`AppBarActionButton` (зона нажатия 48×48, `tooltip` обязателен для иконок без текста).
- Анимации учитывают `MediaQuery.disableAnimationsOf(context)`; для появления элементов есть `FadeSlideIn`.
- Не выводить выдуманные данные (вес «по умолчанию», фейковые уведомления, статус Premium без entitlement): при отсутствии данных — пустое состояние.
- Не добавлять строки в UI на одном языке: все новые строки — в трёх ARB-файлах.
- Premium: доступ определяется только серверным entitlement (`subscription_entitlements`). Локальные флаги и факт нажатия кнопки доступ не выдают.
- Миграции Supabase не применять к продакшену без проверки пользователем.

## Что не трогать без явного разрешения

- Аккаунты магазинов, платёжные настройки, API-ключи, секреты Edge Functions.
- Данные пользователя (`profiles`, записи дневника, веса, воды) — не удалять и не переписывать.
- Файлы в `assets/3d_models/` и их лицензии (`LICENSE.txt`).

## Git

- Перед крупными изменениями проверить `git status`: в рабочем дереве могут быть незакоммиченные правки, которые не мои.
- Коммиты и пуш — только по явной просьбе.
