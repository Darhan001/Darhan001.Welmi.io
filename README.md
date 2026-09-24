# Lumina (Welmi)

Flutter-приложение для трекинга питания, воды, активности и веса.

## 🔑 Запуск с секретами (обязательно)

Все ключи/секреты читаются из переменных окружения через `--dart-define-from-file`.
Сами ключи **не хранятся в коде** и не коммитятся (`env.json` и `.env` в `.gitignore`).

**Обязательные** (без них приложение не запустится — покажет экран с инструкцией):

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

**Необязательные** (приложение запустится и без них, часть функций просто отключится):

- `GEMINI_NUTRITION_API_KEY`, `OPENROUTER_API_KEY`, `SCANNER_API_KEY` — AI-функции
  переключатся на локальные формулы-fallback;
- `SENTRY_DSN` — без него краш-репорты не отправляются.

1. Скопируйте/создайте файл `env.json` в корне проекта (рядом с `pubspec.yaml`):

```json
{
  "SUPABASE_URL": "https://ваш-проект.supabase.co",
  "SUPABASE_ANON_KEY": "ваш-anon-ключ",
  "GEMINI_NUTRITION_API_KEY": "ваш-gemini-ключ",
  "OPENROUTER_API_KEY": "sk-or-v1-...",
  "SCANNER_API_KEY": "ключ-сканера-еды",
  "SENTRY_DSN": "https://...ingest.us.sentry.io/..."
}
```

2. Запуск / сборка:

```bash
# Run (debug)
flutter run --dart-define-from-file=env.json

# Release APK
flutter build apk --dart-define-from-file=env.json

# iOS
flutter build ipa --dart-define-from-file=env.json
```

3. Если запустить **без** обязательной конфигурации Supabase — приложение покажет
   экран с инструкцией вместо тихого падения. Если не хватает только необязательных
   ключей (AI/Sentry) — приложение запустится и будет работать.

### Запуск на телефоне для тестирования

```bash
# 1. Подключи телефон по USB (включи "Отладку по USB" в настройках разработчика)
#    или запусти эмулятор. Список устройств:
flutter devices

# 2. Запусти на телефоне (ключи подставятся из env.json автоматически):
flutter run --dart-define-from-file=env.json

# 3. Выбери устройство, если их несколько — Flutter спросит номер из списка.
#    Чтобы указать сразу: flutter run -d <id устройства> --dart-define-from-file=env.json

# 4. Release-APK для установки на телефон:
flutter build apk --release --dart-define-from-file=env.json
#    Готовый файл: build/app/outputs/flutter-apk/app-release.apk
```

Или проще — готовый скрипт (проверяет env.json и запускает с ключами):

```bash
bash scripts/run.sh          # запуск на телефоне/эмуляторе
bash scripts/run.sh devices  # список устройств
bash scripts/run.sh release  # сборка APK
```

В Android Studio/IntelliJ конфигурация запуска **`main.dart`** (`.idea/runConfigurations/main_dart.xml`)
уже содержит флаг `--dart-define-from-file=env.json`, так что запуск кнопкой ▶ подставляет
ключи из `env.json` автоматически — отдельно ничего настраивать не нужно.

> 💡 В DevicePreview (в debug-сборке) можно переключать разные модели телефонов
> (iPhone, Pixel и т.д.) без реальных устройств — удобно для проверки интерфейса.

### Где лежат ключи и как их посмотреть

- Все секреты — в одном файле **`env.json`** в корне проекта (он в `.gitignore`).
- Посмотреть: `cat env.json` (или открыть файл в редакторе).
- В коде ключей нет — `lib/core/config/app_config.dart` читает их через `String.fromEnvironment(...)`.
  Там же описано, какие переменные обязательные, а какие необязательные.
- В git попадает только README и структура, сами значения — нет.
- Есть скрипты: `scripts/hide_keys_from_code.py` (убрать ключи из кода) и
  `scripts/restore_keys_to_code.py` (вернуть их из `env.json` в код).

> ⚠️ **Безопасность:** ключи, которые раньше были в истории git, считаются скомпрометированными —
> их нужно отозвать и перевыпустить (Supabase, Google AI Studio, OpenRouter, Sentry), затем обновить `env.json`.

## 📦 Структура

- `lib/core/` — сервисы, модели, конфигурация, тема, общие виджеты
- `lib/core/config/app_config.dart` — чтение ключей и обязательные/необязательные параметры
- `lib/features/` — фичи по вертикальным срезам (presentation)
- `env.json` — секреты (gitignored)

## 📲 Push-уведомления (FCM + Supabase Edge Functions)

Код уже готов: приложение регистрирует FCM-токен в таблице `device_tokens`, получает push
и открывает нужный экран по тапу. Осталось выполнить ручные шаги — они описаны ниже
в порядке выполнения.

### Шаг 1. Firebase-проект и google-services.json

1. Зайди на [console.firebase.google.com](https://console.firebase.google.com) → **Add project** → назови, например, `welmi`.
2. В проекте: **Project settings** → твоё приложение (**Add app**) → **Android**.
3. Пакет Android: `com.example.lumina` (см. `android/app/build.gradle.kts`).
4. Скачай сгенерированный **`google-services.json`** и положи в `android/app/google-services.json`.
   > ⚠️ Без этого файла сборка не запустится (`flutter run`) — это ожидаемо, файл закрывает заглушку в Gradle.

### Шаг 2. Проверка приёма push (FCM Console)

1. Запусти приложение: `flutter run --dart-define-from-file=env.json` (или собери APK).
2. В логах должно появиться `📲 FCM token saved for user ...` — значит токен записан в Supabase.
3. В Firebase Console → **Cloud Messaging** → **Send test message** → вставь токен (его можно вывести в лог, добавив `print` в `push_notification_service.dart`) и отправь.
4. Уведомление должно прийти на телефон — и в открытом приложении, и в фоне.

### Шаг 3. SQL для таблицы device_tokens

В Supabase → **SQL Editor** выполни блок `11. PUSH-УВЕДОМЛЕНИЯ` из `supabase_schema.sql`
(создаёт таблицу `device_tokens` + RLS). Блок идемпотентный — можно запускать повторно.

### Шаг 4. Деплой Edge Functions (отправка push с сервера)

Установи [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)
и выполни из корня проекта:

```bash
# 1. Инициализация проекта (создаст supabase/config.toml, если ещё нет)
npx supabase init

# 2. Привязка к твоему проекту Supabase
npx supabase link --project-ref oqdxbfrufklcztsiqwhs

# 3. Service account для FCM:
#    Firebase Console → Project settings → Service accounts →
#    Generate new private key (роль: Firebase Admin)
#    → скачается firebase-adminsdk.json
npx supabase secrets set FCM_SERVICE_ACCOUNT="$(cat firebase-adminsdk.json | base64)"

# 4. Деплой функции отправки push
npx supabase functions deploy send-push

# 5. Деплой функции напоминаний + расписание
#    Добавь в supabase/config.toml:
#    [functions.send-reminders]
#    verify_jwt = false
#    schedule = "*/30 * * * *"
#    затем:
npx supabase functions deploy send-reminders
```

### Шаг 5. Тест отправки

> Безопасность: функция отклоняет запросы без реальной сессии пользователя
> (anon-ключ → 403). Для теста нужен access-токен вошедшего пользователя.
> Временно добавь в `push_notification_service.dart` после `_saveToken`:
> `debugPrint(Supabase.instance.client.auth.currentSession?.accessToken)` —
> скопируй токен из лога, затем удали строку.

```bash
# Отправить push пользователю (UUID — из Authentication → Users)
curl -X POST https://oqdxbfrufklcztsiqwhs.supabase.co/functions/v1/send-push \
  -H "Authorization: Bearer ACCESS_ТОКЕН_ПОЛЬЗОВАТЕЛЯ" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"UUID_ПОЛЬЗОВАТЕЛЯ","title":"💧 Время пить воду!","body":"Проверка push","route":"water"}'
```

### Как это работает

- **Приём:** приложение получает FCM-токен, сохраняет в `device_tokens` (при входе/онбординге), обновляет при перевыпуске, удаляет при выходе.
- **Отправка:** Edge Function `send-push` находит токены пользователя и шлёт через FCM HTTP v1. Функция `send-reminders` по cron шлёт напоминания о воде (10–20:00, каждый 2-й час) и еде (8:30 / 13:00 / 19:00, Москва) — уважает `notification_prefs` из профиля.
- **Тап:** в payload поле `route` (`water`, `diary`, `progress`, `weight`) — приложение откроет нужный экран.

## 🧰 Полезные команды

```bash
flutter analyze          # статический анализ
flutter test             # тесты
```
