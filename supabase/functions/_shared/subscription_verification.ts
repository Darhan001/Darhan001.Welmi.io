import { createClient } from 'jsr:@supabase/supabase-js@2';
import {
  AppStoreServerAPIClient,
  Environment,
  SignedDataVerifier,
} from 'npm:@apple/app-store-server-library@3.1.0';
import { importPKCS8, SignJWT } from 'npm:jose@5.9.6';

export type VerifiedSubscription = {
  store: 'google_play' | 'app_store';
  productId: string;
  transactionId: string;
  originalTransactionId: string;
  purchaseToken: string | null;
  status: 'active' | 'in_grace_period' | 'expired' | 'revoked' | 'billing_retry';
  startedAt: string | null;
  expiresAt: string | null;
  autoRenewEnabled: boolean | null;
};

export const MONTHLY_ID = 'welmi_premium_monthly';
export const YEARLY_ID = 'welmi_premium_yearly';
export const PRODUCT_IDS = new Set([MONTHLY_ID, YEARLY_ID]);

export const admin = () => createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

function required(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing server secret: ${name}`);
  return value;
}

async function googleAccessToken(): Promise<string> {
  const account = JSON.parse(atob(required('GOOGLE_PLAY_SERVICE_ACCOUNT_BASE64')));
  const key = await importPKCS8(account.private_key, 'RS256');
  const assertion = await new SignJWT({ scope: 'https://www.googleapis.com/auth/androidpublisher' })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(account.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('55m')
    .sign(key);
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  const body = await response.json();
  if (!response.ok || typeof body.access_token !== 'string') {
    throw new Error(`Google OAuth failed (${response.status})`);
  }
  return body.access_token;
}

export async function verifyGooglePlay(
  productId: string,
  purchaseToken: string,
): Promise<VerifiedSubscription> {
  const accessToken = await googleAccessToken();
  const packageName = required('ANDROID_PACKAGE_NAME');
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
  const response = await fetch(url, {
    headers: { authorization: `Bearer ${accessToken}` },
  });
  const purchase = await response.json();
  if (!response.ok) throw new Error(`Google Play verification failed (${response.status})`);

  const line = (purchase.lineItems ?? []).find(
    (item: Record<string, unknown>) => item.productId === productId,
  );
  if (!PRODUCT_IDS.has(productId) || !line) throw new Error('Product does not match the verified purchase.');

  const expiryMs = line.expiryTime ? Date.parse(line.expiryTime) : NaN;
  const state = purchase.subscriptionState as string;
  const validState = state === 'SUBSCRIPTION_STATE_ACTIVE' ||
    state === 'SUBSCRIPTION_STATE_CANCELED' ||
    state === 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD';
  const status = !validState || !Number.isFinite(expiryMs) || expiryMs <= Date.now()
    ? 'expired'
    : state === 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD' ? 'in_grace_period' : 'active';
  return {
    store: 'google_play',
    productId,
    // Google renewals can keep the purchase token while the order ID changes;
    // use the stable token as this provider's upsert key.
    transactionId: purchaseToken,
    originalTransactionId: purchaseToken,
    purchaseToken,
    status,
    startedAt: purchase.startTime ?? null,
    expiresAt: Number.isFinite(expiryMs) ? new Date(expiryMs).toISOString() : null,
    autoRenewEnabled: line.autoRenewingPlan?.autoRenewEnabled ?? null,
  };
}

function appleRootCertificates(): Uint8Array[] {
  return required('APPLE_ROOT_CERTIFICATES_BASE64')
    .split(',')
    .map((certificate) => Uint8Array.from(atob(certificate.trim()), (c) => c.charCodeAt(0)));
}

export async function verifyAppleNotification(signedPayload: string): Promise<Record<string, unknown>> {
  const bundleId = required('APPLE_BUNDLE_ID');
  const appAppleId = Number(required('APPLE_APP_ID'));
  let payload: Record<string, unknown> | undefined;
  for (const environment of [Environment.PRODUCTION, Environment.SANDBOX]) {
    try {
      const verifier = new SignedDataVerifier(
        appleRootCertificates(), true, environment, bundleId, appAppleId,
      );
      payload = await verifier.verifyAndDecodeNotification(signedPayload);
      break;
    } catch {
      // Try the other signed App Store environment.
    }
  }
  if (!payload) throw new Error('Apple notification signature is invalid.');
  return payload;
}

export async function verifyAppleTransaction(
  transactionId: string,
  expectedProductId?: string,
): Promise<VerifiedSubscription> {
  const bundleId = required('APPLE_BUNDLE_ID');
  const rootCertificates = appleRootCertificates();
  const privateKey = required('APPLE_IAP_PRIVATE_KEY');
  const keyId = required('APPLE_IAP_KEY_ID');
  const issuerId = required('APPLE_IAP_ISSUER_ID');
  const appAppleId = Number(required('APPLE_APP_ID'));

  let verified: Record<string, unknown> | undefined;
  let subscriptionStatus: number | undefined;
  let gracePeriodExpiresAt: number | undefined;
  let autoRenewStatus: number | undefined;
  for (const environment of [Environment.PRODUCTION, Environment.SANDBOX]) {
    try {
      const api = new AppStoreServerAPIClient(
        privateKey, keyId, issuerId, bundleId, environment,
      );
      const result = await api.getTransactionInfo(transactionId);
      if (!result.signedTransactionInfo) {
        throw new Error('Apple transaction has no signed transaction data.');
      }
      const verifier = new SignedDataVerifier(
        rootCertificates, true, environment, bundleId, appAppleId,
      );
      const initial = await verifier.verifyAndDecodeTransaction(result.signedTransactionInfo);
      if (initial.bundleId !== bundleId) throw new Error('Apple transaction belongs to another app.');
      const initialProductId = String(initial.productId ?? '');
      if (!PRODUCT_IDS.has(initialProductId) ||
          (expectedProductId && expectedProductId !== initialProductId)) {
        throw new Error('Product does not match the verified Apple transaction.');
      }

      const statusResponse = await api.getAllSubscriptionStatuses(
        String(initial.originalTransactionId ?? transactionId),
      );
      const candidates: Array<{
        status: number;
        transaction: Record<string, unknown>;
        renewal: Record<string, unknown>;
      }> = [];
      for (const group of statusResponse.data ?? []) {
        for (const latest of group.lastTransactions ?? []) {
          if (!latest.signedTransactionInfo) continue;
          const latestTransaction = await verifier.verifyAndDecodeTransaction(
            latest.signedTransactionInfo,
          );
          if (String(latestTransaction.originalTransactionId) !==
              String(initial.originalTransactionId)) continue;
          const currentProductId = String(latestTransaction.productId ?? '');
          if (!PRODUCT_IDS.has(currentProductId)) continue;
          const renewal = latest.signedRenewalInfo
            ? await verifier.verifyAndDecodeRenewalInfo(latest.signedRenewalInfo)
            : {};
          candidates.push({
            status: Number(latest.status ?? 0),
            transaction: latestTransaction as unknown as Record<string, unknown>,
            renewal: renewal as unknown as Record<string, unknown>,
          });
        }
      }
      candidates.sort((a, b) =>
        Number(b.transaction.expiresDate ?? 0) - Number(a.transaction.expiresDate ?? 0));
      const latest = candidates[0];
      verified = (latest?.transaction ?? initial) as unknown as Record<string, unknown>;
      subscriptionStatus = latest?.status;
      gracePeriodExpiresAt = Number(latest?.renewal.gracePeriodExpiresDate ?? 0) || undefined;
      autoRenewStatus = Number(latest?.renewal.autoRenewStatus ?? 0);
      break;
    } catch {
      // A sandbox transaction queried against production returns an API error;
      // retry using Apple's sandbox endpoint before failing closed.
    }
  }
  if (!verified) throw new Error('Apple did not return a verifiable transaction.');
  if (verified.bundleId !== bundleId) throw new Error('Apple transaction belongs to another app.');
  const productId = String(verified.productId ?? '');
  if (!PRODUCT_IDS.has(productId) || (expectedProductId && expectedProductId !== productId)) {
    throw new Error('Product does not match the verified Apple transaction.');
  }
  let expiryMs = Number(verified.expiresDate ?? 0);
  const revoked = verified.revocationDate != null;
  let status: VerifiedSubscription['status'];
  if (revoked || subscriptionStatus === 5) {
    status = 'revoked';
  } else if (subscriptionStatus === 4) {
    expiryMs = gracePeriodExpiresAt ?? expiryMs;
    status = expiryMs > Date.now() ? 'in_grace_period' : 'expired';
  } else if (subscriptionStatus === 3) {
    status = expiryMs > Date.now() ? 'active' : 'billing_retry';
  } else if (subscriptionStatus === 2) {
    status = 'expired';
  } else {
    status = expiryMs > Date.now() ? 'active' : 'expired';
  }
  return {
    store: 'app_store',
    productId,
    transactionId: String(verified.transactionId),
    originalTransactionId: String(verified.originalTransactionId),
    purchaseToken: null,
    status,
    startedAt: verified.purchaseDate == null
      ? null
      : new Date(Number(verified.purchaseDate)).toISOString(),
    expiresAt: expiryMs > 0 ? new Date(expiryMs).toISOString() : null,
    autoRenewEnabled: autoRenewStatus == null ? null : autoRenewStatus === 1,
  };
}

export async function saveVerifiedSubscription(
  userId: string,
  verified: VerifiedSubscription,
): Promise<void> {
  const db = admin();
  const { data: existing } = await db
    .from('subscription_entitlements')
    .select('user_id')
    .eq('store', verified.store)
    .eq('original_transaction_id', verified.originalTransactionId)
    .maybeSingle();
  if (existing && existing.user_id !== userId) {
    throw new Error('This store subscription is already linked to another Welmi account.');
  }

  const { error: transactionError } = await db
    .from('subscription_store_transactions')
    .upsert({
      user_id: userId,
      store: verified.store,
      product_id: verified.productId,
      transaction_id: verified.transactionId,
      original_transaction_id: verified.originalTransactionId,
      purchase_token: verified.purchaseToken,
      status: verified.status,
      expires_at: verified.expiresAt,
      verified_at: new Date().toISOString(),
    }, { onConflict: 'store,transaction_id' });
  if (transactionError) throw transactionError;

  const { error } = await db.from('subscription_entitlements').upsert({
    user_id: userId,
    store: verified.store,
    product_id: verified.productId,
    original_transaction_id: verified.originalTransactionId,
    status: verified.status,
    started_at: verified.startedAt,
    expires_at: verified.expiresAt,
    auto_renew_enabled: verified.autoRenewEnabled,
    updated_at: new Date().toISOString(),
  }, { onConflict: 'user_id' });
  if (error) throw error;
}
