-- VITA — Migración 0018
-- Compras de Alimentación con TRAZABILIDAD a Finanzas (forward-only).
--
-- Modelo: una COMPRA = un viaje a un supermercado en una fecha, con su monto.
-- Soporta varias compras por quincena (p. ej. dos supermercados en días
-- distintos). Al marcarla comprada, la app registra el gasto en
-- `finance_transactions` (categoría 'Alimentación') y guarda aquí el id del
-- movimiento (`finance_tx_id`) para dejar el rastro. La integración es **de
-- aquí en adelante**: no toca ni reinterpreta datos pasados de Finanzas.
--
-- Idempotente. RLS por usuaria. Reutiliza nutrition_touch_updated_at() (0017).

-- ═══════════════════════════════════════════════════════════════
-- COMPRA (un viaje al supermercado)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.nutrition_compras (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  tipo           text not null default 'quincenal'
                   check (tipo in ('quincenal', 'reposicion')),
  supermercado   text,                 -- dónde se compra (texto libre)
  fecha          date not null default current_date, -- qué día
  periodo_inicio date,                 -- quincena que cubre
  periodo_fin    date,
  monto          numeric check (monto >= 0), -- total, editable por la usuaria
  estado         text not null default 'planificada'
                   check (estado in ('planificada', 'comprada')),
  finance_tx_id  uuid,                 -- gasto creado en Finanzas (trazabilidad)
  presupuesto    numeric,
  nota           text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists nutrition_compras_user_idx
  on public.nutrition_compras (user_id, fecha desc);

drop trigger if exists nutrition_compras_touch on public.nutrition_compras;
create trigger nutrition_compras_touch before update on public.nutrition_compras
  for each row execute function public.nutrition_touch_updated_at();

alter table public.nutrition_compras enable row level security;
drop policy if exists nutrition_compras_all on public.nutrition_compras;
create policy nutrition_compras_all on public.nutrition_compras for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- ÍTEMS de una compra (con precio y estado por producto)
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.nutrition_compra_items (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  compra_id   uuid not null
                references public.nutrition_compras (id) on delete cascade,
  food_id     uuid references public.nutrition_foods (id) on delete set null,
  nombre      text not null,           -- copia legible
  categoria   text,
  cantidad    numeric,
  unidad      text,                    -- unidad humana: kg · u · litro · paquete
  precio      numeric,                 -- monto del ítem (editable)
  estado      text not null default 'falta'
                check (estado in ('falta', 'en_carro', 'comprado')),
  ya_tengo    boolean not null default false,
  sustituto   text,
  created_at  timestamptz not null default now()
);

create index if not exists nutrition_compra_items_idx
  on public.nutrition_compra_items (user_id, compra_id);

alter table public.nutrition_compra_items enable row level security;
drop policy if exists nutrition_compra_items_all on public.nutrition_compra_items;
create policy nutrition_compra_items_all on public.nutrition_compra_items for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
