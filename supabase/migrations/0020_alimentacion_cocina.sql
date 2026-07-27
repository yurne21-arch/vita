-- 0020 · Alimentación — sesión de cocción de la semana.
-- Registra cuándo la usuaria cocinó el meal prep de una semana. Una fila por
-- semana (lunes). Forward-only; la fecha la fija ella desde "Cocina de la semana".

create table if not exists public.nutrition_cocina_sesion (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users (id) on delete cascade,
  semana_inicio date not null,               -- lunes de la semana cocinada
  cocinada_at   timestamptz,                 -- cuándo cocinó (null = pendiente)
  nota          text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (user_id, semana_inicio)
);

alter table public.nutrition_cocina_sesion enable row level security;

drop policy if exists cocina_sesion_rw on public.nutrition_cocina_sesion;
create policy cocina_sesion_rw on public.nutrition_cocina_sesion
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop trigger if exists trg_cocina_sesion_touch on public.nutrition_cocina_sesion;
create trigger trg_cocina_sesion_touch
  before update on public.nutrition_cocina_sesion
  for each row execute function public.nutrition_touch_updated_at();
