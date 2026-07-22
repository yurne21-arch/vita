-- VITA — Migración 0015
-- Sincroniza Proyectos ↔ Finanzas SIN módulos aparte:
-- cada paso puede llevar un MONTO. El presupuesto del proyecto es la suma de
-- los montos de sus pasos, y esos montos —por la fecha del paso— se ven en
-- Finanzas → Presupuesto como gasto previsto del mes.
--
-- Se retira el intento anterior (columna presupuesto_materiales del proyecto y
-- project_id en finanzas): quedaba como cajón aparte, no sincronizado.
-- Idempotente; forward-only.

alter table public.project_tasks
  add column if not exists monto numeric;

drop index if exists public.finance_tx_project_idx;

alter table public.finance_transactions
  drop column if exists project_id;

alter table public.projects
  drop column if exists presupuesto_materiales;
