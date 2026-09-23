// ============================================================
// _shared/fcm.ts — отправка push через Firebase Cloud Messaging (HTTP v1)
// Используется обеими функциями: send-push и send-reminders.
//
// Требуемый секрет (задаётся один раз):
//   supabase secrets set FCM_SERVICE_ACCOUNT="<JSON service account, можно base64>"
// Как получить JSON: Firebase Console → Project settings → Service accounts →
//   Generate new private key (нужна роль "Firebase Admin SDK Administrator Service Agent").
// ============================================================

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

let cachedServiceAccount: Record<string, string> | null = null;
let cachedAccessToken: string | null = null;
let cachedTokenExpiresAt = 0;

export interface PushPayload {
  token: string;
  title: string;
  body: string;
  /** Доп. данные, например { route: 'water' } — куда откроет приложение по тапу */
  data?: Record<string, string>;
  /** Android-канал (должен существовать в приложении) */
  channel?: string;
}

function getServiceAccount(): Record<string, string> {
  if (cachedServiceAccount) return cachedServiceAccount;
  const raw = Deno.env.get('FCM_SERVICE_ACCOUNT');
  if (!raw) {
    throw new Error(
      'Секрет FCM_SERVICE_ACCOUNT не задан. Выполни:\n' +
        '  supabase secrets set FCM_SERVICE_ACCOUNT="$(cat firebase-adminsdk.json | base64)"',
    );
  }
  try {
    cachedServiceAccount = JSON.parse(raw);
  } catch {
    cachedServiceAccount = JSON.parse(atob(raw));
  }
  return cachedServiceAccount!;
}

// ────────────────────────────────────────────────────────────
// OAuth 2.0: подписываем service-account JWT (RS256) через WebCrypto
// и обмениваем на access token для FCM API.
// ────────────────────────────────────────────────────────────

function base64UrlEncode(data: string | Uint8Array): string {
  const b64 = typeof data === 'string' ? btoa(data) : btoa(String.fromCharCode(...data));
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToPkcs8(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----(BEGIN|END) [A-Z ]*-----/g, '')
    .replace(/\s+/g, '');
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

async function getAccessToken(): Promise<string> {
  const sa = getServiceAccount();
  if (cachedAccessToken && Date.now() < cachedTokenExpiresAt) return cachedAccessToken;

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: sa.client_email,
    scope: FCM_SCOPE,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const signingInput =
    base64UrlEncode(JSON.stringify(header)) + '.' + base64UrlEncode(JSON.stringify(claims));

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToPkcs8(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = signingInput + '.' + base64UrlEncode(new Uint8Array(signature));

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body:
      'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' +
      encodeURIComponent(jwt),
  });
  const data = await res.json();
  if (!res.ok) {
    throw new Error('OAuth token error: ' + JSON.stringify(data));
  }

  cachedAccessToken = data.access_token as string;
  cachedTokenExpiresAt = Date.now() + 50 * 60 * 1000; // токен живёт час, кешируем 50 мин
  return cachedAccessToken!;
}

// ────────────────────────────────────────────────────────────
// Отправка
// ────────────────────────────────────────────────────────────

/** Отправить push на одно устройство. Возвращает true при успехе. */
export async function sendPush(p: PushPayload): Promise<boolean> {
  const sa = getServiceAccount();
  const accessToken = await getAccessToken();
  const channel = p.channel ?? 'welmi_push';

  const body = {
    message: {
      token: p.token,
      notification: { title: p.title, body: p.body },
      data: { ...(p.data ?? {}), channel },
      android: {
        priority: 'HIGH',
        notification: {
          channel_id: channel,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: { headers: { 'apns-priority': '10' } },
    },
  };

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    },
  );

  if (!res.ok) {
    console.error('❌ FCM error', res.status, await res.text());
    return false;
  }
  return true;
}
