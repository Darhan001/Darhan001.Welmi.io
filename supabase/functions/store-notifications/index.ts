import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5.9.6';
import {
  admin,
  saveVerifiedSubscription,
  verifyAppleNotification,
  verifyAppleTransaction,
  verifyGooglePlay,
} from '../_shared/subscription_verification.ts';

const googleJwks = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'));

async function assertGooglePushIdentity(request: Request): Promise<void> {
  const authorization = request.headers.get('Authorization') ?? '';
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
  if (!token) throw new Error('Google Pub/Sub identity token is missing.');
  const audience = Deno.env.get('PUBSUB_OIDC_AUDIENCE');
  const serviceAccountEmail = Deno.env.get('PUBSUB_SERVICE_ACCOUNT_EMAIL');
  if (!audience || !serviceAccountEmail) throw new Error('Pub/Sub OIDC secrets are not configured.');
  const { payload } = await jwtVerify(token, googleJwks, {
    issuer: ['https://accounts.google.com', 'accounts.google.com'],
    audience,
  });
  if (payload.email !== serviceAccountEmail || payload.email_verified !== true) {
    throw new Error('Pub/Sub service account is not authorized.');
  }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return Response.json({ error: 'Method not allowed' }, { status: 405 });
  try {
    const body = await request.json();
    if (typeof body.signedPayload === 'string') {
      await handleAppleNotification(body.signedPayload);
      return Response.json({ ok: true });
    }
    await assertGooglePushIdentity(request);
    await handleGoogleNotification(body);
    return Response.json({ ok: true });
  } catch (error) {
    console.error('store notification rejected:', error);
    return Response.json({ error: 'Notification could not be processed.' }, { status: 400 });
  }
});

async function handleGoogleNotification(body: Record<string, any>): Promise<void> {
  const encoded = body.message?.data;
  if (typeof encoded !== 'string') throw new Error('Pub/Sub message.data is missing.');
  const notification = JSON.parse(atob(encoded));
  const purchaseToken = notification.subscriptionNotification?.purchaseToken;
  const productId = notification.subscriptionNotification?.subscriptionId;
  if (!purchaseToken || !productId) return; // Test or non-subscription event.
  const db = admin();
  const { data: transaction, error } = await db
    .from('subscription_store_transactions')
    .select('user_id, product_id')
    .eq('store', 'google_play')
    .eq('purchase_token', purchaseToken)
    .maybeSingle();
  if (error) throw error;
  if (!transaction) return; // Purchases must first be linked by verify-subscription.
  const verified = await verifyGooglePlay(String(productId), purchaseToken);
  await saveVerifiedSubscription(transaction.user_id, verified);
}

async function handleAppleNotification(signedPayload: string): Promise<void> {
  const notification = await verifyAppleNotification(signedPayload);
  const data = notification.data as Record<string, unknown> | undefined;
  const signedTransaction = data?.signedTransactionInfo;
  if (typeof signedTransaction !== 'string') return;
  // The notification and nested JWS are signed by Apple. Extract the transaction
  // ID only to look it up; the App Store Server API response is verified again.
  const payloadPart = signedTransaction.split('.')[1];
  if (!payloadPart) throw new Error('Apple transaction payload is malformed.');
  const transactionData = JSON.parse(atob(payloadPart.replace(/-/g, '+').replace(/_/g, '/')));
  const transactionId = String(transactionData.transactionId ?? '');
  if (!transactionId) throw new Error('Apple transaction ID is missing.');
  const verified = await verifyAppleTransaction(transactionId);
  const db = admin();
  const { data: transaction, error } = await db
    .from('subscription_store_transactions')
    .select('user_id')
    .eq('store', 'app_store')
    .eq('original_transaction_id', verified.originalTransactionId)
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  if (!transaction) return;
  await saveVerifiedSubscription(transaction.user_id, verified);
}
