#!/usr/bin/env bash
# Запуск/сборка Welmi с секретами из env.json.
# Использование:
#   bash scripts/run.sh            # debug-запуск на устройстве/эмуляторе
#   bash scripts/run.sh release    # release APK
#   bash scripts/run.sh devices    # список подключённых телефонов
#   bash scripts/run.sh analyze    # только статический анализ
set -e
cd "$(dirname "$0")/.."

if [ ! -f env.json ]; then
  echo "❌ Нет файла env.json в корне проекта — там должны лежать ключи."
  echo "   Создай его по образцу из README.md и повтори."
  exit 1
fi

case "${1:-run}" in
  run)
    echo "🚀 flutter run --dart-define-from-file=env.json"
    flutter run --dart-define-from-file=env.json
    ;;
  release)
    echo "📦 flutter build apk --release --dart-define-from-file=env.json"
    flutter build apk --release --dart-define-from-file=env.json
    ;;
  devices)
    flutter devices
    ;;
  analyze)
    flutter analyze
    ;;
  *)
    echo "Неизвестная команда: $1 (доступно: run, release, devices, analyze)"
    exit 1
    ;;
esac
