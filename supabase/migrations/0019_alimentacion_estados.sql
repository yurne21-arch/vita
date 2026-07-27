-- VITA — Migración 0019
-- Estado de cada comida del día: si se comió / no se comió, y si se cambió por
-- otra. Permite marcar (comí / no comí) y cambiar una comida por otra de la
-- biblioteca, con guardado real, y reflejarlo en Menú, Hoy y Mi Vida.
--
-- El plan se genera determinista; esta tabla guarda SOLO las decisiones de la
-- usuaria (override) por (fecha, momento). Idempotente. RLS por usuaria.

create table if not exists public.nutrition_meal_state (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  fecha       date not null,
  momento     text not null
                check (momento in ('desayuno', 'almuerzo', 'merienda', 'finde')),
  assembly_id text,                     -- comida elegida (si la cambió)
  estado      text not null default 'planeado'
                check (estado in ('planeado', 'comido', 'no_comido')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, fecha, momento)
);

create index if not exists nutrition_meal_state_user_idx
  on public.nutrition_meal_state (user_id, fecha);

drop trigger if exists nutrition_meal_state_touch on public.nutrition_meal_state;
create trigger nutrition_meal_state_touch before update on public.nutrition_meal_state
  for each row execute function public.nutrition_touch_updated_at();

alter table public.nutrition_meal_state enable row level security;
drop policy if exists nutrition_meal_state_all on public.nutrition_meal_state;
create policy nutrition_meal_state_all on public.nutrition_meal_state for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
