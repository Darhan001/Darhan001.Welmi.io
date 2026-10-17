-- Welmi Premium entitlements. This file is a migration proposal; it has not
-- been run against the configured Supabase project.
create table if not exists public.subscription_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  store text not null check (store in ('google_play', 'app_store')),
  product_id text not null,
  original_transaction_id text not null,
  status text not null check (status in ('active', 'in_grace_period', 'expired', 'revoked', 'billing_retry')),
  started_at timestamptz,
  expires_at timestamptz,
  auto_renew_enabled boolean,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create unique index if not exists subscription_entitlements_store_original_idx
  on public.subscription_entitlements (store, original_transaction_id);
create index if not exists subscription_entitlements_status_expiry_idx
  on public.subscription_entitlements (status, expires_at);

-- Store tokens are sensitive. They are only read/written by Edge Functions
-- using the server-side service role and must never be exposed to Flutter.
create table if not exists public.subscription_store_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  store text not null check (store in ('google_play', 'app_store')),
  product_id text not null,
  transaction_id text not null,
  original_transaction_id text not null,
  purchase_token text,
  status text not null,
  expires_at timestamptz,
  verified_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (store, transaction_id),
  unique (store, purchase_token)
);

create index if not exists subscription_store_transactions_owner_idx
  on public.subscription_store_transactions (user_id, store);
create index if not exists subscription_store_transactions_original_idx
  on public.subscription_store_transactions (store, original_transaction_id);

alter table public.subscription_entitlements enable row level security;
alter table public.subscription_store_transactions enable row level security;

drop policy if exists "Users can read their subscription entitlement"
  on public.subscription_entitlements;
create policy "Users can read their subscription entitlement"
  on public.subscription_entitlements
  for select to authenticated
  using (user_id = (select auth.uid()));

-- Deliberately no client write policy for either table. Service-role Edge
-- Functions bypass RLS after verifying a transaction with its store.
revoke insert, update, delete on public.subscription_entitlements
  from anon, authenticated;
revoke all on public.subscription_store_transactions
  from anon, authenticated;
grant select on public.subscription_entitlements to authenticated;
