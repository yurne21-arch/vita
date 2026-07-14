# CLAUDE.md — VITA

Sistema Operativo Personal impulsado por IA. Reduce la carga mental: la IA **analiza → propone → explica**; la usuaria **decide**. No es una app de tareas, ni fitness, ni un ERP.

Repo: `github.com/yurne21-arch/vita` · Deploy: https://yurne21-arch.github.io/vita/ · Costo objetivo: **$0**

## Stack real (lo que hay en el código hoy)

Flutter ≥3.24 / Dart ≥3.5 · `flutter_riverpod` · `go_router` · `supabase_flutter` · `flutter_lints`.
Sin Drift, sin i18n, sin IA todavía — aunque los docs de diseño los describan (ver *Deuda técnica*).

Plataformas: **Web (PWA)** y Android. iOS **no nativo**: se instala como PWA desde Safari → Añadir a pantalla de inicio.

## Comandos

```bash
cd app
flutter pub get
flutter analyze          # cero warnings en main
flutter test
dart format .            # obligatorio antes de commit

# correr (las llaves NUNCA se commitean)
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY

# build web release
flutter build web --release --base-href "/vita/" --pwa-strategy=none \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Deploy: automático vía `.github/workflows/ci.yaml` en cada push a `main` (analyze → test → build → GitHub Pages). Requiere los secrets `SUPABASE_URL` y `SUPABASE_ANON_KEY` en *Settings → Secrets → Actions*, y *Settings → Pages → Source: GitHub Actions*. El repo debe llamarse `vita` y ser público.

## Estructura

```
app/lib/
  core/     config/ theme/ router/ widgets/ providers.dart
            design/tokens/   ← design system (vita_color, vita_spacing, …)
            data/{remote,local,sync}/   ai/
  features/<dominio>/{presentation,domain,data}/
            auth · profile · mi_vida · proyectos · agenda · salud
supabase/migrations/   docs/{diseno,adr}/
```

## Reglas de arquitectura (no negociables)

- **Clean Architecture:** `presentación → dominio ← datos`. El dominio es **Dart puro**: no importa Flutter ni Supabase.
- **Los features NUNCA se importan entre sí.** Se comunican a través de `core/`.
- Los repositorios devuelven **entidades de dominio**, nunca modelos de BD.
- **Sin lógica de negocio en widgets.** Estado con Riverpod (`Provider`/`Notifier`/`AsyncNotifier`, sin codegen). Nada de estado mutable global suelto.
- Inmutabilidad por defecto (`copyWith`). Siempre `async/await`. Sin `catch` vacíos.
- **Sin secretos en el cliente:** las llaves de IA solo en variables de entorno del servidor (Edge Functions). `SUPABASE_ANON_KEY` es pública por diseño; quien protege es RLS.

## Reglas de producto (Constitución técnica)

1. Construir **solo lo que se usará en los primeros meses**. Nada "para el futuro".
2. Orden de madurez inalterable: **primero funciona, luego bonito, luego inteligente, luego potente.**
3. **La UX manda.** Cada pantalla debe aprobar: ¿es rápida? ¿es intuitiva? ¿se entiende en <5 s? ¿reduce carga mental? Si falla una, se rediseña antes de seguir.
4. **Gratis primero:** prohibido adoptar herramientas de pago si una gratuita logra ≥90% del resultado. Toda dependencia o servicio nuevo se propone con: costo mensual · anual · alternativa gratuita · ventajas · desventajas · cuándo empezar a pagar.
5. **La IA propone, la usuaria decide.** Nada se aplica sin aprobación.
6. Sin gamificación (ni puntos, ni medallas, ni rachas). Nunca generar culpa. Ningún dato se registra dos veces. Toda recomendación se justifica.
7. La personalización vive en **datos y configuración, nunca en código**.

## Base de datos

Supabase (free tier), PostgreSQL + RLS + Auth + Storage. Proyecto: `vita-dev` (ref `stxnyopihcfhgpizllxg`, región sa-east-1).

- **Toda tabla nace con RLS.** `user_id` en todas las tablas → política directa `user_id = auth.uid()`, sin joins.
- IDs `uuid`, tiempos `timestamptz` (UTC), nombres `snake_case`.
- Las tablas `_events` son **append-only**: se declaran solo políticas de SELECT e INSERT. Con RLS activa, lo que no tiene política queda denegado, así que el historial no se puede reescribir.
- Migraciones **forward-only**: una migración aplicada **nunca se edita**; si algo cambia, se crea otra.
- Diseño futuro (Context Snapshot, `proposals`, 7 guardarraíles de IA, niveles de privacidad) → `docs/diseno/`.

Migraciones actuales:

- `0001_init.sql` — `profiles` + RLS + alta automática de perfil + bucket privado de Storage.
- `0002_dominios_mvp.sql` — las 12 tablas del MVP: hábitos (`habitos`, `habitos_log`), salud (`weight_events`, `energy_events`, `mood_events`, `sleep_events`), `daily_priorities`, agenda (`events`, `event_reminders`) y proyectos (`projects`, `project_tasks`, `project_log`). Incluye funciones, triggers, índices y las 35 políticas de RLS.

Reglas de negocio que viven en la BD (triggers): máximo 3 prioridades por día (`dp_max_tres`); un solo proyecto principal y solo si está activo (`projects_principal_guard`, más un índice único parcial de respaldo); estampado de `completada_at` al completar un paso.

`db pull` y `db dump` de la CLI **requieren Docker**, que no está instalado. Para inspeccionar el esquema remoto, usar la Management API:

```bash
curl -s -X POST "https://api.supabase.com/v1/projects/stxnyopihcfhgpizllxg/database/query" \
  -H "Authorization: Bearer $(security find-generic-password -s 'Supabase CLI' -w)" \
  -H "Content-Type: application/json" -d '{"query":"select 1"}'
```

## Git

Trunk-based, sin rama `develop`. Ramas `feat/*` y `fix/*`. Conventional Commits en presente (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`). Commits pequeños y atómicos. `main` siempre desplegable; cada cambio entra por PR para que corra la CI.

## ⚠️ Deuda técnica conocida (leer antes de tocar datos)

1. **Drift está desactivado.** `core/data/local/app_database.dart` quedó vacío a propósito: SQLite rompía el arranque en Flutter Web (`reading init`). Hoy **no hay caché offline**; la fuente de verdad es Supabase y la app requiere conexión.
3. **Los docs van por delante del código.** `docs/diseno/` describe Drift, i18n, outbox y motor de IA que aún no existen. El código manda; los docs son el destino, no el estado.
4. **Nombres mezclados es/en** en la BD (`habitos` vs `weight_events`). Unificar al crear la migración 0002.

## Docs

`docs/diseno/` — PRD, Arquitectura, Constitución Técnica, Modelo de Datos, Motor de IA, Plan de Sprints.
`docs/adr/` — 0001 Clean Architecture · 0002 Riverpod · 0003 Offline Drift+Outbox · 0004 IA agnóstica · 0005 iPhone PWA · 0006 Gratis primero.
`docs/Guia_Despliegue_Sprint0.md` — paso a paso de Supabase, GitHub Pages, iPhone y Vercel.
