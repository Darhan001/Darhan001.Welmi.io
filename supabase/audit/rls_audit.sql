-- ============================================================
-- Welmi — проверка Row Level Security (ТОЛЬКО ЧТЕНИЕ).
--
-- Скрипт ничего не меняет: только SELECT из системных каталогов.
-- Запуск: Supabase Dashboard → SQL Editor → вставить → Run.
--
-- Зачем: в репозитории нет миграций для основных таблиц (profiles,
-- дневник, вода, вес, device_tokens …), а клиент полагается на RLS
-- («каждый видит только своё»). Состояние политик в рабочей базе по коду
-- проверить нельзя — его показывает этот скрипт.
-- ============================================================

-- 1. Таблицы, к которым обращается приложение: включён ли RLS.
--    Ожидается rls_enabled = true для ВСЕХ строк. false = любой владелец
--    anon-ключа (он есть в каждом APK) читает и меняет чужие данные.
with app_tables(name) as (
  values ('profiles'), ('food_entries'), ('meal_items'), ('daily_nutrition'),
         ('water_entries'), ('weight_entries'), ('activity_logs'),
         ('body_measurements'), ('workout_history'), ('recipe_favorites'),
         ('recipes'), ('device_tokens'), ('subscription_entitlements'),
         ('subscription_store_transactions')
)
select t.name as table_name,
       c.oid is not null as table_exists,
       coalesce(c.relrowsecurity, false) as rls_enabled,
       coalesce(c.relforcerowsecurity, false) as rls_forced,
       (select count(*) from pg_policies p
         where p.schemaname = 'public' and p.tablename = t.name) as policy_count
from app_tables t
left join pg_class c
  on c.relname = t.name
 and c.relnamespace = 'public'::regnamespace
order by rls_enabled, t.name;

-- 2. Все политики public-схемы с условиями. Проверьте, что:
--    • условие опирается на auth.uid() (= user_id / = id для profiles);
--    • meal_items проверяет владельца через food_entries
--      (у позиции нет собственного user_id);
--    • нет политик с qual = 'true' для ролей anon/authenticated
--      (кроме справочников вроде recipes, и то только на SELECT);
--    • у UPDATE есть и USING, и WITH CHECK — иначе строку можно
--      «переписать» на чужой user_id.
select tablename, policyname, cmd, roles, qual as using_expr,
       with_check as with_check_expr
from pg_policies
where schemaname = 'public'
order by tablename, cmd, policyname;

-- 3. Политики без привязки к auth.uid() — кандидаты на утечку данных.
select tablename, policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename <> 'recipes'
  and coalesce(qual, '') not ilike '%auth.uid()%'
  and coalesce(with_check, '') not ilike '%auth.uid()%';

-- 4. Права ролей anon/authenticated на таблицы. anon не должен иметь
--    INSERT/UPDATE/DELETE ни на одну пользовательскую таблицу.
select table_name, grantee, string_agg(privilege_type, ', ' order by privilege_type) as privileges
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee in ('anon', 'authenticated')
group by table_name, grantee
order by table_name, grantee;

-- 5. Storage: bucket avatars. Ожидается, что запись разрешена только в
--    папку <auth.uid()>/…, а ограничения размера и MIME заданы у bucket.
select id, name, public, file_size_limit, allowed_mime_types
from storage.buckets
where id = 'avatars';

select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
order by policyname;

-- 6. SECURITY DEFINER функции в public: выполняются с правами владельца
--    и обходят RLS. Каждую нужно проверить вручную.
select p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
where p.pronamespace = 'public'::regnamespace
  and p.prosecdef;
