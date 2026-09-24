#!/usr/bin/env python3
"""Проверка API-ключей из env.json. Секреты НЕ печатаются (только маска).

Использование:
  python scripts/check_keys.py                    # проверить все ключи из env.json
  python scripts/check_keys.py --set K=V [K2=V2]  # добавить/обновить ключи и сразу проверить
  python scripts/check_keys.py --show             # показать ключи замаскированно

Коды выхода: 0 — все критичные ключи в порядке, 1 — есть проблемы.
"""
import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV_PATH = os.path.join(ROOT, "env.json")

TIMEOUT = 25

# Какие ключи обязательны для запуска приложения
CRITICAL = ["SUPABASE_URL", "SUPABASE_ANON_KEY"]


def load_env() -> dict:
    if not os.path.exists(ENV_PATH):
        return {}
    with open(ENV_PATH, encoding="utf-8") as f:
        return json.load(f)


def save_env(data: dict) -> None:
    with open(ENV_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def mask(value: str) -> str:
    if not value:
        return "(пусто)"
    if len(value) <= 12:
        return value[:4] + "…"
    return value[:8] + "…" + value[-4:]


def http_json(url: str, method="GET", headers=None, body=None):
    req = urllib.request.Request(url, method=method, headers=headers or {})
    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, data=data, timeout=TIMEOUT) as resp:
            return resp.status, json.loads(resp.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode("utf-8", "replace"))
        except Exception:
            return e.code, {}
    except Exception as e:
        return -1, {"_error": str(e)}


# ── Проверки по сервисам ──────────────────────────────────────────

def check_supabase(env: dict, key: str):
    if key == "SUPABASE_URL":
        url = env.get("SUPABASE_URL", "").rstrip("/")
        if not url:
            return "MISSING", "нет SUPABASE_URL"
        # /auth/v1/health требует apikey — используем anon-ключ, если есть
        headers = {}
        if env.get("SUPABASE_ANON_KEY"):
            headers["apikey"] = env["SUPABASE_ANON_KEY"]
        code, body = http_json(f"{url}/auth/v1/health", headers=headers)
        if code == 200:
            return "OK", f"проект доступен ({body.get('name', 'GoTrue')})"
        return "FAIL", f"auth/v1/health → HTTP {code}"
    if key == "SUPABASE_ANON_KEY":
        url = env.get("SUPABASE_URL", "").rstrip("/")
        anon = env.get("SUPABASE_ANON_KEY", "")
        if not url or not anon:
            return "MISSING", "нужны SUPABASE_URL и SUPABASE_ANON_KEY"
        headers = {"apikey": anon, "Authorization": f"Bearer {anon}"}
        # Проверяем на реальном запросе приложения: чтение строки из profiles
        # (RLS вернёт пустой массив — это тоже успех: ключ принят).
        code, body = http_json(f"{url}/rest/v1/profiles?select=id&limit=1", headers=headers)
        if code == 200:
            rows = body if isinstance(body, list) else []
            return "OK", f"anon-ключ принят (RLS: {len(rows)} строк)"
        if code == 404:
            return "WARN", "таблица profiles не найдена (примени schema SQL), но ключ принят"
        if code == 401:
            return "FAIL", "401 — ключ неверный/перевыпущен"
        return "FAIL", f"HTTP {code}"
    return "SKIP", ""


def check_openrouter(env: dict, key: str):
    api = env.get("OPENROUTER_API_KEY", "")
    if not api:
        return "MISSING", "нет ключа"
    code, body = http_json(
        "https://openrouter.ai/api/v1/key",
        headers={"Authorization": f"Bearer {api}"},
    )
    if code == 200:
        data = body.get("data", {})
        usage = data.get("usage", 0)
        limit = data.get("limit")
        usage_s = f"израсходовано ${usage:.4f}"
        if limit is not None:
            usage_s += f" из ${limit:.2f}"
        return "OK", f"ключ активен ({usage_s}, free-tier={data.get('is_free_tier')})"
    if code == 401:
        return "FAIL", "401 — ключ неверный/отозван"
    return "FAIL", f"HTTP {code}"


def check_gemini(env: dict, key: str):
    api = env.get(key, "")
    if not api:
        return "MISSING", "нет ключа"
    if not api.startswith("AIza"):
        return ("WARN",
                "не похож на ключ Google AI Studio (ожидается 'AIza…'); "
                "пропускаю — сканер/AI работают через OpenRouter")
    url = ("https://generativelanguage.googleapis.com/v1beta/models"
           "?pageSize=1&key=" + urllib.parse.quote(api))
    code, _ = http_json(url)
    if code == 200:
        return "OK", "ключ Google AI Studio работает"
    if code in (400, 403):
        return "FAIL", f"HTTP {code} — ключ неверный или API не включён"
    return "FAIL", f"HTTP {code}"


def check_sentry(env: dict, key: str):
    dsn = env.get("SENTRY_DSN", "")
    if not dsn:
        return "MISSING", "нет DSN (не критично)"
    m = re.match(r"^https://([^@]+)@([^/]+)/(\d+)$", dsn)
    if not m:
        return "WARN", "формат DSN не распознан"
    store = (f"https://{m.group(2)}/api/{m.group(3)}/store/?sentry_version=7"
             f"&sentry_key={m.group(1)}")
    code, _ = http_json(store, method="POST", body={"message": "welmi-key-check"})
    if code in (200, 201):
        return "OK", "событие отправлено в Sentry"
    if code == 403:
        return "FAIL", "403 — DSN неверный или квота исчерпана"
    return "FAIL", f"HTTP {code}"


def check_scanner(env: dict, key: str):
    api = env.get(key, "")
    if not api:
        return "MISSING", "нет ключа (сканер еды работает через OpenRouter)"
    if api.startswith(("sk-or-", "AIza")):
        return "OK", "ключ OpenRouter/Gemini — используется сканером через AI"
    return ("WARN",
            "ключ стороннего провайдера — прямая проверка не реализована; "
            "сканер пробует его через OpenRouter/Gemini REST")


CHECKS = {
    "SUPABASE_URL": check_supabase,
    "SUPABASE_ANON_KEY": check_supabase,
    "OPENROUTER_API_KEY": check_openrouter,
    "GEMINI_NUTRITION_API_KEY": check_gemini,
    "SCANNER_API_KEY": check_scanner,
    "SENTRY_DSN": check_sentry,
}

LABELS = {
    "SUPABASE_URL": "Supabase URL",
    "SUPABASE_ANON_KEY": "Supabase anon key",
    "OPENROUTER_API_KEY": "OpenRouter (AI-чат/планы)",
    "GEMINI_NUTRITION_API_KEY": "Gemini (нутрициолог)",
    "SCANNER_API_KEY": "Сканер еды",
    "SENTRY_DSN": "Sentry (краш-репорты)",
}


def parse_set_args(items):
    parsed = []
    for item in items:
        if "=" not in item:
            die(f"--set: ожидалось КЛЮЧ=ЗНАЧЕНИЕ, получено: {item!r}")
        k, v = item.split("=", 1)
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", k):
            die(f"--set: некорректное имя ключа: {k!r}")
        parsed.append((k, v))
    return parsed


def die(msg: str):
    print(f"❌ {msg}")
    sys.exit(1)


def main() -> None:
    ap = argparse.ArgumentParser(description="Проверка ключей env.json")
    ap.add_argument("--set", nargs="+", metavar="KEY=VALUE",
                    help="добавить/обновить ключи перед проверкой")
    ap.add_argument("--show", action="store_true",
                    help="показать ключи замаскированно без проверки")
    args = ap.parse_args()

    env = load_env()

    if args.set:
        for k, v in parse_set_args(args.set):
            env[k] = v
        save_env(env)
        print(f"✅ Обновлено {len(args.set)} ключ(ей) в env.json\n")

    if not env:
        die(f"{ENV_PATH} пуст или не существует — создай его по README.md")

    if args.show:
        for k in sorted(env):
            print(f"  {k:28} = {mask(env[k])}")
        return

    print("Проверка ключей из env.json (секреты не печатаются):\n")
    problems = 0
    for key, fn in CHECKS.items():
        label = LABELS.get(key, key)
        value = env.get(key, "")
        if key not in env:
            status, msg = "MISSING", "нет в env.json"
        else:
            status, msg = fn(env, key)
        icon = {"OK": "✅", "WARN": "⚠️ ", "FAIL": "❌", "MISSING": "➖"}[status]
        critical = key in CRITICAL and status in ("FAIL", "MISSING")
        if critical:
            problems += 1
        print(f"  {icon} {label:26} [{status:7}] {msg}")

    # Ключи, которых нет в известном списке — просто показать наличие
    extra = [k for k in env if k not in CHECKS]
    if extra:
        print()
        for k in extra:
            print(f"  ❓ {k:26} [UNKNOWN] есть в env.json, проверка не реализована")

    print()
    if problems:
        print(f"❌ Критичные ключи с проблемами: {problems} — приложение не запустится.")
        sys.exit(1)
    print("✅ Критичные ключи (Supabase) в порядке — приложение запустится.")


if __name__ == "__main__":
    main()
