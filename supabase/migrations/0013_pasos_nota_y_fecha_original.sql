-- VITA — Migración 0013
-- Cada paso/hito puede llevar una nota, y recuerda su fecha ORIGINAL (la que se
-- fijó al principio). Así, si la fecha se mueve, queda registro y se ve la
-- diferencia entre lo planificado y lo real — sin reescribir la historia.
-- El movimiento de fecha se anota además en la bitácora (tipo 'fecha_movida').
-- Idempotente; forward-only.

alter table public.project_tasks
  add column if not exists nota text,
  add column if not exists fecha_objetivo_original date;

-- Semilla: para pasos que YA tienen fecha, su fecha original es la actual.
update public.project_tasks
  set fecha_objetivo_original = fecha_objetivo
  where fecha_objetivo is not null
    and fecha_objetivo_original is null;
