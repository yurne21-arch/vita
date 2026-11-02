-- 0023 · Recordatorios de hábitos por Telegram.
-- Guarda a qué chat de Telegram enviarle los recordatorios a cada usuaria, y
-- permite activar/desactivar el recordatorio por hábito. El bot token vive como
-- secreto de la Edge Function, no aquí. Forward-only.

-- A dónde enviar (un chat de Telegram por usuaria).
create table if not exists public.notif_telegram (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  chat_id    text not null,
  activo     boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notif_telegram enable row level security;
drop policy if exists notif_telegram_rw on public.notif_telegram;
create policy notif_telegram_rw on public.notif_telegram
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Recordar este hábito (por defecto sí, si tiene una hora válida).
alter table public.habitos
  add column if not exists recordar boolean not null default true;
