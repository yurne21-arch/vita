-- VITA — Migración 0008
-- Medio de pago en cada movimiento + ajuste automático de saldos.
--
-- Cada gasto/ingreso puede decir de qué cuenta o tarjeta salió (o a cuál entró),
-- y con qué crédito se relaciona (pago de cuota). Un trigger ajusta solo:
--   · gasto desde una cuenta  → esa cuenta baja
--   · ingreso a una cuenta    → esa cuenta sube
--   · gasto con tarjeta        → la deuda de la tarjeta sube
--   · pago/ingreso a tarjeta   → la deuda de la tarjeta baja
-- Al editar o borrar el movimiento, el efecto se revierte. Los movimientos
-- importados (sin medio) no afectan saldos: reflejan el pasado ya cuadrado.
--
-- Idempotente.

alter table public.finance_transactions
  add column if not exists cuenta_id  uuid references public.finance_accounts (id) on delete set null,
  add column if not exists tarjeta_id uuid references public.finance_cards (id) on delete set null,
  add column if not exists loan_id    uuid references public.finance_loans (id) on delete set null;

create index if not exists finance_tx_loan_idx
  on public.finance_transactions (loan_id) where loan_id is not null;

-- Motor de saldos: aplica/revierte el efecto de un movimiento sobre la cuenta
-- o tarjeta indicada. Idempotente por diseño (revierte OLD, aplica NEW).
create or replace function public.finance_tx_saldo()
returns trigger language plpgsql as $$
declare
  d numeric;
begin
  -- Revertir el efecto anterior (en UPDATE y DELETE).
  if (tg_op = 'UPDATE' or tg_op = 'DELETE') then
    if old.cuenta_id is not null then
      d := case when old.tipo = 'ingreso' then old.monto else -old.monto end;
      update public.finance_accounts set saldo = saldo - d where id = old.cuenta_id;
    end if;
    if old.tarjeta_id is not null then
      d := case when old.tipo = 'ingreso' then -old.monto else old.monto end;
      update public.finance_cards set saldo_deuda = saldo_deuda - d where id = old.tarjeta_id;
    end if;
  end if;

  -- Aplicar el efecto nuevo (en INSERT y UPDATE).
  if (tg_op = 'INSERT' or tg_op = 'UPDATE') then
    if new.cuenta_id is not null then
      d := case when new.tipo = 'ingreso' then new.monto else -new.monto end;
      update public.finance_accounts set saldo = saldo + d where id = new.cuenta_id;
    end if;
    if new.tarjeta_id is not null then
      d := case when new.tipo = 'ingreso' then -new.monto else new.monto end;
      update public.finance_cards set saldo_deuda = saldo_deuda + d where id = new.tarjeta_id;
    end if;
  end if;

  return null;
end $$;

drop trigger if exists finance_tx_saldo_trg on public.finance_transactions;
create trigger finance_tx_saldo_trg
  after insert or update or delete on public.finance_transactions
  for each row execute function public.finance_tx_saldo();
