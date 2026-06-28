# VITA

**Sistema Operativo Personal impulsado por IA.** Este repositorio contiene el desarrollo de VITA, comenzando por el **Sprint 0 (Cimientos)**.

> Estado: Sprint 0 — solo los cimientos. Sin IA, sin módulos de producto reales, sin servicios de pago. Costo: **$0**.

## Qué incluye el Sprint 0

- App **Flutter** (Web + Android) con Clean Architecture y Riverpod.
- **PWA** instalable (probada en iPhone vía Safari → "Añadir a pantalla de inicio").
- **Supabase** (capa gratuita): Auth, tabla `profiles` con RLS, bucket de Storage privado.
- **Drift** (base local) + `SyncPort` + outbox **en esqueleto**.
- `AIProviderPort` **vacío** (sin proveedor; la IA llega en sprints posteriores).
- Shell de **5 pestañas** + placeholder de Mi Vida, tema claro/oscuro, i18n base (es).
- **CI** en GitHub Actions y despliegue web gratuito (Vercel).

## Requisitos

- Flutter 3.22+ (canal stable) y Dart 3.4+.
- Cuenta gratuita de Supabase.

## Configuración

1. Instala dependencias y genera el código (Drift + i18n):

   ```bash
   cd app
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

2. Crea un proyecto en Supabase (capa gratuita) y aplica la migración de `supabase/migrations/0001_init.sql`
   (con la CLI de Supabase o desde el editor SQL del panel).

   > **Para probar el login rápido:** en el panel de Supabase, en *Authentication → Sign In / Providers → Email*,
   > desactiva temporalmente "Confirm email". Así `Crear cuenta` inicia sesión de inmediato (sin paso de correo).
   > Puedes reactivarlo más adelante.

3. Ejecuta la app pasando las llaves por `--dart-define` (nunca se guardan en el repo):

   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY
   ```

## Build web (PWA) y despliegue

**Recomendado (automático): GitHub Pages.** El workflow `.github/workflows/ci.yaml` construye y
publica solo en cada push a `main`. Requisitos: el repositorio debe llamarse **`vita`** (para que
`--base-href "/vita/"` coincida) y ser **público** (Pages es gratis solo en repos públicos). Define los
secretos `SUPABASE_URL` y `SUPABASE_ANON_KEY` en *Settings → Secrets and variables → Actions*, y en
*Settings → Pages* elige *Source: GitHub Actions*. La URL final será `https://yurne21-arch.github.io/vita/`.

**Alternativa (privado): Vercel** con build local:

```bash
cd app
flutter build web --release \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Luego se publica `app/build/web` en Vercel (capa gratuita). En el iPhone: abrir la URL en
**Safari → Compartir → Añadir a pantalla de inicio**.

> La guía paso a paso completa (Supabase, GitHub, Pages, iPhone y la alternativa Vercel) está en
> `docs/Guia_Despliegue_Sprint0.md`.

### Offline en Web (opcional, para sprints posteriores)

Para habilitar la base local Drift en Web, agrega `sqlite3.wasm` y `drift_worker.js` a `app/web/`
siguiendo la documentación de `drift_flutter`. En el Sprint 0 el caché local es **best-effort**:
la fuente de verdad es Supabase, así que la app funciona aunque el caché web no esté configurado.

## Estructura

Ver `docs/diseno/` para los documentos de diseño y `docs/adr/` para las decisiones técnicas.

## Costos

Sprint 0: **$0**. Ningún servicio de pago se activa. Cualquier gasto futuro requiere aprobación explícita.
