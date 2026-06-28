# VITA — Plan del Sprint 0: Cimientos

*Plan exacto previo a escribir código. Se rige por la Constitución Técnica y las reglas "gratis primero", "lente de costo" y "primero funciona". No contiene código. Solo tras tu aprobación de este plan comienza la programación.*

---

## Evaluación obligatoria: probar VITA en tu iPhone sin pagar

Pediste evaluar la mejor estrategia gratuita o de bajo costo para usar VITA en tu iPhone evitando, si se puede, el Apple Developer Program. Esta es la evaluación:

| Opción | ¿Sirve para tu iPhone? | Costo | Veredicto |
|---|---|---|---|
| **Flutter Web como PWA** (instalada en pantalla de inicio) | **Sí** | **$0** | **Recomendada** |
| Web responsive aparte | Sí, pero sería un segundo código | $0 pero duplica trabajo | Rechazada (rompe "un solo código") |
| Pruebas locales | Solo en tu PC, no en el iPhone con comodidad | $0 | Apoyo durante desarrollo, no para uso diario |
| TestFlight | Sí | **Requiere Apple Developer + una Mac** | Diferida (solo si se justifica) |
| Apple Developer + iOS nativo | Sí, mejor experiencia nativa | **99 USD/año + Mac** | Solo cuando sea imprescindible |

**Recomendación: Flutter Web como PWA.** Desde el mismo código Flutter, generas una versión web instalable. En tu iPhone: Safari → Compartir → "Añadir a pantalla de inicio", y VITA queda como un ícono que abre en modo pantalla completa (standalone). Desde iOS 16.4 (marzo 2023) las PWA añadidas a la pantalla de inicio pueden enviar notificaciones push, y desde iOS 26 todo sitio añadido a la pantalla de inicio se abre por defecto como app web. Como estás en Chile (fuera de la UE), aplica la experiencia completa de PWA. **No requiere Apple Developer, ni TestFlight, ni una Mac. Costo: $0.**

**Matices honestos (los validamos, no los oculto):**
- **Instalación manual:** en iOS no hay aviso automático de instalación; una PWA se instala solo mediante "Añadir a pantalla de inicio" en Safari. Para ti (una sola usuaria) es un gesto único.
- **Almacenamiento offline:** iOS limita el caché (alrededor de 50 MB) y puede borrar los datos almacenados si la app no se usa durante algunas semanas. Esto **no es un problema para VITA** porque la fuente de verdad es Supabase (la nube) y lo local es solo caché: si iOS lo borra, se vuelve a sincronizar. La usarás a diario, así que tampoco se evictará.
- **Notificaciones:** funcionan en la PWA instalada, pero requieren permiso explícito, no admiten push silencioso ni despertar en segundo plano. Para el MVP las notificaciones son mínimas (y el nivel "silenciosa" no usa push). Si más adelante necesitas push crítico muy confiable, esa sería una razón válida para evaluar iOS nativo.
- **Sensación premium:** Flutter Web en Safari puede sentirse algo menos "nativo". Lo medimos con la puerta UX; si no cumple, se ajusta.

**Cuándo pagar Apple Developer (99 USD/año):** solo si más adelante necesitas notificaciones push críticas muy confiables o una experiencia 100% nativa en iPhone, y tras tu aprobación explícita. **Para el Sprint 0 y el MVP: $0.**

---

## 1. Objetivo del sprint

Construir el **espinazo** de VITA: un esqueleto extremo a extremo, a **$0**, que puedas **instalar y abrir en tu iPhone como PWA**, iniciar sesión, y que demuestre que el flujo de datos funciona (escribir y leer un dato con seguridad RLS en Supabase + caché local). **Sin pantallas de producto, sin módulos, sin IA.** Primero que funcione el cimiento.

## 2. Qué se va a construir

- Repositorio en GitHub con la **estructura de carpetas de la Constitución**.
- App **Flutter** que compila en **Web y Android**, con Clean Architecture, Riverpod, tema **claro/oscuro** (tokens base, verde oliva), i18n base (español), y **router con el shell de 5 pestañas vacías** + un placeholder de Mi Vida.
- **PWA** configurada (manifest + service worker) instalable en tu iPhone.
- **Pantalla de login** mínima conectada a **Supabase Auth**.
- **Supabase:** proyecto (capa gratuita) + Auth + tabla `profiles` con **RLS** + bucket de Storage privado.
- **Drift** (base local) + interfaz `SyncPort` + esqueleto de **outbox** (sin lógica de sync compleja).
- **`AIProviderPort` vacío** (solo la interfaz; sin proveedor, sin IA).
- **CI** en GitHub Actions: `analyze` + `test` + `build web`.
- **Despliegue web gratuito** → una URL para abrir en tu iPhone.
- **README + `docs/`** con los 15 manuales, los documentos de diseño y los primeros ADRs.

## 3. Qué NO se va a construir

- Ninguna pantalla de producto real (Mi Vida real, Salud, Nutrición, etc.) — solo el shell vacío.
- **Ninguna IA / LLM.**
- Ningún módulo de dominio completo.
- Sin notificaciones.
- Sin lógica de sincronización compleja (solo el esqueleto del outbox).
- Sin iOS nativo, sin TestFlight, sin Apple Developer.
- **Sin ningún servicio de pago.**
- Sin optimización prematura.

## 4. Estructura inicial del proyecto

El subconjunto del árbol de la Constitución que se crea en este sprint:

```
vita/
├── app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart                 # router + tema
│   │   ├── core/
│   │   │   ├── config/              # entorno (URL/keys por dart-define, NO en repo)
│   │   │   ├── theme/               # tokens, claro/oscuro
│   │   │   ├── i18n/                # español base
│   │   │   ├── router/             # shell de 5 pestañas
│   │   │   ├── widgets/            # tarjeta y botón principal base
│   │   │   ├── data/
│   │   │   │   ├── local/           # Drift
│   │   │   │   ├── remote/          # cliente Supabase
│   │   │   │   └── sync/            # SyncPort + outbox (esqueleto)
│   │   │   └── ai/                  # AIProviderPort (vacío)
│   │   └── features/
│   │       ├── auth/               # login (única feature real del Sprint 0)
│   │       └── mi_vida/            # placeholder
│   ├── test/
│   ├── web/                        # manifest PWA, iconos
│   ├── analysis_options.yaml
│   └── pubspec.yaml
├── supabase/
│   ├── migrations/                 # 0001 profiles + RLS
│   └── config.toml
├── docs/                           # manuales + diseño + adr
├── .github/workflows/ci.yaml
├── .gitignore
└── README.md
```

## 5. Checklist de Supabase

- [ ] Crear proyecto en la **capa gratuita** (región cercana a Chile, p. ej. South America / São Paulo, para menor latencia).
- [ ] Activar **Auth** (correo + OTP).
- [ ] Migración inicial `0001`: tabla `profiles` (id = auth uid, display_name, locale, currency, measurement_system, created_at) con **RLS** (`user_id = auth.uid()`).
- [ ] Crear **bucket de Storage privado** (configurado, vacío).
- [ ] Instalar **Supabase CLI** y correr en local (`supabase init`, `supabase start`).
- [ ] Guardar **URL y anon key** como variables de entorno (vía `--dart-define`), **nunca en el repo**.
- [ ] Dejar el proyecto como **dev** (el de producción se crea aparte más adelante).

## 6. Checklist de Flutter

- [ ] `flutter create` con plataformas **web + android**.
- [ ] Aplicar la **estructura de carpetas** de la Constitución.
- [ ] Añadir dependencias **mainstream y gratuitas**: `flutter_riverpod`, `supabase_flutter`, `drift` + `sqlite3_flutter_libs`, `go_router`, `intl` + `flutter_localizations`.
- [ ] Configurar **tema claro/oscuro** con tokens (verde oliva, tipografía, espaciado).
- [ ] **Router** con shell de 5 pestañas (Mi Vida, Salud, Proyectos, Calendario, Más) — vacías + placeholder de Mi Vida.
- [ ] Configurar **manifest PWA** (nombre "VITA", set de iconos, theme color, `display: standalone`).
- [ ] `analysis_options.yaml` con `flutter_lints`; `dart format`.
- [ ] **Pantalla de login** mínima conectada a Supabase Auth.
- [ ] **Round-trip de prueba:** escribir un `profile` → leerlo desde Supabase y desde el caché local.

## 7. Checklist de GitHub

- [ ] Crear repositorio **privado** (cuenta `yurne21-arch`).
- [ ] Proteger la rama **`main`** (siempre desplegable).
- [ ] `.gitignore` para Flutter + secretos.
- [ ] Adoptar **Conventional Commits**.
- [ ] **GitHub Actions** (`ci.yaml`): `flutter analyze` + `flutter test` + `flutter build web`.
- [ ] **Hosting web gratuito** para el build → URL para tu iPhone.
- [ ] Cargar `docs/` con manuales, documentos de diseño y primeros ADRs (Riverpod, Drift+Outbox, IA agnóstica, gratis-primero, PWA-iOS).

## 8. Decisiones técnicas finales para Sprint 0

- **Router:** `go_router` (mainstream, AI-friendly).
- **iPhone:** **Flutter Web como PWA** (ver evaluación arriba). Sin Apple Developer, sin Mac, $0.
- **Hosting web gratuito:** **Vercel** (capa gratuita; ya lo tienes conectado y maneja bien SPA/PWA). Alternativas igualmente gratis: Netlify o GitHub Pages (que ya usas).
- **Offline:** Drift + `SyncPort` + outbox **en esqueleto** (la lógica completa llega en sprints posteriores).
- **IA:** solo el puerto `AIProviderPort` **vacío**. Cero integración de IA en este sprint.
- **Secretos:** fuera del repo, vía `--dart-define` / variables de entorno.

## 9. Costos del sprint

- **Costo mensual:** **$0.** **Costo anual:** **$0.**
- **Alternativa gratuita:** ya es íntegramente gratuita (Supabase free, Vercel free, GitHub free, Flutter, librerías open source).
- **Ventaja:** producto instalable y probable en tu iPhone sin gastar.
- **Desventaja:** ninguna a este nivel.
- **Cuándo empezar a pagar:** **no en este sprint.** Ningún servicio de pago se activa. Cualquier gasto fijo futuro (IA sobre datos reales, plan de Supabase, Apple Developer) **requerirá tu aprobación explícita**; nada se activa automáticamente.

## 10. Resultado esperado al final del sprint

Una **URL** que abres en tu iPhone con Safari → "Añadir a pantalla de inicio" → **VITA queda instalada como ícono y abre en pantalla completa**. Dentro: **inicias sesión** y ves el **shell de 5 pestañas vacías** con el placeholder de Mi Vida. Un **smoke-test** confirma que un `profile` se escribe y se lee con **RLS** (solo ves lo tuyo) y queda en el **caché local**. Todo **a $0**, instalado en tu iPhone, con el espinazo probado de punta a punta.

## 11. Criterios para aprobar el sprint

- [ ] La app **compila** en Web y Android **sin warnings** del analizador.
- [ ] El **login** funciona (Supabase Auth).
- [ ] **Round-trip de dato con RLS verificado** (la usuaria solo accede a lo suyo).
- [ ] La **PWA se instala y se usa desde tu iPhone** en modo standalone.
- [ ] **CI en verde** (`analyze` + `test` + `build web`).
- [ ] `README`, `docs/` y los primeros **ADRs** presentes.
- [ ] **$0 gastado**; ningún servicio de pago activado.
- [ ] **Puerta UX:** el shell se siente **rápido, limpio y claro en <5 s**, aunque esté vacío.

---

## Decisión que requiere tu visto bueno

¿Apruebas este **Plan del Sprint 0** tal como está —incluida la estrategia **Flutter Web PWA** para tu iPhone y el hosting gratuito en Vercel— o quieres ajustar algo?

Al aprobarlo, **comienzo a escribir código por primera vez en el proyecto**, exactamente dentro de este alcance. No antes, y nunca fuera de lo aquí definido sin avisarte.
