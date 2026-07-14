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

Supabase (free tier), PostgreSQL + RLS + Auth + Storage.

- **Toda tabla nace con RLS.** `user_id` en todas las tablas → política directa `user_id = auth.uid()`, sin joins.
- IDs `uuid`, tiempos `timestamptz` (UTC), nombres `snake_case`.
- Las tablas `_events` son **append-only** (solo INSERT/SELECT; se hace `REVOKE UPDATE, DELETE`). El estado actual sale de **vistas**, no de las tablas crudas.
- Migraciones **forward-only**: una migración aplicada **nunca se edita**; si algo cambia, se crea otra (`<timestamp>_<descripcion>.sql`).
- Diseño futuro (Context Snapshot, `proposals`, 7 guardarraíles de IA, niveles de privacidad) → `docs/diseno/`.

## Git

Trunk-based, sin rama `develop`. Ramas `feat/*` y `fix/*`. Conventional Commits en presente (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`). Commits pequeños y atómicos. `main` siempre desplegable; cada cambio entra por PR para que corra la CI.

## ⚠️ Deuda técnica conocida (leer antes de tocar datos)

1. **Faltan migraciones.** El código usa 13 tablas, pero `supabase/migrations/` solo define `profiles`. Estas se crearon a mano en el panel de Supabase y **no están versionadas**:
   `projects` · `project_tasks` · `project_log` · `events` · `event_reminders` · `daily_priorities` · `habitos` · `habitos_log` · `weight_events` · `sleep_events` · `energy_events` · `mood_events`
   → No se puede reconstruir la BD desde cero. Pendiente: volcar el esquema real a una migración `0002_*.sql`.
2. **Drift está desactivado.** `core/data/local/app_database.dart` quedó vacío a propósito: SQLite rompía el arranque en Flutter Web (`reading init`). Hoy **no hay caché offline**; la fuente de verdad es Supabase y la app requiere conexión.
3. **Los docs van por delante del código.** `docs/diseno/` describe Drift, i18n, outbox y motor de IA que aún no existen. El código manda; los docs son el destino, no el estado.
4. **Nombres mezclados es/en** en la BD (`habitos` vs `weight_events`). Unificar al crear la migración 0002.

## Docs

`docs/diseno/` — PRD, Arquitectura, Constitución Técnica, Modelo de Datos, Motor de IA, Plan de Sprints.
`docs/adr/` — 0001 Clean Architecture · 0002 Riverpod · 0003 Offline Drift+Outbox · 0004 IA agnóstica · 0005 iPhone PWA · 0006 Gratis primero.
`docs/Guia_Despliegue_Sprint0.md` — paso a paso de Supabase, GitHub Pages, iPhone y Vercel.
