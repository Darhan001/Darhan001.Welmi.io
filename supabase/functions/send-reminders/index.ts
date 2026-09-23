// ============================================================
// send-reminders — серверные напоминания о воде и еде.
//
// Работает по расписанию (cron), настраивается в supabase/config.toml:
//   [functions.send-reminders]
//   verify_jwt = false
//   schedule = "*/30 * * * *"
//
// Логика (время в Europe/Moscow, как и в приложении):
//   💧 Вода: каждый чётный час с 10:00 до 20:00 (если water_reminders)
//   🍳 Еда:  8:30 завтрак, 13:00 обед, 19:00 ужин (если meal_reminders)
//
// Настройки берутся из profiles.notification_prefs
// (переключается на экране «Редактирование профиля»/«Цель»).
//
// Деплой:
//   supabase link --project-ref <PROJECT_REF>
//   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat firebase-adminsdk.json | base64)"
//   supabase functions deploy send-reminders
// ============================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { sendPush } from '../_shared/fcm.ts';

// Смещение Europe/Moscow от UTC (без учёта DST, его в России нет).
const MSK_OFFSET_HOURS = 3;

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

Deno.serve(async () => {
  try {
    const now = new Date();
    const msk = new Date(now.getTime() + MSK_OFFSET_HOURS * 3600 * 1000);
    const hour = msk.getUTCHours();
    const minute = msk.getUTCMinutes();

    const sendWater = [10, 12, 14, 16, 18, 20].includes(hour) && minute === 0;
    const sendBreakfast = hour === 8 && minute === 30;
    const sendLunch = hour === 13 && minute === 0;
    const sendDinner = hour === 19 && minute === 0;

    if (!sendWater && !sendBreakfast && !sendLunch && !sendDinner) {
      return json({ ok: true, skipped: true, hour, minute });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, serviceKey);

    const { data: profiles, error } = await supabase
      .from('profiles')
      .select('id, notification_prefs')
      .limit(10000);

    if (error) throw error;

    let sent = 0;

    for (const profile of profiles ?? []) {
      const prefs = (profile.notification_prefs ?? {}) as Record<string, unknown>;
      const waterOn = prefs['water_reminders'] !== false;
      const mealOn = prefs['meal_reminders'] !== false;

      const { data: tokens } = await supabase
        .from('device_tokens')
        .select('token')
        .eq('user_id', profile.id)
        .eq('enabled', true);

      if (!tokens || tokens.length === 0) continue;

      const tasks: Array<{ title: string; body: string; route: string }> = [];
      if (sendWater && waterOn) {
        tasks.push({
          title: '💧 Время пить воду!',
          body: 'Не забудь выпить стакан чистой воды.',
          route: 'water',
        });
      }
      if (sendBreakfast && mealOn) {
        tasks.push({
          title: '🍳 Завтрак',
          body: 'Пора позавтракать и зарядиться энергией!',
          route: 'diary',
        });
      }
      if (sendLunch && mealOn) {
        tasks.push({
          title: '🥗 Обед',
          body: 'Пора пообедать — отметь приём пищи в дневнике.',
          route: 'diary',
        });
      }
      if (sendDinner && mealOn) {
        tasks.push({
          title: '🍽️ Ужин',
          body: 'Пора поужинать — отметь ужин в дневнике.',
          route: 'diary',
        });
      }

      for (const task of tasks) {
        for (const t of tokens) {
          const ok = await sendPush({
            token: t.token,
            title: task.title,
            body: task.body,
            data: { route: task.route },
          });
          if (ok) sent++;
        }
      }
    }

    return json({ ok: true, sent, hour, minute });
  } catch (e) {
    console.error('❌ send-reminders error:', e);
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
