-- VITA — Migración 0017
-- Alimentación Inteligente: perfiles nutricionales + biblioteca por componentes
-- (alimentos → preparaciones base/terminación → ensambles), afinidad, despensa
-- y registro de peso.
--
-- Diseño: docs/diseno/VITA_Alimentacion_Cerebro.md y VITA_Alimentacion_Biblioteca.md.
-- El motor determinista, el planificador, la producción y las compras llegan en
-- una migración posterior, moldeados a la salida real del motor.
--
-- Principios respetados aquí:
--  · Modelo de 3 niveles: alimento → preparación (base|terminación) → ensamble.
--  · Metas por perfil calculadas y AUDITABLES (se guarda fórmula/déficit/motivo).
--    Marcadas `provisional` hasta calcular con el perfil real.
--  · Solo alimentos/ensambles APROBADOS entran al motor; nunca inventa combos.
--
-- Idempotente. RLS completa por usuaria (user_id = auth.uid()).

-- ═══════════════════════════════════════════════════════════════
-- FUNCIÓN DE APOYO (updated_at) — reutiliza patrón de finanzas
-- ═══════════════════════════════════════════════════════════════

create or replace function public.nutrition_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end; $$;

-- ═══════════════════════════════════════════════════════════════
-- 1) PERFILES NUTRICIONALES (Yurby, Juan…) — metas auditables
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.nutrition_profiles (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null default auth.uid()
                          references auth.users (id) on delete cascade,
  nombre                text not null,
  sexo                  text check (sexo in ('femenino', 'masculino')),
  edad                  int  check (edad between 10 and 110),
  estatura_cm           numeric check (estatura_cm between 100 and 230),
  peso_kg               numeric check (peso_kg between 30 and 300),
  objetivo              text not null default 'deficit'
                          check (objetivo in ('deficit', 'mantencion', 'ganancia',
                                              'embarazo', 'lactancia', 'adulto_mayor')),
  actividad             text not null default 'sedentario'
                          check (actividad in ('sedentario', 'ligero', 'moderado', 'activo')),
  ritmo_kg_semana       numeric default 0.4,      -- ritmo deseado (por tendencia)
  -- Cálculo energético (auditable) --------------------------------
  mantenimiento_estimado numeric,                 -- TDEE estimado
  deficit_aplicado      numeric,                  -- kcal restadas/sumadas
  kcal_objetivo         numeric,                  -- meta calórica diaria
  prot_objetivo_g       numeric,                  -- proteína MÍNIMA diaria
  grasa_min_g           numeric,                  -- grasa mínima diaria
  carb_dist_pct         numeric,                  -- % de kcal a carbohidrato (resto)
  kcal_tolerancia_pct   numeric not null default 5, -- ±% para "cerrar" el día
  formula_usada         text,                     -- p.ej. 'Mifflin-St Jeor'
  motivo                text,                     -- motivo del ajuste (auditoría)
  fecha_calculo         date,
  provisional           boolean not null default true,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  unique (user_id, nombre)
);

drop trigger if exists nutrition_profiles_touch on public.nutrition_profiles;
create trigger nutrition_profiles_touch before update on public.nutrition_profiles
  for each row execute function public.nutrition_touch_updated_at();

alter table public.nutrition_profiles enable row level security;
drop policy if exists nutrition_profiles_all on public.nutrition_profiles;
create policy nutrition_profiles_all on public.nutrition_profiles for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- 2) ALIMENTOS (ingredientes) — macros por 100 g, rinde, precio
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.nutrition_foods (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null default auth.uid()
                      references auth.users (id) on delete cascade,
  nombre            text not null,
  categoria         text not null
                      check (categoria in ('proteina', 'carbohidrato', 'verdura',
                                           'fruta', 'lacteo', 'fresco', 'despensa',
                                           'grasa', 'otro')),
  -- Macros por 100 g (o por 100 ml si unidad = ml) ----------------
  kcal_100          numeric not null default 0,
  prot_100          numeric not null default 0,
  carb_100          numeric not null default 0,
  grasa_100         numeric not null default 0,
  fibra_100         numeric not null default 0,
  unidad            text not null default 'g' check (unidad in ('g', 'ml', 'unidad')),
  gramos_por_unidad numeric,                 -- p.ej. 1 huevo ≈ 55 g, 1 arepa ≈ 150 g
  rinde_cocido_pct  numeric,                 -- crudo→cocido (pollo ≈ 70)
  precio_clp        numeric,                 -- pendiente de cargar
  precio_por        text check (precio_por in ('g', 'kg', 'ml', 'l', 'unidad')),
  aprobado          boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (user_id, nombre)
);

create index if not exists nutrition_foods_user_cat_idx
  on public.nutrition_foods (user_id, categoria, nombre);

drop trigger if exists nutrition_foods_touch on public.nutrition_foods;
create trigger nutrition_foods_touch before update on public.nutrition_foods
  for each row execute function public.nutrition_touch_updated_at();

alter table public.nutrition_foods enable row level security;
drop policy if exists nutrition_foods_all on public.nutrition_foods;
create policy nutrition_foods_all on public.nutrition_foods for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- 3) PREPARACIONES (base|terminación) — lo que se cocina en tanda
--    Una terminación deriva de una base (deriva_de) y NO cuenta
--    como producción nueva → así medimos las producciones reales.
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.nutrition_preparations (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid()
                  references auth.users (id) on delete cascade,
  nombre        text not null,
  tipo          text not null default 'base'
                  check (tipo in ('base', 'terminacion')),
  deriva_de     uuid references public.nutrition_preparations (id) on delete set null,
  food_id       uuid references public.nutrition_foods (id) on delete set null,
  frecuencia    text not null default 'frecuente'
                  check (frecuencia in ('favorita_frecuente', 'frecuente', 'ocasional',
                                        'solo_finde', 'antojo_planificado')),
  congelable    boolean not null default false,
  meal_prep     boolean not null default false,
  tiempo_min    int,
  etiquetas     text[] not null default '{}',
  notas         text,
  aprobado      boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (user_id, nombre),
  -- una terminación debe derivar de una base; una base no deriva de nadie
  check ((tipo = 'terminacion' and deriva_de is not null)
         or (tipo = 'base' and deriva_de is null))
);

drop trigger if exists nutrition_preparations_touch on public.nutrition_preparations;
create trigger nutrition_preparations_touch before update on public.nutrition_preparations
  for each row execute function public.nutrition_touch_updated_at();

alter table public.nutrition_preparations enable row level security;
drop policy if exists nutrition_preparations_all on public.nutrition_preparations;
create policy nutrition_preparations_all on public.nutrition_preparations for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- 4) ENSAMBLES (comidas servidas) + sus componentes
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.nutrition_assemblies (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  nombre         text not null,
  momento        text not null
                   check (momento in ('desayuno', 'almuerzo', 'merienda', 'finde')),
  frecuencia     text not null default 'frecuente'
                   check (frecuencia in ('favorita_frecuente', 'frecuente', 'ocasional',
                                         'solo_finde', 'antojo_planificado')),
  etiquetas      text[] not null default '{}',
  estado         text not null default 'ok' check (estado in ('ok', 'ajustar', 'quitar')),
  alternativa_de uuid references public.nutrition_assemblies (id) on delete set null,
  notas          text,
  aprobado       boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (user_id, nombre)
);

create index if not exists nutrition_assemblies_user_momento_idx
  on public.nutrition_assemblies (user_id, momento);

drop trigger if exists nutrition_assemblies_touch on public.nutrition_assemblies;
create trigger nutrition_assemblies_touch before update on public.nutrition_assemblies
  for each row execute function public.nutrition_touch_updated_at();

alter table public.nutrition_assemblies enable row level security;
drop policy if exists nutrition_assemblies_all on public.nutrition_assemblies;
create policy nutrition_assemblies_all on public.nutrition_assemblies for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Componentes de un ensamble: cada uno es una preparación O un alimento suelto.
create table if not exists public.nutrition_assembly_components (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  assembly_id    uuid not null references public.nutrition_assemblies (id) on delete cascade,
  preparation_id uuid references public.nutrition_preparations (id) on delete cascade,
  food_id        uuid references public.nutrition_foods (id) on delete cascade,
  rol            text not null default 'base'
                   check (rol in ('proteina', 'base', 'verdura', 'fresco', 'aliño', 'lacteo', 'fruta')),
  obligatorio    boolean not null default true,
  orden          int not null default 0,
  created_at     timestamptz not null default now(),
  -- exactamente uno: preparación o alimento
  check ((preparation_id is not null) <> (food_id is not null))
);

create index if not exists nutrition_assembly_components_assembly_idx
  on public.nutrition_assembly_components (assembly_id, orden);

alter table public.nutrition_assembly_components enable row level security;
drop policy if exists nutrition_assembly_components_all on public.nutrition_assembly_components;
create policy nutrition_assembly_components_all on public.nutrition_assembly_components for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- 5) AFINIDAD / APRENDIZAJE — por persona, sobre ensamble o preparación
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.nutrition_ratings (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  persona        text not null,                    -- 'Yurby' | 'Juan'
  assembly_id    uuid references public.nutrition_assemblies (id) on delete cascade,
  preparation_id uuid references public.nutrition_preparations (id) on delete cascade,
  rating         text check (rating in ('me_encanta', 'me_gusta', 'me_da_igual',
                                        'solo_ocasional', 'no_me_gusta', 'nunca_sugerir')),
  afinidad       numeric not null default 0,       -- score derivado (aprendizaje)
  veces_sugerido int not null default 0,
  veces_aceptado int not null default 0,
  veces_rechazado int not null default 0,
  ultimo_contexto text,                            -- por qué no se eligió (no siempre rechazo)
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  check ((assembly_id is not null) <> (preparation_id is not null))
);

create unique index if not exists nutrition_ratings_uniq
  on public.nutrition_ratings
     (user_id, persona, coalesce(assembly_id, preparation_id));

drop trigger if exists nutrition_ratings_touch on public.nutrition_ratings;
create trigger nutrition_ratings_touch before update on public.nutrition_ratings
  for each row execute function public.nutrition_touch_updated_at();

alter table public.nutrition_ratings enable row level security;
drop policy if exists nutrition_ratings_all on public.nutrition_ratings;
create policy nutrition_ratings_all on public.nutrition_ratings for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- 6) DESPENSA — qué hay, dónde y hasta cuándo
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.nutrition_pantry (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null default auth.uid()
                      references auth.users (id) on delete cascade,
  food_id           uuid references public.nutrition_foods (id) on delete set null,
  nombre            text not null,                 -- copia legible aunque cambie el food
  cantidad          numeric,
  unidad            text not null default 'g' check (unidad in ('g', 'ml', 'unidad')),
  ubicacion         text not null default 'despensa'
                      check (ubicacion in ('despensa', 'refri', 'congelador')),
  consumir_primero  boolean not null default false,
  fecha_ingreso     date not null default current_date,
  fecha_vencimiento date,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists nutrition_pantry_user_idx
  on public.nutrition_pantry (user_id, ubicacion, fecha_vencimiento);

drop trigger if exists nutrition_pantry_touch on public.nutrition_pantry;
create trigger nutrition_pantry_touch before update on public.nutrition_pantry
  for each row execute function public.nutrition_touch_updated_at();

alter table public.nutrition_pantry enable row level security;
drop policy if exists nutrition_pantry_all on public.nutrition_pantry;
create policy nutrition_pantry_all on public.nutrition_pantry for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- 7) PESO Y PROGRESO — tendencia, no dato aislado
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.nutrition_weight_log (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  persona     text not null,
  fecha       date not null default current_date,
  peso_kg     numeric not null check (peso_kg between 30 and 300),
  nota        text,
  created_at  timestamptz not null default now(),
  unique (user_id, persona, fecha)
);

create index if not exists nutrition_weight_user_idx
  on public.nutrition_weight_log (user_id, persona, fecha desc);

alter table public.nutrition_weight_log enable row level security;
drop policy if exists nutrition_weight_all on public.nutrition_weight_log;
create policy nutrition_weight_all on public.nutrition_weight_log for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
