# База продуктов и дневник питания (Open Food Facts)

Первый этап интеграции: поиск продукта, штрихкод, порция в граммах,
пересчёт КБЖУ, добавление/изменение/удаление записи в существующем дневнике.

## Что добавлено

| Файл | Назначение |
| --- | --- |
| `lib/features/food_database/domain/models/food_product.dart` | Продукт (на 100 г), порция, черновик записи, пересчёт по граммам |
| `lib/features/food_database/data/open_food_facts_service.dart` | Поиск и штрихкод через Open Food Facts, разбор неполных данных, лимиты и кэш |
| `lib/features/food_database/presentation/pages/product_search_page.dart` | Экран поиска (по названию или цифрам штрихкода) |
| `lib/features/food_database/presentation/pages/barcode_scanner_page.dart` | Камера: EAN-8/13, UPC-A/E, ITF-14, Code 128 |
| `lib/features/food_database/presentation/widgets/food_portion_sheet.dart` | Ввод массы порции и живой пересчёт КБЖУ |
| `lib/features/food_database/presentation/widgets/meal_item_editor_sheet.dart` | Редактирование записи дневника |
| `lib/core/services/supabase_service.dart` | `updateMealItem`, `deleteFoodEntry`, `updateFoodEntryTotalCalories` |
| `lib/features/diary/presentation/pages/diary_page.dart` | Кнопка «База», действия по тапу на запись, обновление итогов |
| `SUPABASE_FOOD_DIARY_MIGRATION.sql` | UPDATE-политика для `meal_items` (без новых таблиц) |

## API Open Food Facts

Документация: <https://openfoodfacts.github.io/openfoodfacts-server/api/>

- Поиск: `https://search.openfoodfacts.org/search?q=...&page_size=20&fields=...`
  (полнотекстового поиска в API v2/v3 нет, используется Search-a-licious).
- Продукт по штрихкоду: `https://world.openfoodfacts.org/api/v3/product/{barcode}.json`.
- `User-Agent`: `Welmi/1.0.1 (support@welmi.app)`.
- Лимиты сервиса: **10 поисковых запросов в минуту** и **15 запросов продукта
  в минуту** на IP. Поэтому поиск выполняется только по кнопке/Enter (не
  «по мере ввода»), между запросами действует пауза, а найденные по штрихкоду
  продукты кэшируются в памяти.
- Калорийность берётся из `energy-kcal_100g`; если её нет — из килоджоулей
  (`/ 4.184`); если нет и их, но известны все БЖУ — оценивается по формуле
  4×Б + 9×Ж + 4×У (в интерфейсе помечается «≈»).
- Отсутствующие нутриенты остаются `null` и показываются как «—», а не как 0.

## Хранение

Новых таблиц нет. Запись использует существующую архитектуру:

- `food_entries` — приём пищи (дата, тип, `total_calories`);
- `meal_items` — продукт внутри приёма (`name`, `calories`, БЖУ, `amount_grams`,
  `info`).

Доступ уже ограничен RLS: пользователь видит и меняет только свои записи
(`food_entries.user_id = auth.uid()`, `meal_items` — через родительский
`food_entries`).

## Ручные шаги

1. **Supabase → SQL Editor:** выполнить `SUPABASE_FOOD_DIARY_MIGRATION.sql`.
   Без UPDATE-политики на `meal_items` редактирование записи вернёт ошибку RLS.
   Файл идемпотентен, таблиц не создаёт.
2. **Open Food Facts:** заполнить короткую форму использования API
   (ссылка «Fill out the API usage form» в разделе **Before You Start**
   официальной документации). Это просьба сервиса, не обязательное условие
   работы.
3. Собрать приложение с ключами Supabase, как обычно:
   `bash scripts/run.sh release` (или `flutter build apk --release
   --dart-define-from-file=env.json`).

## Как проверить

1. Дневник → «Добавить» у приёма пищи → **База**.
2. Ввести «молоко» и нажать Enter/поиск → выбрать продукт → указать 150 г →
   «Добавить в дневник». В строке появится «150 г», калории пересчитаны.
3. Тап по записи → «Изменить» → поменять граммы на 200 → «Сохранить»:
   калории и БЖУ пересчитаются, итоги дня обновятся.
4. Тап по записи → «Удалить» → подтвердить: строка и итоги дня обновятся.
5. Кнопка со сканером в поиске → отсканировать штрихкод (например,
   `3017620422003`) → откроется карточка порции.
6. Ввести в поиск `0000000000000` → «Продукт не найден».

Автотесты: `flutter test test/food_product_test.dart`.

## Ограничения

- Данные Open Food Facts добровольные: продукт может отсутствовать, а БЖУ —
  быть неполным. Продукт без калорийности нельзя добавить (БД требует
  `meal_items.calories`), интерфейс объясняет почему.
- Нет офлайн-кэша поиска: нужен интернет. Кэш штрихкодов живёт до
  перезапуска приложения.
- Для запуска дневника по-прежнему нужен рабочий проект Supabase и вход
  пользователя.
