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

/** Роль из JWT (anon | authenticated | service_role) без проверки подписи —
 *  только для разграничения аноним/сервер; реальную проверку делает getUser(). */
function decodeJwtRole(token: string): string | null {
  try {
    const payload = token.split('.')[1];
    const b64 = payload.replace(/-/g, '+').replace(/_/g, '/');
    const json = JSON.parse(atob(b64));
    return typeof json.role === 'string' ? json.role : null;
  } catch {
    return null;
  }
}

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
    if (!title || !body) return json({ error: 'title и body обязательны' }, 400);

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, serviceKey);

    // Проверка: слать push может только сам пользователь (реальная сессия)
    // или серверный вызов с service role. Аноним с anon-ключом → 403.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ error: 'Authorization header обязателен' }, 401);
    }

    const jwtRole = decodeJwtRole(authHeader.slice(7));
    if (jwtRole !== 'service_role') {
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
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
