-- VITA — Migración 0012
-- Mi Mes: la reflexión mensual que la usuaria escribe (qué salió bien, qué
-- mejorar, foco del próximo mes). El "espejo" del mes (proyectos, salud,
-- hábitos, finanzas, agenda) se calcula al vuelo desde las tablas existentes;
-- lo único que se persiste aquí es lo que ELLA escribe. Una fila por mes.
-- Idempotente.

create table if not exists public.month_reflections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  anno int not null,
  mes int not null check (mes between 1 and 12),
  salio_bien text,
  a_mejorar text,
  foco text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, anno, mes)
);

alter table public.month_reflections enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'month_reflections'
      and policyname = 'month_reflections_owner'
  ) then
    create policy month_reflections_owner
      on public.month_reflections
      for all
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;
end $$;
