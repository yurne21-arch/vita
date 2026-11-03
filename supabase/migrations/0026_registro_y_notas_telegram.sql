-- 0026 · Marcar hábitos y anotar observaciones desde Telegram.
-- El aviso trae un botón "✅ Ya lo hice": al tocarlo se marca el hábito del día
-- en habitos_log. Luego la usuaria puede escribir una nota (series, litros,
-- minutos…) que se guarda en ese mismo registro. Forward-only.

-- Observación del día para un hábito (lo que hizo: "4x12", "2 litros", "20 min").
alter table public.habitos_log
  add column if not exists nota text;

-- Hábito que está esperando una nota escrita, por chat de Telegram.
-- Cuando la usuaria toca "✅ Ya lo hice", dejamos aquí el hábito pendiente; su
-- siguiente mensaje de texto se guarda como nota. Solo la Edge Function (service
-- role) lo usa.
create table if not exists public.telegram_pendiente (
  chat_id    text primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  habito_id  uuid not null references public.habitos (id) on delete cascade,
  fecha      date not null,
  created_at timestamptz not null default now()
);

alter table public.telegram_pendiente enable row level security;
