-- Welmi recipe catalog and recipe diary setup.
-- Run only in the intended Supabase project's SQL Editor after review.
-- This file creates new tables and does not alter/drop existing tables.

create table if not exists public.recipe_categories (
  id text primary key,
  name text not null unique,
  image_url text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recipes (
  id text primary key,
  category_id text not null references public.recipe_categories(id) on update cascade on delete restrict,
  title text not null,
  description text not null default '',
  image_url text not null default '',
  calories integer not null check (calories >= 0),
  protein_grams numeric(7,2) not null default 0 check (protein_grams >= 0),
  fat_grams numeric(7,2) not null default 0 check (fat_grams >= 0),
  carbs_grams numeric(7,2) not null default 0 check (carbs_grams >= 0),
  fiber_grams numeric(7,2) not null default 0,
  sugar_grams numeric(7,2) not null default 0,
  sodium_mg numeric(8,2) not null default 0,
  cooking_time_minutes integer not null default 20 check (cooking_time_minutes > 0),
  servings integer not null default 1 check (servings > 0),
  tags text[] not null default '{}',
  is_vegetarian boolean not null default false,
  is_high_protein boolean not null default false,
  is_low_calorie boolean not null default false,
  is_quick boolean not null default false,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id text not null references public.recipes(id) on delete cascade,
  name text not null,
  amount text not null,
  calories integer not null default 0 check (calories >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recipe_steps (
  id uuid primary key default gen_random_uuid(),
  recipe_id text not null references public.recipes(id) on delete cascade,
  step_number integer not null check (step_number > 0),
  description text not null,
  timer_minutes integer check (timer_minutes is null or timer_minutes > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (recipe_id, step_number)
);

create table if not exists public.recipe_favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  recipe_id text not null references public.recipes(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, recipe_id)
);

-- Recipe additions from the app currently use the existing food_entries and
-- meal_items tables so the existing diary UI can read them. This normalized
-- table is provided for future migration/import of richer recipe references.
create table if not exists public.meal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  recipe_id text references public.recipes(id) on delete set null,
  title text not null,
  meal_type text not null check (meal_type in ('breakfast','lunch','dinner','snack')),
  entry_date date not null default current_date,
  servings numeric(6,2) not null default 1 check (servings > 0),
  calories integer not null check (calories >= 0),
  protein_grams numeric(7,2) not null default 0,
  fat_grams numeric(7,2) not null default 0,
  carbs_grams numeric(7,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists recipes_category_published_idx on public.recipes(category_id, is_published, title);
create index if not exists recipes_tags_idx on public.recipes using gin(tags);
create index if not exists recipe_ingredients_recipe_order_idx on public.recipe_ingredients(recipe_id, sort_order);
create index if not exists recipe_steps_recipe_order_idx on public.recipe_steps(recipe_id, step_number);
create index if not exists recipe_favorites_user_idx on public.recipe_favorites(user_id, created_at desc);
create index if not exists meal_entries_user_date_idx on public.meal_entries(user_id, entry_date desc, meal_type);

alter table public.recipe_categories enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.recipe_steps enable row level security;
alter table public.recipe_favorites enable row level security;
alter table public.meal_entries enable row level security;

drop policy if exists "Public can read recipe categories" on public.recipe_categories;
create policy "Public can read recipe categories" on public.recipe_categories for select using (true);
drop policy if exists "Public can read published recipes" on public.recipes;
create policy "Public can read published recipes" on public.recipes for select using (is_published);
drop policy if exists "Public can read ingredients of published recipes" on public.recipe_ingredients;
create policy "Public can read ingredients of published recipes" on public.recipe_ingredients for select using (exists (select 1 from public.recipes r where r.id = recipe_id and r.is_published));
drop policy if exists "Public can read steps of published recipes" on public.recipe_steps;
create policy "Public can read steps of published recipes" on public.recipe_steps for select using (exists (select 1 from public.recipes r where r.id = recipe_id and r.is_published));
drop policy if exists "Users manage own recipe favorites" on public.recipe_favorites;
create policy "Users manage own recipe favorites" on public.recipe_favorites for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Users manage own meal entries" on public.meal_entries;
create policy "Users manage own meal entries" on public.meal_entries for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select on public.recipe_categories, public.recipes, public.recipe_ingredients, public.recipe_steps to anon, authenticated;
grant select, insert, delete on public.recipe_favorites to authenticated;
grant select, insert, update, delete on public.meal_entries to authenticated;
