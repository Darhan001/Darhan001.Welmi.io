"""Restore API keys from env.json into lib/main.dart as defaultValue.

Reads env.json and rewrites the String.fromEnvironment(...) constants in
lib/main.dart to include a defaultValue with the real key value, so the app
works without --dart-define-from-file. Values are never printed.
"""
import json
import re


def esc(s: str) -> str:
    out = []
    for ch in s:
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "$":
            out.append("\\$")
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ch == "\t":
            out.append("\\t")
        elif ord(ch) < 32:
            out.append("\\u%04x" % ord(ch))
        else:
            out.append(ch)
    return "".join(out)


def main() -> None:
    data = json.load(open("env.json", encoding="utf-8"))

    path = "lib/main.dart"
    src = open(path, "rb").read().decode("utf-8")

    keys = [
        ("SUPABASE_URL", "supabaseUrl"),
        ("SUPABASE_ANON_KEY", "supabaseAnonKey"),
        ("GEMINI_NUTRITION_API_KEY", "geminiNutritionApiKey"),
        ("OPENROUTER_API_KEY", "openRouterApiKey"),
        ("SCANNER_API_KEY", "scannerApiKey"),
        ("SENTRY_DSN", "sentryDsn"),
    ]

    for env_key, var_name in keys:
        val = data.get(env_key, "")
        replacement = (
            "const String %s = String.fromEnvironment('%s', "
            "defaultValue: '%s');" % (var_name, env_key, esc(val))
        )
        # multiline form first (e.g. geminiNutritionApiKey)
        src = re.sub(
            r"const String %s =\r?\n\s*String\.fromEnvironment\('%s'\);"
            % (var_name, env_key),
            replacement,
            src,
        )
        src = re.sub(
            r"const String %s = String\.fromEnvironment\('%s'\);"
            % (var_name, env_key),
            replacement,
            src,
        )

    open(path, "wb").write(src.encode("utf-8"))
    print("done")


if __name__ == "__main__":
    main()
