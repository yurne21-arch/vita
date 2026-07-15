# VITA_MASTER

Índice operativo de VITA. Orienta rápido; **no reemplaza** las especificaciones
completas en `docs/diseno/`. Cuando esto y un documento fuente choquen, manda el
documento fuente (ver §9 y la jerarquía en el Skill `vita-builder`).

Para *cómo trabajar* en VITA: Skill `vita-builder`. Para *qué es* VITA: este
archivo. Para profundidad: el documento específico del §9.

---

## 1. Qué es VITA

**Sistema Operativo Personal impulsado por IA.** Reduce la carga mental: la IA
**analiza → propone → explica**; la usuaria **decide**. Multiusuario por diseño,
pero hoy con una sola usuaria real (Yurnelly); su perfil es *dato*, no código.

**No es** un gestor de tareas, ni una app de fitness/nutrición/peso, ni un ERP,
ni una app de rachas y puntos. Administra *la vida completa*, no pendientes.

---

## 2. Principios innegociables

Gobiernan cada decisión diaria. (Ley completa: Constitución Técnica.)

1. **Orden de madurez:** primero funciona, luego bonito, luego inteligente,
   luego potente. Nunca se altera.
2. **La vida primero, la productividad después.**
3. **La UX manda.** Cada pantalla: ¿rápida? ¿intuitiva? ¿se entiende en <5 s?
   ¿reduce carga mental? Si falla una, se rediseña antes de seguir.
4. **Una acción primaria por pantalla.** Calma, claridad, control.
5. **Cero culpa, cero urgencia artificial. Sin gamificación** (ni puntos, ni
   medallas, ni rachas, ni marcadores "x de y").
6. **Reversibilidad:** deshacer antes que confirmar cuando se pueda. Nunca
   perder trabajo en silencio.
7. **El sistema desaparece:** personalidad máxima, presencia mínima.
8. **La IA propone, la usuaria decide.** Nada se aplica sin aprobación.
9. **Privacidad y control del usuario.** Sin secretos en el cliente.
10. **Construir solo lo que se usará pronto.** Nada "para el futuro".
11. **Gratis primero:** nada de pago si una alternativa gratuita logra ≥90%.
12. **Cada dato se registra una sola vez.** Todo tiene historial; nada se
    reinicia.

---

## 3. Personalidad y voz

*(No existe un documento de Voz aparte; esta es la fuente operativa. Ver §12.)*

Registro: **sabio sereno + cuidador**. Español neutro cálido. Breve por defecto;
claridad antes que ingenio. Personalidad máxima, presencia mínima.

- Errores: **tranquilos y útiles**, nunca crudos. Se explica qué pasó y qué
  hacer; nunca se muestra una excepción técnica.
- Vacíos: invitan sin exigir ("Empieza con pocos; menos es más").
- **Prohibido:** culpar, apurar, dramatizar, jerga técnica frente a la usuaria,
  frases de relleno, felicitaciones vacías, lenguaje de rachas/marcadores.
- Regla: si una frase no orienta ni tranquiliza, sobra.

---

## 4. Identidad visual

Fuente única: **`app/lib/core/theme/`** (`AppColors`, `AppSpacing`, `AppTheme`).
No inventar valores locales si existe un token.

- Tema **oscuro cálido oliva** (y claro): acento `olive #6B7A4F`; fondo oscuro
  `#14130F`, superficie `#1E1D19`; tinta clara/oscura definidas en `AppColors`.
  Semánticos: `success/warning/danger/info`.
- **Profundidad por superficies**, jerarquía por **tipografía**, color como
  **información** (no decoración). Poco acento, mucho aire. Material 3, pero
  **anti-Material genérico**: nada debe "sentirse Flutter de fábrica".
- Contraste accesible; toques ≥48 dp (usar `IconButton`, no `GestureDetector`
  sobre íconos pequeños).

⚠️ Estado real (ver §12): la fuente **Inter no está aplicada** (usa la de
Material). Los tokens de `app/lib/core/design/tokens/` están **muertos** (cero
imports): **no usarlos**; el sistema vivo es `core/theme/`.

---

## 5. Interacción

*(No existe documento de Interacción aparte; esta es la fuente operativa.)*

- **Respuesta inmediata** a toda acción; UI optimista con reversión visible si
  falla. Calma ≠ lentitud: VITA se siente rápida.
- Duraciones guía: **120 / 200 / 280 ms** (micro / transición / entrada).
- Continuidad espacial, foco visual, conservación de estado y contexto.
- **Silencio como interacción:** si el resultado ya es evidente, no confirmar.
- **Feedback proporcional.** Respetar `reduced motion`. El movimiento orienta y
  confirma; nunca decora.

---

## 6. Arquitectura de producto

**Implementado hoy** (4 pestañas): **Mi Vida** (dashboard: versículo diario,
prioridades ≤3, estado —peso/energía/ánimo/sueño—, agenda del día, proyecto
principal, hábitos), **Proyectos** (≤3 activos, pasos/hitos, bitácora,
principal único), **Calendario/Agenda** (eventos, recordatorios), **Ajustes**
(cuenta, cerrar sesión). Salud y Hábitos viven *dentro* de Mi Vida.

**Aprobado en diseño, no construido** (roadmap): Dios diario (espiritual),
Salud como módulo con evolución/gráficos, Nutrición, Entrenamiento, Ciclo,
Finanzas, Dashboard ejecutivo, Mi Historia (timeline), Familia (andamiaje),
Motor de IA. No inventar módulos fuera de esta lista.

**Corazón futuro:** Context Snapshot (expediente vivo server-side) → Pipeline
único de Propuestas (analizar→proponer→explicar→aceptar/modificar/rechazar).
Detalle: Arquitectura Definitiva y Motor de IA.

---

## 7. Arquitectura técnica

Fuente de verdad: `CLAUDE.md` (raíz) y `docs/diseno/VITA_Arquitectura_Definitiva.md`.

- **Flutter ≥3.24 / Dart ≥3.5.** `flutter_riverpod` (sin codegen), `go_router`,
  `supabase_flutter`. Plataformas: Web (PWA) + Android; iOS vía PWA.
- **Clean Architecture:** `presentación → dominio ← datos`. Dominio Dart puro.
  **Los features nunca se importan entre sí**; se comunican vía `core/`.
- **Supabase** (free): Postgres + RLS + Auth + Storage. Proyecto `vita-dev`
  (`stxnyopihcfhgpizllxg`). Toda tabla con RLS `user_id = auth.uid()`. Tablas
  `_events` **append-only**. Migraciones en `supabase/migrations/`, forward-only.
- **Persistencia local (Drift) desactivada** hoy: sin offline real, fuente de
  verdad = Supabase. Secretos por `--dart-define`, nunca en el repo.

---

## 8. Design System

La **fuente única de verdad visual es el código:** `app/lib/core/theme/`
(colores, espaciado, tema) más los widgets compartidos en `app/lib/core/widgets/`
(`VitaCard`, `ErrorEnTarjeta`, helpers de error). **No inventar componentes,
colores, radios ni espaciados locales si ya existe el equivalente.** VITA
converge hacia un sistema, no acumula variantes. Antes de crear un widget/token,
buscar si ya existe. (No hay un documento de Design System; el código lo es.)

---

## 9. Mapa de documentos

Rutas reales en `docs/`. Leer **solo** el necesario para la tarea (§10).

| Documento | Responde a | Cuándo leerlo |
|---|---|---|
| `diseno/VITA_PRD_Consolidado_v1.md` | Producto y filosofía; qué es / qué no es | Decisiones de producto, alcance |
| `diseno/VITA_Constitucion_Tecnica.md` | Leyes de desarrollo y calidad | Conflictos, dudas de "cómo se hace" |
| `diseno/VITA_Arquitectura_Definitiva.md` | Arquitectura de producto y técnica | Cambios estructurales, puertos |
| `diseno/VITA_Modelo_Base_de_Datos.md` | Modelo de datos completo (futuro incl.) | Tocar esquema, tablas, RLS |
| `diseno/VITA_Motor_de_IA.md` | IA: snapshot, propuestas, 7 guardarraíles | Cualquier trabajo de IA |
| `diseno/VITA_Plan_de_Sprints.md` | Roadmap y "definición de hecho" | Planear qué sigue |
| `diseno/VITA_Adenda_Gratis_Primero.md` | Regla de costo | Proponer dependencias/servicios |
| `adr/0001..0006` | Decisiones cerradas (1 pág c/u) | Verificar una decisión concreta |
| `Guia_Despliegue_Sprint0.md` | Supabase, GitHub Pages, iPhone, Vercel | Desplegar o configurar |
| `VITA_Sprint_0_Plan.md`, `VITA_Consolidacion_Puerta_0.md` | Histórico (previos al código) | Rara vez; contexto de origen |

Voz, Interacción y Design System **no tienen documento**: su fuente operativa
son las §3, §5 y §8 de aquí, más el código.

---

## 10. Contexto progresivo (matriz de tokens)

Cargar el **mínimo**. Casi ninguna tarea necesita más de MASTER + 1 documento.

| Tipo de tarea | Consultar |
|---|---|
| Visual / apariencia | MASTER §4, §8 + `core/theme` |
| Interacción / animación | MASTER §5 + patrón existente en código |
| Copy / mensajes / errores | MASTER §3 |
| Arquitectura / estructura | MASTER §7 + Arquitectura Definitiva |
| Datos / esquema / RLS | MASTER §7 + Modelo de Base de Datos + `supabase/migrations` |
| UX / navegación / pantallas | MASTER §6 + PRD (sección relevante) |
| Decisión filosófica / alcance | PRD + Constitución |
| Módulo de IA | MASTER §6 + Motor de IA |
| Bug / fix acotado | Solo el código afectado |

---

## 11. Decisiones cerradas (no reabrir sin motivo)

- Clean Architecture + feature-first; dominio Dart puro; features aislados.
- Riverpod **sin codegen**. `go_router`.
- Supabase (Postgres + RLS + Auth + Storage). Append-only en `_events`.
- IA **agnóstica del proveedor**, detrás de un puerto; corre en el servidor.
- iPhone **vía PWA** (sin app nativa ni Apple Developer).
- **Gratis primero** / lente de costo.
- Secretos por `--dart-define`.
- Registro cerrado en Supabase (`disable_signup`): una sola usuaria, URL pública.

---

## 12. Pendientes reales (abiertos)

- **Offline:** Drift está desactivado (rompía el arranque en Web); hay que
  reactivarlo con soporte Web correcto. Hoy la app requiere conexión (incumple
  ADR 0003).
- **Proveedor de IA definitivo** sin decidir (Gemini free en dev; capa de pago
  para datos sensibles). Motor de IA aún no construido.
- **`anonKey` deprecado** en `main.dart`: migrar a `publishableKey` con cuidado
  (formato de llave distinto).
- **Fuente Inter** deseada pero no aplicada (usa la de Material).
- **Design system:** los tokens de `core/design/tokens/` están muertos; decidir
  si se borran o se migra a ellos. Hoy el sistema vivo es `core/theme/`.
- **Módulo Salud con evolución/gráficos** no construido (se registra en Mi Vida,
  pero no hay historial visual).
- **`vita-prod`** no creado: hoy se usan datos reales en `vita-dev`.
- **`docs/manuales/`** referenciado en `docs/README.md` pero inexistente.
