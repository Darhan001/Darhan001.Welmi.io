-- ============================================================
-- Welmi — Supabase Schema
-- ============================================================
-- Инструкция:
-- 1. Создай проект в Supabase (app.supabase.com)
-- 2. Открой SQL Editor
-- 3. Вставь этот SQL и запусти
-- 4. Скопируй URL и anon key из Settings → API
-- ============================================================

-- 1. PROFILES (профили пользователей)
-- ============================================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  display_name TEXT,
  email TEXT,
  photo_url TEXT,
  goal TEXT CHECK (goal IN ('loseWeight', 'gainWeight', 'maintainWeight')),
  gender TEXT CHECK (gender IN ('male', 'female')),
  height_cm REAL DEFAULT 175,
  current_weight_kg REAL DEFAULT 72,
  target_weight_kg REAL DEFAULT 70,
  birth_date DATE DEFAULT '1995-01-01',
  activity_level TEXT CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'high')),
  goal_speed_kg_per_week REAL DEFAULT 0.5,
  subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro')),
  subscription_expires_at TIMESTAMPTZ,
  units_system TEXT DEFAULT 'metric' CHECK (units_system IN ('metric', 'imperial')),
  notification_prefs JSONB DEFAULT '{"water_reminders": true, "meal_reminders": true, "motivational": false}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger: автоматическое обновление updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. WEIGHT ENTRIES (записи веса)
-- ============================================================
CREATE TABLE weight_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  weight_kg REAL NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_weight_entries_user_date ON weight_entries(user_id, date DESC);

-- 3. WATER ENTRIES (записи воды)
-- ============================================================
CREATE TABLE water_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount_ml INTEGER NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_water_entries_user_date ON water_entries(user_id, date DESC);

-- 4. FOOD DIARY ENTRIES (приёмы пищи)
-- ============================================================
CREATE TYPE meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');

CREATE TABLE food_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  meal_type meal_type NOT NULL DEFAULT 'breakfast',
  total_calories INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_food_entries_user_date ON food_entries(user_id, date DESC);

-- 5. MEAL ITEMS (продукты в приёме пищи)
-- ============================================================
CREATE TABLE meal_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  food_entry_id UUID NOT NULL REFERENCES food_entries(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  calories INTEGER NOT NULL,
  protein_grams REAL,
  fat_grams REAL,
  carbs_grams REAL,
  amount_grams REAL,
  info TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_meal_items_entry ON meal_items(food_entry_id);

-- 6. ACTIVITY LOGS (активность/шаги)
-- ============================================================
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  steps INTEGER DEFAULT 0,
  calories_burned REAL,
  active_minutes REAL,
  distance_km REAL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_logs_user_date ON activity_logs(user_id, date DESC);

-- 7. BODY MEASUREMENTS (замеры тела)
-- ============================================================
CREATE TABLE body_measurements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  chest_cm REAL,
  waist_cm REAL,
  hips_cm REAL,
  left_arm_cm REAL,
  right_arm_cm REAL,
  left_thigh_cm REAL,
  right_thigh_cm REAL,
  neck_cm REAL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_body_measurements_user_date ON body_measurements(user_id, date DESC);

-- 8. BODY FAT ENTRIES (% жира)
-- ============================================================
CREATE TABLE body_fat_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  body_fat_percent REAL NOT NULL,
  method TEXT CHECK (method IN ('caliper', 'scale', 'manual', 'estimated')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_body_fat_user_date ON body_fat_entries(user_id, date DESC);

-- 9. DAILY NUTRITION SUMMARY (сводка за день)
-- ============================================================
CREATE TABLE daily_nutrition (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_calories INTEGER DEFAULT 0,
  protein_grams INTEGER DEFAULT 0,
  fat_grams INTEGER DEFAULT 0,
  carb_grams INTEGER DEFAULT 0,
  water_ml INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

CREATE INDEX idx_daily_nutrition_user_date ON daily_nutrition(user_id, date DESC);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
-- Важно! После создания таблиц нужно включить RLS:
-- 1. Зайди в Authentication → Policies
-- 2. Или выполни SQL ниже
-- ============================================================

-- Включаем RLS на всех таблицах
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_nutrition ENABLE ROW LEVEL SECURITY;
-- FIX (critical security gap): these two tables were created but RLS was never
-- switched on, so any authenticated user could read/write ALL users' body data.
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_fat_entries ENABLE ROW LEVEL SECURITY;

-- Политики для profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Политики для weight_entries
CREATE POLICY "Users can view own weight entries"
  ON weight_entries FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own weight entries"
  ON weight_entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own weight entries"
  ON weight_entries FOR DELETE
  USING (auth.uid() = user_id);

-- FIX: пользователь не мог отредактировать неверно введённый вес
CREATE POLICY "Users can update own weight entries"
  ON weight_entries FOR UPDATE
  USING (auth.uid() = user_id);

-- Политики для water_entries
CREATE POLICY "Users can view own water entries"
  ON water_entries FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own water entries"
  ON water_entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- FIX: было невозможно исправить/удалить ошибочную запись воды
CREATE POLICY "Users can update own water entries"
  ON water_entries FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own water entries"
  ON water_entries FOR DELETE
  USING (auth.uid() = user_id);

-- Политики для body_measurements (FIX: отсутствовали полностью)
CREATE POLICY "Users can view own body measurements"
  ON body_measurements FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own body measurements"
  ON body_measurements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own body measurements"
  ON body_measurements FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own body measurements"
  ON body_measurements FOR DELETE
  USING (auth.uid() = user_id);

-- Политики для body_fat_entries (FIX: отсутствовали полностью)
CREATE POLICY "Users can view own body fat entries"
  ON body_fat_entries FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own body fat entries"
  ON body_fat_entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own body fat entries"
  ON body_fat_entries FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own body fat entries"
  ON body_fat_entries FOR DELETE
  USING (auth.uid() = user_id);

-- Политики для food_entries
CREATE POLICY "Users can view own food entries"
  ON food_entries FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own food entries"
  ON food_entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own food entries"
  ON food_entries FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own food entries"
  ON food_entries FOR DELETE
  USING (auth.uid() = user_id);

-- Политики для meal_items (через food_entry)
CREATE POLICY "Users can view own meal items"
  ON meal_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM food_entries
      WHERE food_entries.id = meal_items.food_entry_id
      AND food_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own meal items"
  ON meal_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM food_entries
      WHERE food_entries.id = meal_items.food_entry_id
      AND food_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own meal items"
  ON meal_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM food_entries
      WHERE food_entries.id = meal_items.food_entry_id
      AND food_entries.user_id = auth.uid()
    )
  );

-- Политики для activity_logs
CREATE POLICY "Users can view own activity logs"
  ON activity_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activity logs"
  ON activity_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own activity logs"
  ON activity_logs FOR UPDATE
  USING (auth.uid() = user_id);

-- FIX: пользователь не мог удалить ошибочно добавленную активность
CREATE POLICY "Users can delete own activity logs"
  ON activity_logs FOR DELETE
  USING (auth.uid() = user_id);

-- Политики для daily_nutrition
CREATE POLICY "Users can view own nutrition"
  ON daily_nutrition FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own nutrition"
  ON daily_nutrition FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own nutrition"
  ON daily_nutrition FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- 10. STORAGE: фото профилей (bucket 'avatars')
-- ============================================================
-- Нужно для смены фото профиля на экране «Редактирование».
-- Запусти этот блок в SQL Editor (работает от роли postgres).

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Фото профиля публичное (не требует авторизации для просмотра)
DROP POLICY IF EXISTS "Public read avatars" ON storage.objects;
CREATE POLICY "Public read avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Загружать фото может только владелец (путь: avatars/{user_id}/...)
DROP POLICY IF EXISTS "Users can upload own avatars" ON storage.objects;
CREATE POLICY "Users can upload own avatars"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can update own avatars" ON storage.objects;
CREATE POLICY "Users can update own avatars"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can delete own avatars" ON storage.objects;
CREATE POLICY "Users can delete own avatars"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================
-- GOOGLE AUTH (через Supabase)
-- ============================================================
-- После создания таблиц, настрой вход через Google:
-- 1. Authentication → Providers → Google → Enable
-- 2. Введи Client ID и Client Secret из Google Cloud Console
-- 3. URL для редиректа: https://YOUR_PROJECT.supabase.co/auth/v1/callback
-- ============================================================

-- ============================================================
-- 11. PUSH-УВЕДОМЛЕНИЯ (FCM): таблица device_tokens
-- ============================================================
-- Хранит FCM-токены устройств. Приложение добавляет токен при входе,
-- Edge Function send-push читает токены и отправляет push.
-- Запусти этот блок в SQL Editor (идиемпотентен — можно повторять).
-- ============================================================

CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL DEFAULT 'android' CHECK (platform IN ('android', 'ios')),
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);

-- Триггер обновления updated_at (переиспользуем функцию из п.1)
DROP TRIGGER IF EXISTS device_tokens_updated_at ON device_tokens;
CREATE TRIGGER device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS: пользователь видит и удаляет только свои токены
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own device tokens" ON device_tokens;
CREATE POLICY "Users can view own device tokens"
  ON device_tokens FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own device tokens" ON device_tokens;
CREATE POLICY "Users can insert own device tokens"
  ON device_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own device tokens" ON device_tokens;
CREATE POLICY "Users can update own device tokens"
  ON device_tokens FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own device tokens" ON device_tokens;
CREATE POLICY "Users can delete own device tokens"
  ON device_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- Edge Function работает под service_role и RLS не затрагивает её.
