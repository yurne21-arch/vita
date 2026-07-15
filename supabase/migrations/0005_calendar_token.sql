-- VITA — Migración 0005
-- Enlace de calendario suscribible: un token secreto por usuaria para exponer
-- sus eventos como feed iCalendar (.ics), sin login, para suscribir en Google
-- Calendar / Apple Calendar. El token es la única credencial del feed, así que
-- es un uuid impredecible y puede rotarse si se filtra.

alter table public.profiles
  add column if not exists calendar_token uuid not null default gen_random_uuid();

-- Cada token identifica a una sola usuaria.
create unique index if not exists profiles_calendar_token_key
  on public.profiles (calendar_token);
