import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const allowedCategories = new Set(['feedback', 'bug', 'idea', 'support']);
const categoryLabels: Record<string, string> = {
  feedback: 'Обратная связь',
  bug: 'Bug',
  idea: 'Idea',
  support: 'Поддержка',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  console.info('send-feedback: request received');

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'Invalid request body' }, 400);
  }

  try {
    const authorization = request.headers.get('Authorization');
    const apiKey = request.headers.get('apikey');
    if (!authorization?.startsWith('Bearer ') || !apiKey) {
      return json({ error: 'Supabase credentials are required' }, 401);
    }

    // JWT gateway validation is disabled only for this function to allow
    // publishable-key guest calls. Validate the project's public API key here,
    // then verify any signed-in user's access token with Auth below.
    const publicKeys = new Set<string>();
    const legacyAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    if (legacyAnonKey) publicKeys.add(legacyAnonKey);
    try {
      const configuredKeys = JSON.parse(Deno.env.get('SUPABASE_PUBLISHABLE_KEYS') ?? '{}');
      if (configuredKeys && typeof configuredKeys === 'object') {
        for (const key of Object.values(configuredKeys)) {
          if (typeof key === 'string') publicKeys.add(key);
        }
      }
    } catch {
      // Continue with the legacy anonymous key when no publishable-key map exists.
    }
    if (!publicKeys.has(apiKey)) return json({ error: 'Invalid project API key' }, 401);

    if (body == null || typeof body !== 'object' || Array.isArray(body)) {
      return json({ error: 'Invalid request body' }, 400);
    }

    const { category, message, user_id, app_version, platform } = body as Record<
      string,
      unknown
    >;
    if (typeof category !== 'string' || !allowedCategories.has(category)) {
      return json({ error: 'Invalid category' }, 400);
    }
    if (typeof message !== 'string' || !message.trim()) {
      return json({ error: 'Message is required' }, 400);
    }
    const cleanMessage = message.trim();
    if (cleanMessage.length > 3000) {
      return json({ error: 'Message exceeds 3000 characters' }, 400);
    }
    if (user_id != null && (typeof user_id !== 'string' || user_id.length > 128)) {
      return json({ error: 'Invalid user_id' }, 400);
    }
    if (app_version != null && (typeof app_version !== 'string' || app_version.length > 40)) {
      return json({ error: 'Invalid app_version' }, 400);
    }
    if (platform != null && (typeof platform !== 'string' || platform.length > 40)) {
      return json({ error: 'Invalid platform' }, 400);
    }

    const token = authorization.slice('Bearer '.length);
    let verifiedUserId: string | null = null;
    if (token === apiKey) {
      if (user_id != null) return json({ error: 'Guest requests cannot set user_id' }, 403);
    } else {
      const supabaseUrl = Deno.env.get('SUPABASE_URL');
      if (!supabaseUrl) return json({ error: 'Function configuration error' }, 500);
      const supabase = createClient(supabaseUrl, apiKey, {
        global: { headers: { Authorization: authorization } },
        auth: { autoRefreshToken: false, persistSession: false },
      });
      const { data, error } = await supabase.auth.getUser(token);
      if (error || !data.user) return json({ error: 'Invalid user session' }, 401);
      verifiedUserId = data.user.id;
      if (user_id != null && user_id !== verifiedUserId) {
        return json({ error: 'user_id does not match the session' }, 403);
      }
    }

    const botToken = Deno.env.get('TELEGRAM_BOT_TOKEN');
    const chatId = Deno.env.get('TELEGRAM_CHAT_ID');
    console.info('send-feedback: Telegram secrets status', {
      TELEGRAM_BOT_TOKEN: botToken ? 'SECRET EXISTS' : 'SECRET MISSING',
      TELEGRAM_CHAT_ID: chatId ? 'SECRET EXISTS' : 'SECRET MISSING',
    });
    if (!botToken || !chatId) {
      return json({ error: 'Feedback delivery is not configured' }, 503);
    }

    const telegramText = [
      '📝 Новая обратная связь — Welmi',
      '',
      `Категория: ${categoryLabels[category]}`,
      '',
      'Сообщение:',
      cleanMessage,
      '',
      'Пользователь:',
      verifiedUserId ?? 'Гость',
      '',
      `User ID: ${verifiedUserId ?? '—'}`,
      `Платформа: ${typeof platform === 'string' ? platform : 'Не указана'}`,
      `Версия: ${typeof app_version === 'string' ? app_version : 'Не указана'}`,
    ].join('\n');

    let telegramResponse: Response;
    try {
      console.info('send-feedback: Telegram request started');
      telegramResponse = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chat_id: chatId, text: telegramText, disable_web_page_preview: true }),
        signal: AbortSignal.timeout(10000),
      });
    } catch {
      console.error('send-feedback: Telegram request failed before an HTTP response');
      return json({ error: 'Telegram is temporarily unavailable' }, 502);
    }

    let telegramResult: { ok?: boolean; error_code?: number } | null = null;
    try {
      telegramResult = await telegramResponse.json();
    } catch {
      // A non-JSON provider response is treated as a delivery failure below.
    }
    console.info('send-feedback: Telegram response', {
      status: telegramResponse.status,
      accepted: telegramResult?.ok === true,
      errorCode: telegramResult?.error_code ?? null,
    });
    if (!telegramResponse.ok || telegramResult?.ok !== true) {
      return json({ error: 'Telegram could not deliver the message' }, 502);
    }

    return json({ ok: true });
  } catch {
    console.error('send-feedback: function error');
    return json({ error: 'Feedback service is temporarily unavailable' }, 500);
  }
});
