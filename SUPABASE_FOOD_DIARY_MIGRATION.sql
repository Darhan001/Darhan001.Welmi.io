-- ============================================================
-- Welmi — food diary: policies for editing meal items
-- ============================================================
-- Зачем: добавление еды уже работало (SELECT/INSERT/DELETE), но в
-- meal_items не было UPDATE-политики. Без неё изменение порции/КБЖУ
-- падает с ошибкой RLS, даже если строка принадлежит пользователю.
--
-- Запусти этот файл в Supabase → SQL Editor. Он идемпотентен:
-- ничего не удаляет, таблиц не создаёт, можно запускать повторно.
--
-- Новых таблиц НЕ нужно: запись дневника по-прежнему хранится в
-- существующих food_entries (приём пищи) + meal_items (продукт).
-- ============================================================

-- Старые проекты могли создавать meal_items без этих колонок
-- (в актуальной supabase_schema.sql они уже есть).
alter table public.meal_items add column if not exists amount_grams real;
alter table public.meal_items add column if not exists info text;

-- RLS должна быть включена (в базовой схеме уже включена).
alter table public.food_entries enable row level security;
alter table public.meal_items enable row level security;

-- Права на таблицы для авторизованных пользователей. Доступ к строкам
-- всё равно ограничен RLS-политиками ниже.
grant select, insert, update, delete on public.food_entries to authenticated;
grant select, insert, update, delete on public.meal_items to authenticated;

-- Редактирование приёма пищи (нужно для обновления total_calories).
drop policy if exists "Users can update own food entries" on public.food_entries;
create policy "Users can update own food entries"
  on public.food_entries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Редактирование продукта внутри приёма пищи. Владелец определяется
-- через родительскую запись food_entries.
drop policy if exists "Users can update own meal items" on public.meal_items;
create policy "Users can update own meal items"
  on public.meal_items for update
  using (
    exists (
      select 1 from public.food_entries
      where food_entries.id = meal_items.food_entry_id
        and food_entries.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.food_entries
      where food_entries.id = meal_items.food_entry_id
        and food_entries.user_id = auth.uid()
    )
  );
