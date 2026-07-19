-- VITA — Migración 0009
-- 1) Saldar el reparto por GASTO (no por fecha). Saldar por fecha ocultaba los
--    gastos que se anotan con fecha vieja (ej. junio). Ahora cada gasto
--    compartido tiene su propia marca de "ya saldado".
-- 2) Nuevo tipo de movimiento 'pago_tarjeta': pagar una tarjeta de crédito
--    (sale de una cuenta y baja la deuda de la tarjeta).
-- Idempotente.

-- Deshace el saldado por fecha accidental (para que junio vuelva a contar).
update public.profiles set tricount_saldado_hasta = null;

-- Marca de saldado por gasto compartido.
alter table public.finance_transactions
  add column if not exists tricount_saldado boolean not null default false;

-- Permitir el tipo 'pago_tarjeta'.
alter table public.finance_transactions
  drop constraint if exists finance_transactions_tipo_check;
alter table public.finance_transactions
  add constraint finance_transactions_tipo_check
  check (tipo in ('gasto', 'ingreso', 'pago_tarjeta'));

-- Motor de saldos: ahora también entiende 'pago_tarjeta'.
--   gasto        desde cuenta  → cuenta baja
--   pago_tarjeta desde cuenta  → cuenta baja
--   ingreso      a cuenta      → cuenta sube
--   gasto        con tarjeta   → deuda de la tarjeta sube
--   ingreso/pago con tarjeta   → deuda de la tarjeta baja
create or replace function public.finance_tx_saldo()
returns trigger language plpgsql as $$
declare
  d numeric;
begin
  if (tg_op = 'UPDATE' or tg_op = 'DELETE') then
    if old.cuenta_id is not null then
      d := case when old.tipo = 'ingreso' then old.monto else -old.monto end;
      update public.finance_accounts set saldo = saldo - d where id = old.cuenta_id;
    end if;
    if old.tarjeta_id is not null then
      d := case when old.tipo = 'gasto' then old.monto else -old.monto end;
      update public.finance_cards set saldo_deuda = saldo_deuda - d where id = old.tarjeta_id;
    end if;
  end if;

  if (tg_op = 'INSERT' or tg_op = 'UPDATE') then
    if new.cuenta_id is not null then
      d := case when new.tipo = 'ingreso' then new.monto else -new.monto end;
      update public.finance_accounts set saldo = saldo + d where id = new.cuenta_id;
    end if;
    if new.tarjeta_id is not null then
      d := case when new.tipo = 'gasto' then new.monto else -new.monto end;
      update public.finance_cards set saldo_deuda = saldo_deuda + d where id = new.tarjeta_id;
    end if;
  end if;

  return null;
end $$;
