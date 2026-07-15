-- VITA — Migración 0004
-- Finanzas completo: incorpora el modelo real de la usuaria (migrado desde su
-- app previa "Finanzas"): tarjetas de crédito, créditos/deudas estructuradas,
-- metas de ahorro, y el eje "quién pagó / compartido" sobre los movimientos
-- (base del reparto tipo Tricount entre Yurby y Juan).
--
-- Amplía lo de 0003 (finance_transactions, finance_budgets, finance_debts) sin
-- romperlo. Idempotente.

-- ═══════════════════════════════════════════════════════════════
-- MOVIMIENTOS: eje "quién pagó" y método de pago
-- ═══════════════════════════════════════════════════════════════

alter table public.finance_transactions
  add column if not exists quien text,          -- 'Yurby' | 'Juan' | 'Ambos' | null
  add column if not exists compartido boolean not null default false,
  add column if not exists metodo text,         -- 'efectivo' | 'tarjeta' | 'cuenta'
  add column if not exists tarjeta text;        -- medio con que se pagó (texto libre)

-- ═══════════════════════════════════════════════════════════════
-- TARJETAS DE CRÉDITO
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_cards (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  nombre       text not null,
  titular      text,                 -- 'Yurby' | 'Juan'
  cupo         numeric not null default 0,
  saldo_deuda  numeric not null default 0,
  cuota_mes    numeric not null default 0,
  dia_cierre   smallint check (dia_cierre between 1 and 31),
  dia_pago     smallint check (dia_pago between 1 and 31),
  orden        smallint not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

drop trigger if exists finance_cards_touch on public.finance_cards;
create trigger finance_cards_touch before update on public.finance_cards
  for each row execute function public.finanzas_touch_updated_at();

alter table public.finance_cards enable row level security;
drop policy if exists finance_cards_all on public.finance_cards;
create policy finance_cards_all on public.finance_cards for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- CRÉDITOS / DEUDAS ESTRUCTURADAS (hipoteca, créditos, etc.)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_loans (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  nombre         text not null,
  cuota_mensual  numeric not null default 0,
  monto_total    numeric not null default 0,
  saldo          numeric,              -- lo que falta (si se conoce)
  fin            text,                 -- 'Abr 2051' (etiqueta libre)
  progreso       smallint check (progreso between 0 and 100),
  orden          smallint not null default 0,
  saldada        boolean not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

drop trigger if exists finance_loans_touch on public.finance_loans;
create trigger finance_loans_touch before update on public.finance_loans
  for each row execute function public.finanzas_touch_updated_at();

alter table public.finance_loans enable row level security;
drop policy if exists finance_loans_all on public.finance_loans;
create policy finance_loans_all on public.finance_loans for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- METAS DE AHORRO (sueños con monto)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.finance_goals (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  label       text not null,
  emoji       text,
  meta_monto  numeric not null default 0,
  ahorrado    numeric not null default 0,
  cumplida    boolean not null default false,
  orden       smallint not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists finance_goals_touch on public.finance_goals;
create trigger finance_goals_touch before update on public.finance_goals
  for each row execute function public.finanzas_touch_updated_at();

alter table public.finance_goals enable row level security;
drop policy if exists finance_goals_all on public.finance_goals;
create policy finance_goals_all on public.finance_goals for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
