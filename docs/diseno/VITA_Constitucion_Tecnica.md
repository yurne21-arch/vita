# VITA — Constitución Técnica

*Documento de gobierno del desarrollo. Debe respetarse durante todo el proyecto. Reemplaza cualquier criterio técnico improvisado. Solo tras tu aprobación comienza la programación (Sprint 0). No contiene código.*

---

## 0. Ley permanente (principios que gobiernan toda decisión)

1. **Construir solo lo que se usará en los primeros meses.** Nada "para el futuro" si no aporta valor inmediato. Mejor un producto excelente y pequeño, antes que uno enorme.
2. **Orden de madurez, siempre:** primero **funciona**, luego es **bonito**, luego es **inteligente**, luego es **potente**. Nunca se altera este orden.
3. **La experiencia de usuario manda.** Cada pantalla debe aprobar las cuatro preguntas: ¿Es rápida? ¿Es intuitiva? ¿Se entiende en menos de 5 segundos? ¿Reduce mi carga mental? Si falla una, se rediseña antes de seguir.
4. **Validación continua.** Tras cada sprint, lo usas varios días; solo cuando funciona bien empieza el siguiente.
5. **Cada línea aporta valor real.** Nunca código por ser técnicamente interesante.
6. **Pensado para construirse con IA:** librerías mainstream, nada de frameworks nicho, código claro, arquitectura simple, fácil de entender para cualquier IA.
7. **Gratis primero** (regla vigente): no se adopta nada de pago si una alternativa gratuita logra ≥90% del resultado. Toda herramienta nueva se evalúa con el formato de costo obligatorio.
8. **La IA propone, tú decides.** Ninguna decisión importante se aplica sin tu aprobación.

Estos principios tienen prioridad sobre cualquier estándar de las secciones siguientes en caso de conflicto.

---

## 0.1 Orden de construcción revisado y MVP mínimo (grabado)

**Orden aprobado por ti:** Diseño → Base de datos → Autenticación → **Mi Vida** → Calendario → Salud → Nutrición → Entrenamiento → Proyectos → Dios → y luego el Motor de IA hace cada módulo más inteligente, sprint a sprint.

**MVP mínimo (lo primero que debe funcionar):** iniciar sesión · abrir Mi Vida · registrar peso · registrar entrenamiento · registrar alimentación · registrar proyectos · registrar eventos de calendario · leer el versículo diario · recibir el plan del día.

**Motor de IA por niveles** (cada nivel solo cuando el anterior esté probado):
- **Nivel 1 — Organizadora:** ordena y muestra (arma el plan del día con reglas simples).
- **Nivel 2 — Analítica:** resume tendencias e informes.
- **Nivel 3 — Predictiva:** detecta patrones y se anticipa.
- **Nivel 4 — Casi autónoma:** propone mejoras de forma proactiva (siempre esperando tu aprobación).

Al inicio, "el plan del día" del MVP puede generarse con **reglas deterministas** (Nivel 1 sin LLM). La inteligencia LLM se incorpora después, módulo por módulo.

---

## 1. Estructura completa de carpetas

Monorepo. Flutter feature-first + Clean Architecture. Backend Supabase separado.

```
vita/
├── app/                                  # Aplicación Flutter
│   ├── lib/
│   │   ├── main.dart                     # punto de entrada
│   │   ├── app.dart                      # widget raíz: router + tema
│   │   ├── core/                         # núcleo transversal (compartido)
│   │   │   ├── config/                   # entorno, constantes, flavors
│   │   │   ├── theme/                     # tokens de diseño, claro/oscuro
│   │   │   ├── i18n/                      # localización (idioma, moneda, unidades)
│   │   │   ├── router/                    # navegación dinámica de 5 pestañas
│   │   │   ├── widgets/                   # componentes UI compartidos (tarjeta, botón principal)
│   │   │   ├── data/
│   │   │   │   ├── local/                 # base Drift (SQLite)
│   │   │   │   ├── remote/                # cliente Supabase
│   │   │   │   └── sync/                  # outbox + SyncPort
│   │   │   ├── ai/                        # AIProviderPort + adaptadores (delgados)
│   │   │   └── utils/
│   │   └── features/                      # un paquete por módulo
│   │       ├── mi_vida/
│   │       │   ├── presentation/          # pantallas, widgets, controllers (Riverpod)
│   │       │   ├── domain/                # entidades, casos de uso, interfaces de repositorio
│   │       │   └── data/                  # implementación de repositorio, fuentes, mappers
│   │       ├── salud/
│   │       ├── nutricion/
│   │       ├── entrenamiento/
│   │       ├── ciclo/
│   │       ├── proyectos/
│   │       ├── calendario/
│   │       ├── dios/
│   │       └── finanzas/                  # solo tarjeta básica en el MVP
│   ├── test/                              # refleja la estructura de lib/
│   ├── analysis_options.yaml
│   └── pubspec.yaml
├── supabase/
│   ├── migrations/                        # SQL versionado, forward-only
│   ├── functions/                         # Edge Functions (context-snapshot, propuestas, ciclos)
│   ├── seed/                              # datos semilla (versículos, daily_verse_plan)
│   └── config.toml
├── docs/                                  # documentación viva
│   ├── manuales/                          # los 15 manuales
│   ├── diseno/                            # PRD, arquitectura, modelo de datos, motor IA, sprints, esta constitución
│   ├── adr/                               # registros de decisiones (Architecture Decision Records)
│   └── README.md
├── .github/workflows/                     # CI gratis (GitHub Actions)
├── .gitignore
└── README.md
```

**Regla:** los `features/` nunca se importan entre sí; se comunican a través de `core/` (sobre todo del Context Snapshot). El dominio (`domain/`) es Dart puro: no importa Flutter ni Supabase.

---

## 2. Convenciones de nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos Dart | snake_case | `weight_repository.dart`, `mi_vida_screen.dart` |
| Clases / tipos | PascalCase | `WeightRepository`, `MiVidaScreen` |
| Variables / funciones | camelCase | `currentWeight`, `buildDayPlan()` |
| Constantes | camelCase, `static const` | `static const maxActiveProjects = 3` |
| Providers (Riverpod) | sufijo `Provider` | `weightRepositoryProvider` |
| Tablas BD | snake_case; eventos en plural `_events` | `weight_events`, `proposals` |
| Columnas BD | snake_case; PK `id`; FK `<entidad>_id` | `user_id`, `snapshot_id` |
| Edge Functions | kebab-case (carpeta) | `context-snapshot`, `generate-menu` |
| Migraciones | `<timestamp>_<descripcion>.sql` | `20260701090000_create_weight_events.sql` |
| Ramas Git | `tipo/descripcion-corta` | `feat/mi-vida-plan-dia` |
| Commits | Conventional Commits | `feat: registrar peso en Mi Vida` |

---

## 3. Reglas de programación

1. **Regla de dependencias (Clean Architecture):** presentación → dominio ← datos. El dominio no conoce a nadie de afuera.
2. **Sin lógica de negocio en widgets.** La UI solo muestra y dispara acciones; las reglas viven en casos de uso (`domain`).
3. **Los repositorios devuelven entidades de dominio**, nunca modelos de base de datos. Los mappers viven en `data`.
4. **Inmutabilidad por defecto:** entidades inmutables con `copyWith`. Se permite `freezed` solo si aclara (es mainstream); evitar generación de código innecesaria.
5. **Gestión de estado:** Riverpod. Los controllers exponen estado; nada de estado mutable global suelto.
6. **Manejo de errores:** las fuentes lanzan errores tipados; los controllers los capturan en su frontera y exponen un estado de error claro a la UI. Sin `catch` vacíos.
7. **Asincronía:** siempre `async/await`; nada de bloquear el hilo de UI.
8. **Sin secretos en el cliente:** llaves de IA y servicios solo en variables de entorno del servidor (Edge Functions).
9. **La IA solo inserta propuestas `pending`:** se respeta el permiso de BD solo-`INSERT` en `proposals`; ningún camino de código permite que la IA escriba en dominios o marque `accepted`.
10. **Dependencias nuevas:** solo librerías ampliamente conocidas; cada incorporación pasa por el formato de costo y por la prueba "¿una IA la entiende sin esfuerzo?".

---

## 4. Estándares de calidad

- **Analizador:** `analysis_options.yaml` con `flutter_lints` como base (mainstream). Cero warnings del analizador en `main`.
- **Formato:** `dart format` obligatorio antes de cada commit.
- **Tamaño:** funciones y widgets pequeños y con una sola responsabilidad. Si un archivo crece demasiado, se divide.
- **Puerta UX (bloqueante):** ninguna pantalla se da por terminada si no aprueba las cuatro preguntas de la Ley permanente (rápida, intuitiva, <5 s, reduce carga mental).
- **Presupuestos de rendimiento:** animaciones <300 ms; apertura de Mi Vida fluida; el Dashboard se entiende en <5 min.
- **Accesibilidad:** contraste adecuado, texto escalable, botones grandes, claro/oscuro.
- **Revisión:** aun en solitario, cada cambio se revisa con una checklist (regla de dependencias respetada, sin lógica en UI, pruebas de invariantes, puerta UX) antes de integrarse.

---

## 5. Flujo de trabajo con Git

- **Conventional Commits:** `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`. Mensajes claros y en presente.
- **Commits pequeños y atómicos:** un cambio lógico por commit; nada de "varios arreglos" mezclados.
- **`main` siempre desplegable:** nunca se sube código roto a `main`.
- **Pull Requests hacia ti misma:** cada feature entra por PR (aunque trabajes sola) para tener historial limpio y que la CI corra antes de integrar.
- **Releases etiquetados por sprint:** `v0.1` (Sprint 1), `v0.2`… para poder volver a cualquier punto estable.

---

## 6. Estrategia de ramas

Trunk-based, simple (GitFlow es demasiado pesado para desarrollo en solitario y asistido por IA):

- **`main`** — protegida, siempre desplegable.
- **`feat/*`, `fix/*`** — ramas cortas por tarea de sprint; viven poco y se fusionan rápido a `main` vía PR + CI.
- **Sin rama `develop`.** Menos complejidad, menos retrabajo.
- **Correcciones urgentes:** `fix/*` desde `main`.

---

## 7. Estrategia de migraciones

- **Supabase CLI** con migraciones SQL versionadas y **forward-only**.
- **Una migración applied nunca se edita:** si algo cambia, se crea una migración nueva (coherente con la filosofía append-only del propio producto).
- **Flujo:** se prueba en local (`supabase start`) → se valida → se aplica a remoto.
- **RLS dentro de las migraciones:** cada tabla nace con su política; ninguna tabla sin RLS.
- **Semillas separadas** (`supabase/seed/`): versículos y `daily_verse_plan` se cargan como datos semilla, no como migración de esquema.
- **Proyectos separados dev/prod:** entornos distintos (además, evita el "billing trap" de capas gratuitas que se activan por proyecto).

---

## 8. Estrategia de pruebas

Pirámide adaptada a velocidad de MVP. **No se persigue cobertura por cobertura**; se prueba lo que protege el producto.

- **Pruebas unitarias (obligatorias) para invariantes y reglas de negocio:** límite de ≤3 proyectos activos, enforcement append-only (no UPDATE/DELETE), constructor de Context Snapshot, ciclo de vida de propuestas y los 7 guardarraíles, restricciones alimentarias como límites duros.
- **Pruebas de widget** para las pantallas críticas (empezando por Mi Vida).
- **Pruebas de integración** mínimas para el lazo snapshot → propuesta → aceptar → aplica.
- **Regla:** toda regla de negocio nueva nace con su prueba. La UI trivial no se sobre-prueba al inicio.
- **CI:** en cada push, GitHub Actions corre `analyze` + `test` (gratis).

---

## 9. Estrategia de despliegue

| Destino | Herramienta | Costo |
|---|---|---|
| Backend | Supabase (proyecto gratuito; dev y prod separados) | **$0** |
| Android | Build APK / canal de pruebas internas de Play | **$0** para pruebas |
| Web | Hosting estático gratuito (GitHub Pages / Netlify / Vercel) | **$0** |
| iOS | Requiere **Apple Developer Program** | **de pago** (ver abajo) |
| CI/CD | GitHub Actions (analyze, test, build) | **$0** (capa gratuita amplia) |

**Costo iOS — formato obligatorio:**
- **Costo mensual:** ~$8–9 (prorrateo); **costo anual:** **99 USD** (Apple Developer Program).
- **Alternativa gratuita:** desarrollar y usar en **Android y Web** sin costo durante todo el MVP.
- **Ventaja de pagar:** publicar/instalar en iPhone.
- **Desventaja:** único costo fijo no evitable para iOS.
- **Cuándo empezar a pagar:** solo cuando realmente necesites VITA en iPhone. Para el MVP, **Android + Web cubren todo gratis**.

Releases: una versión etiquetada y probada por sprint; `main` siempre instalable.

---

## 10. Estándares de documentación

- **README** en la raíz: qué es VITA, cómo instalar y correr (app y Supabase), cómo contribuir.
- **`docs/` como documentación viva:** los 15 manuales, los documentos de diseño (PRD, arquitectura, modelo de datos, motor de IA, sprints) y esta constitución. Si la realidad diverge del diseño, se actualiza el documento.
- **ADRs (`docs/adr/`):** cada decisión técnica importante se registra en una página breve (contexto · decisión · consecuencias). Ejemplos ya tomados: Riverpod, Drift+Outbox, IA agnóstica, gratis-primero.
- **Comentarios de documentación** en las APIs públicas del dominio y en los puertos (`SyncPort`, `AIProviderPort`).
- **CHANGELOG** por sprint: qué se agregó, cambió o corrigió.
- **Regla:** la documentación se escribe pensando en que cualquier IA o persona entienda el proyecto rápido (coherente con la Ley permanente nº 6).

---

## Resumen de costo de toda la Constitución

El desarrollo y la operación del MVP son **$0**, con dos únicos gastos posibles, ambos opcionales y diferidos:
1. **IA sobre datos reales sensibles** (~<1–3 USD/mes), a decidir cuando el MVP funcione.
2. **Apple Developer Program** (99 USD/año), solo si necesitas iOS; Android y Web son gratis.

---

## Decisión que requiere tu visto bueno

¿Apruebas esta **Constitución Técnica** tal como está, o quieres ajustar algún estándar (estructura de carpetas, estrategia de ramas, de pruebas, de despliegue, etc.)?

Al aprobarla, **queda cerrada toda la fase de diseño** y puedo comenzar el **Sprint 0 (Cimientos)** — la primera vez que escribiré código en el proyecto. No antes.
