// ============================================================
// send-push — отправка push-уведомления конкретному пользователю.
//
// Тело запроса (JSON):
//   {
//     "user_id": "uuid-пользователя",   // кому слать (обязательно)
//     "title": "💧 Время пить воду!",
//     "body": "Не забудь выпить стакан чистой воды.",
//     "route": "water",                  // куда откроется приложение по тапу
//     "channel": "welmi_push"            // Android-канал (необязательно)
//   }
//
// Безопасность:
//   - Функция рассчитана на verify_jwt = true (по умолчанию).
//   - Пользователь может слать push только САМ себе (user_id = свой UUID):
//     без реальной пользовательской сессии запрос отклоняется (403) —
//     аноним с anon-ключом ничего не сможет отправить.
//   - Из Edge Function / сервера (service_role) можно слать любому.
//
// Деплой:
//   supabase link --project-ref <PROJECT_REF>
//   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat firebase-adminsdk.json | base64)"
//   supabase functions deploy send-push
// ============================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { sendPush } from '../_shared/fcm.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { user_id, title, body, route, channel } = await req.json();
    if (!user_id) return json({ error: 'user_id обязателен' }, 400);
    if (typeof title !== 'string' || typeof body !== 'string' || !title || !body) {
      return json({ error: 'title и body обязательны' }, 400);
    }
    if (title.length > 120 || body.length > 1000) {
      return json({ error: 'title/body слишком длинные' }, 400);
    }
    if (route != null && (typeof route !== 'string' || route.length > 40)) {
      return json({ error: 'route некорректен' }, 400);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, serviceKey);

    // Проверка: слать push может только сам пользователь (реальная сессия)
    // или серверный вызов с service role. Аноним с anon-ключом → 403.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ error: 'Authorization header обязателен' }, 401);
    }

    // Серверный вызов признаётся только по самому service-ключу. Раньше
    // роль читалась из JWT без проверки подписи: при деплое с
    // --no-verify-jwt поддельный токен {"role":"service_role"} позволял
    // слать push любому пользователю, а ключи вида sb_secret_… (не JWT)
    // вовсе не распознавались как серверные.
    const isServiceCall = authHeader.slice(7) === serviceKey;
    if (!isServiceCall) {
      const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
      const client = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: authHeader } },
      });
      const { data: { user } } = await client.auth.getUser();
      if (user == null || user.id !== user_id) {
        return json(
          { error: 'Нужна сессия этого пользователя (или service role)' },
          403,
        );
      }
    }

    const { data: tokens, error } = await supabase
      .from('device_tokens')
      .select('token')
      .eq('user_id', user_id)
      .eq('enabled', true);

    if (error) throw error;

    let sent = 0;
    let failed = 0;
    for (const t of tokens ?? []) {
      const ok = await sendPush({
        token: t.token,
        title,
        body,
        data: { route: route ?? 'home' },
        channel,
      });
      ok ? sent++ : failed++;
    }

    return json({ ok: true, sent, failed, total: tokens?.length ?? 0 });
  } catch (e) {
    console.error('❌ send-push error:', e);
    return json({ error: 'Push delivery failed' }, 500);
  }
});
