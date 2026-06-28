-- VITA — Migración 0001 (Sprint 0)
-- Cimientos de datos: perfil de usuaria, RLS y Storage privado.
-- Filosofía: cada tabla nace con RLS; la usuaria solo accede a lo suyo.

-- ───────────────────────────────────────────────────────────────
-- profiles
-- ───────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id                  uuid primary key references auth.users (id) on delete cascade,
  display_name        text,
  locale              text not null default 'es-CL',
  currency            text not null default 'CLP',
  measurement_system  text not null default 'metric',
  created_at          timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- La usuaria solo ve, crea y edita su propio perfil.
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ───────────────────────────────────────────────────────────────
-- Alta automática de perfil al registrarse
-- ───────────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ───────────────────────────────────────────────────────────────
-- Storage: bucket privado (vacío en el Sprint 0)
-- ───────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('private', 'private', false)
on conflict (id) do nothing;

-- Solo el dueño accede a sus objetos del bucket privado.
create policy "private_objects_owner_all"
  on storage.objects for all
  using (bucket_id = 'private' and owner = auth.uid())
  with check (bucket_id = 'private' and owner = auth.uid());
