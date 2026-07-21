-- VITA — Migración 0014
-- Cruce Proyectos × Finanzas: un proyecto puede llevar un presupuesto de
-- materiales/compras, y cada gasto de Finanzas puede etiquetarse a un proyecto.
-- Así se ve, por proyecto, cuánto se presupuestó vs cuánto se ha gastado.
-- Idempotente; forward-only.

alter table public.projects
  add column if not exists presupuesto_materiales numeric;

alter table public.finance_transactions
  add column if not exists project_id uuid
    references public.projects (id) on delete set null;

create index if not exists finance_tx_project_idx
  on public.finance_transactions (project_id) where project_id is not null;
