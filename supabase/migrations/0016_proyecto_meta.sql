-- VITA — Migración 0016
-- Vincula cada proyecto con una META (las que ya existen en Finanzas:
-- finance_goals). Una meta agrupa proyectos; al completar un proyecto, la meta
-- muestra su avance ("1 de 2 proyectos"). Sin duplicar el concepto de meta.
-- Idempotente; forward-only.

alter table public.projects
  add column if not exists meta_id uuid
    references public.finance_goals (id) on delete set null;

create index if not exists projects_meta_idx
  on public.projects (meta_id) where meta_id is not null;
