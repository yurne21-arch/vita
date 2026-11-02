-- 0024 · Recordatorios por día y a varias horas.
-- El sistema anterior tenía UNA hora por hábito y avisaba todos los días. Esto
-- permite varios recordatorios por hábito, cada uno a su hora, en los días que
-- toque, y con un texto propio (p. ej. "ir a caminar" vs "ejercicio").
-- Forward-only. El bot token y los envíos siguen en la Edge Function.

create table if not exists public.habito_recordatorios (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  habito_id  uuid not null references public.habitos (id) on delete cascade,
  hora       text not null,                         -- "HH:MM" 24h ("05:20", "21:00")
  dias       smallint[] not null default '{}',      -- 1=Lun..7=Dom; vacío = todos los días
  nota       text,                                  -- texto del aviso (opcional; si no, el nombre)
  activo     boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.habito_recordatorios enable row level security;
drop policy if exists habito_recordatorios_rw on public.habito_recordatorios;
create policy habito_recordatorios_rw on public.habito_recordatorios
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create index if not exists habito_recordatorios_user_idx
  on public.habito_recordatorios (user_id) where activo;
