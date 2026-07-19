-- VITA — Migración 0011
-- Cartola por cuadre: cada gasto compartido saldado queda ligado al cuadre
-- (settlement) en que se saldó, y cada cuadre guarda su rango de fechas. Así la
-- cartola se genera sola por cuadre, sin que la usuaria elija fechas.
-- Idempotente.

alter table public.finance_transactions
  add column if not exists settlement_id uuid
    references public.finance_settlements (id) on delete set null;

create index if not exists finance_tx_settlement_idx
  on public.finance_transactions (settlement_id) where settlement_id is not null;

alter table public.finance_settlements
  add column if not exists desde date,
  add column if not exists hasta date;

-- Backfill: liga los gastos ya saldados sin cuadre al último cuadre registrado
-- (caso de un solo cuadre; lo suficiente para no perder el historial actual).
update public.finance_transactions t
set settlement_id = (
  select s.id from public.finance_settlements s
  where s.user_id = t.user_id
  order by s.created_at desc limit 1
)
where t.compartido and t.tricount_saldado and t.settlement_id is null
  and exists (select 1 from public.finance_settlements s where s.user_id = t.user_id);

-- Rango de cada cuadre según sus gastos ligados.
update public.finance_settlements s
set desde = sub.mn, hasta = sub.mx
from (
  select settlement_id, min(fecha) mn, max(fecha) mx
  from public.finance_transactions
  where settlement_id is not null
  group by settlement_id
) sub
where sub.settlement_id = s.id;
