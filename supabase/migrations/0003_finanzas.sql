-- VITA — Migración 0003
-- Finanzas personales: movimientos (gastos/ingresos), presupuestos y deudas.
--
-- Filosofía (PRD §8.12): no es contable ni banco. El dinero como medio, no como
-- fin; el presupuesto acompaña, no juzga. A diferencia de las tablas `_events`
-- de salud, estas SÍ son editables/borrables: un gasto mal anotado debe poder
-- corregirse. RLS completa por usuaria en las tres.
--
-- Idempotente: puede aplicarse sobre una base que ya las tenga.

-- ═══════════════════════════════════════════════════════════════
-- FUNCIÓN DE APOYO (updated_at)
-- ═══════════════════════════════════════════════════════════════

create or replace function public.finanzas_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end; $$;

-- ═══════════════════════════════════════════════════════════════
-- MOVIMIENTOS (gastos e ingresos)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  tipo        text not null check (tipo in ('gasto', 'ingreso')),
  monto       numeric not null check (monto > 0),
  categoria   text not null,
  ambito      text not null default 'personal'
                check (ambito in ('personal', 'casa')),
  nota        text,
  fecha       date not null default current_date,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists finance_tx_user_fecha_idx
  on public.finance_transactions (user_id, fecha desc, created_at desc);

drop trigger if exists finance_tx_touch on public.finance_transactions;
create trigger finance_tx_touch before update on public.finance_transactions
  for each row execute function public.finanzas_touch_updated_at();

alter table public.finance_transactions enable row level security;

drop policy if exists finance_tx_select on public.finance_transactions;
create policy finance_tx_select on public.finance_transactions for select
  using (auth.uid() = user_id);
drop policy if exists finance_tx_insert on public.finance_transactions;
create policy finance_tx_insert on public.finance_transactions for insert
  with check (auth.uid() = user_id);
drop policy if exists finance_tx_update on public.finance_transactions;
create policy finance_tx_update on public.finance_transactions for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists finance_tx_delete on public.finance_transactions;
create policy finance_tx_delete on public.finance_transactions for delete
  using (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- PRESUPUESTOS (tope mensual por categoría, opcional)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_budgets (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  categoria      text not null,
  monto_mensual  numeric not null check (monto_mensual >= 0),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (user_id, categoria)
);

drop trigger if exists finance_budget_touch on public.finance_budgets;
create trigger finance_budget_touch before update on public.finance_budgets
  for each row execute function public.finanzas_touch_updated_at();

alter table public.finance_budgets enable row level security;

drop policy if exists finance_budget_all on public.finance_budgets;
create policy finance_budget_all on public.finance_budgets for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- DEUDAS (yo debo / me deben)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_debts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  direccion    text not null check (direccion in ('debo', 'me_deben')),
  persona      text not null,
  monto        numeric not null check (monto > 0),
  descripcion  text,
  saldada      boolean not null default false,
  fecha        date not null default current_date,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists finance_debts_user_idx
  on public.finance_debts (user_id, saldada, fecha desc);

drop trigger if exists finance_debts_touch on public.finance_debts;
create trigger finance_debts_touch before update on public.finance_debts
  for each row execute function public.finanzas_touch_updated_at();

alter table public.finance_debts enable row level security;

drop policy if exists finance_debts_all on public.finance_debts;
create policy finance_debts_all on public.finance_debts for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
