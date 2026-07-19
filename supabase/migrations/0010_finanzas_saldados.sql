-- VITA — Migración 0010
-- Historial de cuadres del reparto compartido. Cada vez que quedan "a mano"
-- (saldan), se guarda un registro con el total repartido y quién le pagó a
-- quién, para tener la historia de lo que se ha ido pagando.
-- Idempotente.

create table if not exists public.finance_settlements (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  fecha           date not null default current_date,
  total_repartido numeric not null default 0,
  puso_yurby      numeric not null default 0,
  puso_juan       numeric not null default 0,
  quien_cobra     text,          -- a quién le debían ('Yurby' | 'Juan' | null si a mano)
  monto_ajuste    numeric not null default 0,
  gastos          smallint not null default 0,  -- cuántos gastos se saldaron
  nota            text,
  created_at      timestamptz not null default now()
);

create index if not exists finance_settlements_idx
  on public.finance_settlements (user_id, fecha desc);

alter table public.finance_settlements enable row level security;
drop policy if exists finance_settlements_all on public.finance_settlements;
create policy finance_settlements_all on public.finance_settlements for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
