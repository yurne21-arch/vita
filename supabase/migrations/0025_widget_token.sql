-- 0025 · Token de solo-lectura para el widget (Scriptable en iPhone).
-- El widget no puede iniciar sesión, así que usa un token secreto que lo
-- identifica. Solo la Edge Function (service role) lee esta tabla; la usuaria
-- nunca la toca. RLS sin políticas = nadie más la ve. Forward-only.

create table if not exists public.widget_token (
  token      text primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.widget_token enable row level security;
