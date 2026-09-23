"""Убрать ключи из исходного кода (обратная операция к restore_keys_to_code.py).

Переводит константы в lib/main.dart в вид:

    const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

то есть без `defaultValue: '<настоящий ключ>'`. После этого секреты живут
только в env.json (он в .gitignore) и подставляются при запуске/сборке:

    flutter run   --dart-define-from-file=env.json
    flutter build apk --dart-define-from-file=env.json

Скрипт ничего не печатает (значения ключей в лог не попадают) и безопасен
для повторного запуска.
"""
import re

VARS = [
    "supabaseUrl",
    "supabaseAnonKey",
    "geminiNutritionApiKey",
    "openRouterApiKey",
    "scannerApiKey",
    "sentryDsn",
]

ENV_KEYS = [
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "GEMINI_NUTRITION_API_KEY",
    "OPENROUTER_API_KEY",
    "SCANNER_API_KEY",
    "SENTRY_DSN",
]


def main() -> None:
    path = "lib/main.dart"
    src = open(path, "rb").read().decode("utf-8")
    removed = 0

    for var_name, env_key in zip(VARS, ENV_KEYS):
        # однострочная форма (возможно многострочная из-за переносов)
        pattern = re.compile(
            r"const String %s =\s*String\.fromEnvironment\('%s'\s*,\s*"
            r"defaultValue:\s*'(?:\\.|[^'\\])*'\);" % (var_name, env_key),
            re.DOTALL,
        )
        src, n = pattern.subn(
            "const String %s =\n    String.fromEnvironment('%s');" % (var_name, env_key),
            src,
        )
        removed += n

    open(path, "wb").write(src.encode("utf-8"))
    print("done: %d constants cleaned" % removed)


if __name__ == "__main__":
    main()
