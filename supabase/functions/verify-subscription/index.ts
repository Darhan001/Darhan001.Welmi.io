import { createClient } from 'jsr:@supabase/supabase-js@2';
import {
  PRODUCT_IDS,
  saveVerifiedSubscription,
  verifyAppleTransaction,
  verifyGooglePlay,
} from '../_shared/subscription_verification.ts';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (request.method !== 'POST') return Response.json({ error: 'Method not allowed' }, { status: 405, headers: cors });

  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) return Response.json({ error: 'Unauthorized' }, { status: 401, headers: cors });
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authorization } } },
    );
    const { data: { user }, error } = await userClient.auth.getUser();
    if (error || !user) return Response.json({ error: 'Unauthorized' }, { status: 401, headers: cors });

    const body = await request.json();
    const productId = String(body.productId ?? '');
    const platform = String(body.platform ?? '');
    if (!PRODUCT_IDS.has(productId)) throw new Error('Unsupported subscription product.');

    const verified = platform === 'android'
      ? await verifyGooglePlay(productId, String(body.serverVerificationData ?? ''))
      : platform === 'ios'
        ? await verifyAppleTransaction(String(body.transactionId ?? ''), productId)
        : null;
    if (!verified) throw new Error('Unsupported store platform.');

    await saveVerifiedSubscription(user.id, verified);
    return Response.json({ verified: true, status: verified.status, expiresAt: verified.expiresAt }, { headers: cors });
  } catch (error) {
    console.error('verify-subscription rejected:', error);
    return Response.json({ verified: false, error: 'Store transaction could not be verified.' }, { status: 400, headers: cors });
  }
});
