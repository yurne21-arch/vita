-- VITA — Migración 0002
-- Dominios del MVP: hábitos, salud, prioridades, agenda y proyectos.
--
-- Estas 12 tablas se habían creado a mano desde el panel de Supabase y no
-- estaban versionadas. Esta migración las declara tal como existen hoy en
-- `vita-dev`, para que la base pueda reconstruirse desde cero.
--
-- Es idempotente (`if not exists` / `or replace` / `drop ... if exists`), así
-- que puede aplicarse sobre una base que ya las tenga sin romper nada.
--
-- Nota sobre append-only: en las tablas `_events` no se declaran políticas de
-- UPDATE ni DELETE. Con RLS activa, lo que no tiene política queda denegado,
-- así que el historial no se puede reescribir.

-- ═══════════════════════════════════════════════════════════════
-- FUNCIONES DE APOYO
-- ═══════════════════════════════════════════════════════════════

-- Marca `updated_at` en cada edición.
create or replace function public.dp_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

create or replace function public.events_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

create or replace function public.projects_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end; $$;

-- Regla de negocio: máximo 3 prioridades por día.
create or replace function public.dp_max_tres()
returns trigger language plpgsql as $$
begin
  if (select count(*) from public.daily_priorities
      where user_id = new.user_id and fecha = new.fecha) >= 3 then
    raise exception 'Máximo 3 prioridades por día';
  end if;
  return new;
end; $$;

-- Estampa la fecha al completar un paso; la limpia al descompletarlo.
create or replace function public.project_tasks_complete_stamp()
returns trigger language plpgsql as $$
begin
  if new.completada and new.completada_at is null then
    new.completada_at := now();
  elsif not new.completada then
    new.completada_at := null;
  end if;
  return new;
end; $$;

-- Regla de negocio: un solo proyecto principal, y solo si está activo.
create or replace function public.projects_principal_guard()
returns trigger language plpgsql as $$
begin
  -- un proyecto no activo no puede ser principal
  if new.estado is distinct from 'activo' then
    new.es_principal := false;
  end if;

  -- estampar/limpiar completado_at según estado (se conserva al archivar un completado)
  if new.estado = 'completado' and new.completado_at is null then
    new.completado_at := now();
  elsif new.estado in ('activo','pausado') then
    new.completado_at := null;
  end if;

  -- garantizar un solo principal: degradar los demás de la misma usuaria
  if new.es_principal then
    update public.projects
       set es_principal = false
     where user_id = new.user_id
       and id <> new.id
       and es_principal;
  end if;

  return new;
end; $$;

-- ═══════════════════════════════════════════════════════════════
-- HÁBITOS
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.habitos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  nombre      text not null,
  emoji       text,
  hora        text,
  orden       integer not null default 0,
  activo      boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (user_id, nombre)
);

create table if not exists public.habitos_log (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  habito_id   uuid not null references public.habitos (id) on delete cascade,
  fecha       date not null,
  hecho       boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (habito_id, fecha)
);

alter table public.habitos     enable row level security;
alter table public.habitos_log enable row level security;

drop policy if exists habitos_own on public.habitos;
create policy habitos_own on public.habitos for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists habitos_log_own on public.habitos_log;
create policy habitos_log_own on public.habitos_log for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- SALUD — tablas de eventos (append-only)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.weight_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  fecha       date not null default current_date,
  valor       numeric not null check (valor > 0 and valor < 500),
  created_at  timestamptz not null default now()
);

create table if not exists public.energy_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  fecha       date not null default current_date,
  valor       smallint not null check (valor >= 1 and valor <= 5),
  created_at  timestamptz not null default now()
);

create table if not exists public.mood_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  fecha       date not null default current_date,
  valor       smallint not null check (valor >= 1 and valor <= 5),
  created_at  timestamptz not null default now()
);

create table if not exists public.sleep_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  fecha       date not null default current_date,
  valor       numeric check (valor >= 0 and valor <= 24),
  created_at  timestamptz not null default now(),
  calidad     smallint check (calidad >= 1 and calidad <= 3)
);

create index if not exists weight_events_user_fecha_idx
  on public.weight_events (user_id, fecha, created_at desc);
create index if not exists energy_events_user_fecha_idx
  on public.energy_events (user_id, fecha, created_at desc);
create index if not exists mood_events_user_fecha_idx
  on public.mood_events (user_id, fecha, created_at desc);
create index if not exists sleep_events_user_fecha_idx
  on public.sleep_events (user_id, fecha, created_at desc);

alter table public.weight_events enable row level security;
alter table public.energy_events enable row level security;
alter table public.mood_events   enable row level security;
alter table public.sleep_events  enable row level security;

-- Solo SELECT e INSERT: sin política de UPDATE/DELETE, RLS los deniega.
drop policy if exists weight_select_own on public.weight_events;
create policy weight_select_own on public.weight_events for select
  using (auth.uid() = user_id);
drop policy if exists weight_insert_own on public.weight_events;
create policy weight_insert_own on public.weight_events for insert
  with check (auth.uid() = user_id);

drop policy if exists energy_select_own on public.energy_events;
create policy energy_select_own on public.energy_events for select
  using (auth.uid() = user_id);
drop policy if exists energy_insert_own on public.energy_events;
create policy energy_insert_own on public.energy_events for insert
  with check (auth.uid() = user_id);

drop policy if exists mood_select_own on public.mood_events;
create policy mood_select_own on public.mood_events for select
  using (auth.uid() = user_id);
drop policy if exists mood_insert_own on public.mood_events;
create policy mood_insert_own on public.mood_events for insert
  with check (auth.uid() = user_id);

drop policy if exists sleep_select_own on public.sleep_events;
create policy sleep_select_own on public.sleep_events for select
  using (auth.uid() = user_id);
drop policy if exists sleep_insert_own on public.sleep_events;
create policy sleep_insert_own on public.sleep_events for insert
  with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- PRIORIDADES DEL DÍA (máximo 3)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.daily_priorities (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  fecha       date not null default current_date,
  texto       text not null,
  orden       smallint not null check (orden >= 1 and orden <= 3),
  completada  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists daily_priorities_user_fecha_idx
  on public.daily_priorities (user_id, fecha, orden);

drop trigger if exists dp_max_tres_trg on public.daily_priorities;
create trigger dp_max_tres_trg before insert on public.daily_priorities
  for each row execute function public.dp_max_tres();

drop trigger if exists dp_touch_trg on public.daily_priorities;
create trigger dp_touch_trg before update on public.daily_priorities
  for each row execute function public.dp_touch_updated_at();

alter table public.daily_priorities enable row level security;

drop policy if exists dp_select_own on public.daily_priorities;
create policy dp_select_own on public.daily_priorities for select
  using (auth.uid() = user_id);
drop policy if exists dp_insert_own on public.daily_priorities;
create policy dp_insert_own on public.daily_priorities for insert
  with check (auth.uid() = user_id);
drop policy if exists dp_update_own on public.daily_priorities;
create policy dp_update_own on public.daily_priorities for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists dp_delete_own on public.daily_priorities;
create policy dp_delete_own on public.daily_priorities for delete
  using (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- AGENDA
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.events (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  titulo       text not null,
  descripcion  text,
  inicio       timestamptz not null,
  fin          timestamptz,
  todo_el_dia  boolean not null default false,
  estado       text not null default 'pendiente'
                 check (estado in ('pendiente', 'realizado', 'cancelado')),
  categoria    text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  importancia  text not null default 'normal'
                 check (importancia in ('normal', 'importante', 'critico')),
  constraint events_fin_despues_inicio check (fin is null or fin >= inicio)
);

create table if not exists public.event_reminders (
  id          uuid primary key default gen_random_uuid(),
  event_id    uuid not null references public.events (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  offset_min  integer not null,
  created_at  timestamptz not null default now()
);

create index if not exists events_user_inicio_idx
  on public.events (user_id, inicio);
create index if not exists event_reminders_event_idx
  on public.event_reminders (event_id);

drop trigger if exists events_touch_trg on public.events;
create trigger events_touch_trg before update on public.events
  for each row execute function public.events_touch_updated_at();

alter table public.events          enable row level security;
alter table public.event_reminders enable row level security;

drop policy if exists events_select_own on public.events;
create policy events_select_own on public.events for select
  using (auth.uid() = user_id);
drop policy if exists events_insert_own on public.events;
create policy events_insert_own on public.events for insert
  with check (auth.uid() = user_id);
drop policy if exists events_update_own on public.events;
create policy events_update_own on public.events for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists events_delete_own on public.events;
create policy events_delete_own on public.events for delete
  using (auth.uid() = user_id);

drop policy if exists er_select_own on public.event_reminders;
create policy er_select_own on public.event_reminders for select
  using (auth.uid() = user_id);
drop policy if exists er_insert_own on public.event_reminders;
create policy er_insert_own on public.event_reminders for insert
  with check (auth.uid() = user_id);
drop policy if exists er_update_own on public.event_reminders;
create policy er_update_own on public.event_reminders for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists er_delete_own on public.event_reminders;
create policy er_delete_own on public.event_reminders for delete
  using (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- PROYECTOS
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.projects (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null default auth.uid()
                     references auth.users (id) on delete cascade,
  titulo           text not null,
  descripcion      text,
  objetivo         text,
  area             text,
  estado           text not null default 'activo'
                     check (estado in ('activo', 'pausado', 'completado', 'archivado')),
  es_principal     boolean not null default false,
  fecha_objetivo   date,
  progreso_manual  smallint check (progreso_manual >= 0 and progreso_manual <= 100),
  orden            smallint not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  completado_at    timestamptz,
  constraint projects_principal_activo
    check (not es_principal or estado = 'activo')
);

create table if not exists public.project_tasks (
  id              uuid primary key default gen_random_uuid(),
  project_id      uuid not null references public.projects (id) on delete cascade,
  user_id         uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  texto           text not null,
  tipo            text not null default 'paso' check (tipo in ('paso', 'hito')),
  completada      boolean not null default false,
  orden           smallint not null default 0,
  fecha_objetivo  date,
  evento_id       uuid references public.events (id) on delete set null,
  created_at      timestamptz not null default now(),
  completada_at   timestamptz
);

create table if not exists public.project_log (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references public.projects (id) on delete cascade,
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  task_id     uuid references public.project_tasks (id) on delete set null,
  fecha       timestamptz not null default now(),
  tipo        text not null default 'avance'
                check (tipo in ('creado', 'avance', 'nota', 'hito_completado', 'cambio_estado')),
  texto       text,
  created_at  timestamptz not null default now()
);

-- Un solo proyecto principal por usuaria (respaldo del trigger).
create unique index if not exists projects_un_principal
  on public.projects (user_id) where es_principal;
create index if not exists projects_user_estado_idx
  on public.projects (user_id, estado, orden);
create index if not exists project_tasks_proj_idx
  on public.project_tasks (project_id, orden);
create index if not exists project_log_proj_idx
  on public.project_log (project_id, fecha desc);

drop trigger if exists projects_touch on public.projects;
create trigger projects_touch before update on public.projects
  for each row execute function public.projects_touch_updated_at();

drop trigger if exists projects_guard on public.projects;
create trigger projects_guard before insert or update on public.projects
  for each row execute function public.projects_principal_guard();

drop trigger if exists project_tasks_stamp on public.project_tasks;
create trigger project_tasks_stamp before insert or update on public.project_tasks
  for each row execute function public.project_tasks_complete_stamp();

alter table public.projects      enable row level security;
alter table public.project_tasks enable row level security;
alter table public.project_log   enable row level security;

drop policy if exists projects_select_own on public.projects;
create policy projects_select_own on public.projects for select
  using (auth.uid() = user_id);
drop policy if exists projects_insert_own on public.projects;
create policy projects_insert_own on public.projects for insert
  with check (auth.uid() = user_id);
drop policy if exists projects_update_own on public.projects;
create policy projects_update_own on public.projects for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists projects_delete_own on public.projects;
create policy projects_delete_own on public.projects for delete
  using (auth.uid() = user_id);

drop policy if exists project_tasks_select_own on public.project_tasks;
create policy project_tasks_select_own on public.project_tasks for select
  using (auth.uid() = user_id);
drop policy if exists project_tasks_insert_own on public.project_tasks;
create policy project_tasks_insert_own on public.project_tasks for insert
  with check (auth.uid() = user_id);
drop policy if exists project_tasks_update_own on public.project_tasks;
create policy project_tasks_update_own on public.project_tasks for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists project_tasks_delete_own on public.project_tasks;
create policy project_tasks_delete_own on public.project_tasks for delete
  using (auth.uid() = user_id);

-- Bitácora: append-only (sin UPDATE/DELETE).
drop policy if exists project_log_select_own on public.project_log;
create policy project_log_select_own on public.project_log for select
  using (auth.uid() = user_id);
drop policy if exists project_log_insert_own on public.project_log;
create policy project_log_insert_own on public.project_log for insert
  with check (auth.uid() = user_id);
