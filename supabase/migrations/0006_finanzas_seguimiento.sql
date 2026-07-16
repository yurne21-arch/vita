-- VITA — Migración 0006
-- Seguimiento financiero: cuentas (saldos), pagos de créditos, abonos a metas y
-- cierres de mes. Completa el módulo de Finanzas para llevar el control real del
-- mes: en qué se gasta, cuánto queda en cada cuenta/tarjeta, y qué se avanzó.
-- Idempotente.

-- ═══════════════════════════════════════════════════════════════
-- CUENTAS (saldos de débito, efectivo, etc.)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_accounts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  nombre      text not null,
  titular     text,               -- 'Yurby' | 'Juan' | 'Ambos'
  saldo       numeric not null default 0,
  orden       smallint not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists finance_accounts_touch on public.finance_accounts;
create trigger finance_accounts_touch before update on public.finance_accounts
  for each row execute function public.finanzas_touch_updated_at();

alter table public.finance_accounts enable row level security;
drop policy if exists finance_accounts_all on public.finance_accounts;
create policy finance_accounts_all on public.finance_accounts for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- PAGOS DE CRÉDITOS (cuántas cuotas y montos se han pagado)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_loan_payments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  loan_id     uuid not null references public.finance_loans (id) on delete cascade,
  monto       numeric not null check (monto > 0),
  fecha       date not null default current_date,
  nota        text,
  created_at  timestamptz not null default now()
);

create index if not exists finance_loan_payments_idx
  on public.finance_loan_payments (loan_id, fecha desc);

alter table public.finance_loan_payments enable row level security;
drop policy if exists finance_loan_payments_all on public.finance_loan_payments;
create policy finance_loan_payments_all on public.finance_loan_payments for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- ABONOS A METAS (seguimiento del ahorro)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_goal_contributions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  goal_id     uuid not null references public.finance_goals (id) on delete cascade,
  monto       numeric not null check (monto <> 0),
  fecha       date not null default current_date,
  nota        text,
  created_at  timestamptz not null default now()
);

create index if not exists finance_goal_contributions_idx
  on public.finance_goal_contributions (goal_id, fecha desc);

alter table public.finance_goal_contributions enable row level security;
drop policy if exists finance_goal_contributions_all
  on public.finance_goal_contributions;
create policy finance_goal_contributions_all
  on public.finance_goal_contributions for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- CIERRES DE MES (resumen guardado + pendientes para el otro mes)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_month_closes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  anno        smallint not null,
  mes         smallint not null check (mes between 1 and 12),
  resumen     jsonb,              -- totales y top categorías al cerrar
  pendiente   text,               -- lo que queda para el otro mes
  cerrado_at  timestamptz not null default now(),
  unique (user_id, anno, mes)
);

alter table public.finance_month_closes enable row level security;
drop policy if exists finance_month_closes_all on public.finance_month_closes;
create policy finance_month_closes_all on public.finance_month_closes for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
