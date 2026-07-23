# VITA — Auditoría integral

**Fecha:** 2026-07-22 · **Build auditada:** `https://yurne21-arch.github.io/vita/` (rama `main`, commit `9b8b58a`)
**Método:** navegador real (Playwright + Chromium 149) sobre el sitio desplegado + inspección de código + comparación con documentación aprobada.
**Cobertura:** 7 rutas · 36 capturas (móvil 390, tablet 768, escritorio 1440, extremos 320/1920) · consola y red registradas en cada ruta.

> **Nota de método sobre autenticación y privacidad.** El producto exige sesión (registro cerrado, una sola usuaria). Para auditar el producto *renderizado* SIN exponer los datos reales de Yurnelly (finanzas, salud) en capturas versionadas — como pide el punto 10 del encargo — se creó un **usuario de auditoría temporal** (`audit-demo@vita.local`) con **datos sintéticos**. Todas las capturas muestran datos inventados. El usuario y sus datos se eliminan al cerrar la auditoría.

> **Nota sobre los documentos citados.** Los "Documento 5 (UX), 6 (Visual), 6.5 (Voz), 6.6 (Interacción), 7 (Design System)" **no existen** como archivos en el repo. Según `VITA_MASTER §9`, esas fuentes viven en el propio MASTER (**§3 Voz, §4 Visual, §5 Interacción, §8 Design System**) más `PRD_Consolidado` y `Constitucion_Tecnica`. La auditoría se hace contra esas fuentes reales + el código (`core/theme`).

> **Limitación técnica declarada.** VITA es Flutter Web con **CanvasKit**: la UI se pinta en un `<canvas>`, no en DOM. Por eso (a) las capturas de "página completa" equivalen al viewport (se capturó *default* + *scroll*); (b) la auditoría de **navegación por teclado, orden de foco, foco visible y semántica accesible** no es observable desde el DOM y se evaluó por código/heurística, no empíricamente. Esto es en sí un hallazgo (ver §8).

---

## 0. Adenda — decisiones del PO y correcciones (2026-07-22)

**Correcciones del informe:**
- **Conteo de prioridades corregido:** **P0 = 0 · P1 = 5 · P2 = 8 · P3 = 4** (17 ítems). Los P1 son **VITA-001, VITA-002, VITA-003, VITA-004, VITA-012** (Inter sube a P1 por ser decisión cerrada del Documento 6). El conteo previo (P1=4) era incorrecto.
- **Rutas:** **7 rutas principales** (`/login`, `/mi-vida`, `/proyectos`, `/mi-mes`, `/calendario`, `/finanzas`, `/ajustes`) + **1 vista dinámica de detalle de proyecto** (`ProyectoDetalleScreen`, abierta por `Navigator.push`, sin ruta propia en `go_router`). Total superficies navegables: 7 + 1 dinámica.

**Decisiones de producto (fuente de verdad = documentación, NO la implementación):**
1. **Tema:** la identidad aprobada sigue siendo **oscuro cálido oliva** (Documento 6). **NO** se adopta el claro salvia+crema como definitivo; **NO** se actualiza `MASTER §4` a la implementación. La implementación migrará gradualmente al Documento 6 (VITA-010) — **diferido**, ver abajo.
2. **Inter:** aprobada e **implementada en Fase 1** (autoalojada, 400/600, Latin+Latin-ext, tabular figures).
3. **Salud:** permanece **dentro de Mi Vida**; sin entrada de navegación; sin infraestructura prematura de separación.
4. **Métricas de salud:** la vista cotidiana habla en **lenguaje humano** ("Energía estable"), no "3/5"; el número se conserva internamente / para históricos y detalle.
5. **Escritorio:** **mobile-first, no mobile-only**; aprovechar el espacio de forma sobria (ancho máximo, columnas solo con contenido real, sin rectángulos vacíos que parezcan contenido faltante).

**Alcance de color en esta fase (instrucción del PO "dejar el color pendiente"):** se ejecuta la Fase 1 **neutral de color** (Inter, hero, CTA duplicada/FAB, paneles vacíos, etiquetas 320 px, reintentar en errores, consolidación estructural de Eyebrow y del botón primario). Se **difieren** los cambios que alteran color/tema: migración a oscuro oliva (VITA-010), recolor de eyebrows para contraste (VITA-002) y recolor del CTA "Nuevo evento" (VITA-004) — se cierran junto con la migración de tema. Las secciones §5/§8/§13 de este informe se leen bajo esta salvedad.

---

## 1. Veredicto ejecutivo

**Qué tan completa:** Alta. Las 7 rutas están **construidas y conectadas a datos reales** (Supabase); no hay pantallas simuladas, botones muertos ni "próximamente". Salud no tiene módulo propio (vive dentro de Mi Vida, por diseño de roadmap) y el Motor de IA es un puerto vacío intencional (`core/ai/ai_provider_port.dart`).

**Qué tan funcional:** Muy alta. **Cero errores de consola y cero solicitudes de red fallidas** en las 7 rutas y 3 breakpoints. Los flujos CRUD principales existen en cada módulo. Un defecto de render en el hero de Proyectos (ver P1) es el único "roto" visible.

**Qué tan coherente:** Media-alta. La voz es excepcional y consistente; el sistema de color/espaciado (`core/theme`) se usa de forma amplia. Pero hay **divergencias sistémicas**: 3 implementaciones de "eyebrow", 2 copias de la paleta de categorías, ~21 colores hardcodeados, 12 radios distintos, y **dos estilos de botón primario** para la misma acción "crear".

**Qué tan cerca de premium:** En móvil/tablet, cerca (paleta cálida marfil+salvia, layout editorial, aire generoso). En **escritorio se aleja**: paneles vacíos enormes y contenido flotando en un mar de crema. Y quedan piezas **Material de fábrica** (indicador tipo píldora del `NavigationBar`, checkmark del `ChoiceChip`, tooltips Material, ripples).

**Qué impide publicarla como "premium":** (1) el defecto del hero de Proyectos; (2) el contraste **fallido** de los eyebrows (2.45:1) presentes en casi toda la app; (3) la **fuente Inter no aplicada** (usa Roboto/Material, que "se siente Flutter"); (4) el vacío del escritorio.

**Mayor riesgo actual:** No hay riesgo de pérdida de datos ni seguridad observable. El mayor riesgo es de **percepción de calidad**: incoherencias visuales sistémicas (eyebrows, botones, Material genérico) que, sumadas, hacen que el producto —que es bueno— se lea como "muy bueno pero no terminado".

**No hay hallazgos P0** (ni pérdida de datos, ni bloqueo, ni crash, ni fallo de seguridad). Esto es, en sí, una señal de madurez del build.

---

## 2. Inventario del producto

| Módulo | Ruta | Estado | ¿Funciona? | Datos | Terminación |
|---|---|---|---|---|---|
| Auth / Login | `/login` | Terminado | Sí | Reales (Supabase Auth) | 95% |
| Mi Vida | `/mi-vida` | Terminado | Sí | Reales (6 repos) | 92% |
| Proyectos | `/proyectos` (+ detalle push) | Terminado c/ defecto | Sí* | Reales | 85% |
| Mi Mes | `/mi-mes` | Terminado | Sí | Reales (derivados) | 92% |
| Calendario | `/calendario` | Terminado | Sí | Reales | 84% |
| Finanzas | `/finanzas` (7 secciones) | Terminado | Sí | Reales | 90% |
| Ajustes | `/ajustes` | Terminado (mínimo por diseño) | Sí | Reales | 90% |
| Salud | — (dentro de Mi Vida) | Parcial por diseño | Sí | Reales | n/a (roadmap) |
| Motor de IA | — | Pendiente (puerto vacío) | — | — | 0% (roadmap) |

*Proyectos funciona, pero el hero "Proyecto principal" renderiza un panel vacío (VITA-001).

Detalle de rutas, overlays y estados: ver **`VITA_SCREEN_INVENTORY.md`**.

---

## 3. Puntuación global

| Categoría | Nota /100 | Sustento (evidencia) |
|---|---|---|
| Producto | 87 | Cada pantalla tiene propósito y valor real; agrega la vida completa. Salud sin módulo propio. |
| UX | 80 | Flujos claros; pero hero roto, CTA duplicada en móvil, callejones vacíos. |
| Visual | 82 | Paleta cálida y jerarquía sólidas; eyebrows de bajo contraste, restos Material, paneles vacíos. |
| Interacción | 76 | Optimista y responsiva; ripples Material, tooltips Material; teclado/foco no observables (canvas). |
| Voz | 90 | Cálida, humana, sin culpa, consistente. Género fijo y algún texto largo. |
| Accesibilidad | 62 | **Eyebrows 2.45:1 FALLAN AA** (sistémico); warning/success texto chico < AA; semántica canvas limitada. |
| Responsive | 78 | Adapta 320→1920 con ancho máximo; etiquetas de nav se parten a 320; paneles vacíos en ancho. |
| Consistencia | 72 | Buen uso de tokens, pero paletas y eyebrows duplicados, 12 radios, 2 estilos de botón primario. |
| Performance percibida | 74 | Consola/red **limpias**; arranque Flutter ~5–6 s en canvas en blanco, wasm CanvasKit pesado, sin splash. |
| Sensación premium | 78 | Premium en móvil/tablet; escritorio vacío y piezas Material la bajan. |
| **GLOBAL** | **≈ 78** | "Funcional y prometedor, pero todavía no premium" (rango 70–79). |

---

## 4. Ranking de módulos (mejor → más débil)

1. **Mi Mes — 85.** Espejo por área limpio, voz impecable, sin marcadores "x de y". Solo asimetría de la rejilla en la última fila.
2. **Mi Vida — 84.** Insignia; jerarquía editorial, 3 layouts responsive reales, todos los estados. Baja por eyebrows y "3/5".
3. **Finanzas — 82.** Profundidad real (7 secciones, dona, cierre de mes, metas cruzadas). Baja por panel SALDOS vacío y chips Material.
4. **Ajustes — 80.** Limpio y honesto; el escritorio queda muy vacío (columna angosta centrada).
5. **Calendario — 74.** Funcional (Hoy/Semana/Mes); panel "Agenda del día" vacío gigante + botón "Nuevo evento" de bajo contraste.
6. **Proyectos — 72.** Excelentes tarjetas y detalle, PERO el hero principal renderiza vacío (VITA-001) y hay CTA "Nuevo proyecto" duplicada en móvil.

(Login ≈ 80: limpio, pero el escritorio queda vacío y el error solo se ve por snackbar.)

---

## 5. Problemas sistémicos (resolver en el Design System, no pantalla por pantalla)

- **S1 · Eyebrows ilegibles.** El estilo "eyebrow" (etiqueta en mayúsculas: `VERSÍCULO DEL DÍA`, `HOY IMPORTA`, `PROYECTO PRINCIPAL`, `EL ESPEJO DEL MES`, `SALDOS`…) usa `AppColors.accentSoft` `#7FA790` a ~11 px. Contraste **2.45:1 sobre página / 2.64:1 sobre tarjeta → FALLA AA** (mínimo 4.5). Aparece en las 7 rutas. Además existe **3 veces** el mismo widget (`Eyebrow` en `proyectos_widgets.dart:201`, `_Eyebrow` en `mi_vida_screen.dart:1285`, `_Eyebrow` en `mi_mes_screen.dart:684`). → Un solo componente `Eyebrow`, con color que pase AA.
- **S2 · Dos botones primarios distintos para "crear".** "Nuevo proyecto"/"Activar recordatorios"/"Avanzar" = relleno salvia oscuro, texto blanco (contraste 4.90 ✓). "Nuevo evento" (Calendario) = relleno salvia pálido, texto salvia (contraste **3.77**, bajo AA). Misma intención, dos tratamientos. → Un único `VitaPrimaryButton`.
- **S3 · Paleta de categorías duplicada.** `catColor` (`calendario_screen.dart:17`) y `areaColor` (`proyectos_widgets.dart:11`) son **la misma** lista de 8 colores en dos archivos; `_paletaCategorias` (`finanzas_screen.dart:32`) re-declara `#4E7A63`/`#4A6B8A`/`#B7860B` que ya son `accent`/`info`/`warning`. → una paleta de dominio en `core/theme`.
- **S4 · Restos Material de fábrica.** Indicador píldora del `NavigationBar`, checkmark del `ChoiceChip` (chips de Finanzas), tooltips Material (`Opciones`), ripples de `InkWell`. Contradice MASTER §4 ("nada debe sentirse Flutter de fábrica").
- **S5 · Estados de error inconsistentes.** `ErrorEnTarjeta` (con "Reintentar") es el estándar, pero Proyectos (`_ErrorPanel`, `proyectos_screen.dart:730`) y Calendario (`_ErrorCarga`, `calendario_screen.dart:376`) muestran texto plano **sin botón de reintentar**.
- **S6 · Valores visuales sueltos.** ~21 colores hardcodeados, **12** radios distintos (`5,6,7,8,9,10,12,14,16,18,20,22`), tamaños de fuente inventados (`9…20`, muchos `11`), paddings numéricos crudos en vez de `AppSpacing`. → tokenizar radios y tamaños.
- **S7 · Fuente Inter ausente.** No hay `GoogleFonts`; el token `vita_typography.fontFamily` es `null` y está muerto. La app usa Roboto/SF del sistema. MASTER §4 pide Inter. Es una causa directa de "se siente Material".
- **S8 · Paneles vacíos en pantallas anchas.** Rejillas de 2 columnas que estiran una tarjeta vacía para igualar la altura de la otra (Calendario "Agenda del día", Finanzas "SALDOS", Mi Vida "TU DÍA"), y columnas angostas centradas en un lienzo enorme (Ajustes, Login) en escritorio.

---

## 6. Hallazgos por módulo

### Mi Vida — 84
- **Funciona:** saludo + fecha, versículo, 3 prioridades (check/undo, ⋮), estado (peso/energía/sueño/ánimo), agenda del día, proyecto principal (con "Avanzar"), hábitos con administración. 3 layouts responsive. Estados completos con `ErrorEnTarjeta`.
- **P1:** eyebrows ilegibles (S1). Evidencia: `mobile/mi-vida__mobile__default.png`.
- **P2:** métricas de salud como `3/5`, `4/5` (marcador "x de y") — tensiona MASTER §5 ("sin marcadores x de y"); el resto de la app ya lo evita (progreso muestra `—`, hábitos muestran "11 días"). "Sueño: Regular" (palabra) vs "Energía: 3/5" (número) = escala inconsistente. Evidencia: `desktop/mi-vida__desktop__default.png`.
- **P2:** en escritorio la tarjeta "TU DÍA" (vacía) se estira para igualar "PROYECTO PRINCIPAL" (S8). Evidencia: `desktop/mi-vida__desktop__scroll.png`.
- **P3:** el wordmark "VITA" queda pegado al borde izquierdo mientras el contenido está indentado y centrado → desalineación en ≥1440. A 320 la fila de salud queda apretada ("68,5 kg ↑3/5" casi se tocan). Evidencia: `states/mi-vida__w320__default.png`, `states/mi-vida__w1920__default.png`.
- **Criterio de aceptación:** eyebrows ≥4.5:1; decidir escala de salud (palabra vs número) y aplicarla a las 4 métricas; TU DÍA no se estira vacía en escritorio.

### Proyectos — 72
- **Funciona:** cartera (principal + Activos/Pausados/Completados), tarjetas con anillo de progreso, chips de estado/área, próximo paso, orden por fecha, detalle completo (pasos/hitos con monto, nota, fecha original, bitácora, presupuesto = suma de montos, aviso de vencido, vínculo con meta).
- **P1 · VITA-001:** el hero "PROYECTO PRINCIPAL" renderiza un **panel grande vacío** con solo una flecha; NO muestran el texto del próximo paso ni el botón "Avanzar", pese a que el mismo dato SÍ aparece en la tarjeta de "Activos" de abajo y en la tarjeta de Mi Vida. Regresión de la queja previa de "la bandera grande". Evidencia: `desktop/proyectos__desktop__default.png`, `mobile/proyectos__mobile__default.png`. Componente: `BarraProximoPaso` dentro de `_HeroPrincipal` (`proyectos_screen.dart`).
- **P2:** en móvil hay **dos** "Nuevo proyecto" (botón ancho en la columna + FAB flotante) → acción primaria duplicada; el FAB además tapa la 2.ª tarjeta. Evidencia: `mobile/proyectos__mobile__default.png`.
- **P2:** error sin "Reintentar" (S5). En escritorio el botón "Nuevo proyecto" ocupa todo el ancho (~1280 px) → CTA sobredimensionada.
- **Criterio de aceptación:** el hero muestra "PRÓXIMO PASO / <texto> / Avanzar" o "Agrega tu primer paso / + Paso"; una sola CTA "Nuevo proyecto" por breakpoint; error con reintentar.

### Mi Mes — 85
- **Funciona:** selector de mes, espejo por área (proyectos/salud/hábitos/finanzas/agenda) con datos derivados reales, reflexión editable persistida. Voz ejemplar ("Te quedó a favor…", "11 días", "Energía buena (3.9)").
- **P2:** eyebrows (S1). En escritorio la rejilla 2×N deja la última celda (a la derecha de "Agenda") vacía. Evidencia: `desktop/mi-mes__desktop__default.png`.
- **P3:** ninguno relevante.
- **Criterio de aceptación:** eyebrows AA; rejilla equilibrada o centrada cuando queda impar.

### Calendario — 74
- **Funciona:** Hoy/Semana/Mes, panel lateral con "Próximo/Ocupado/Libre", agenda del día, hoja del día, editor de evento con date/time pickers, recordatorios `.ics`.
- **P1 (contraste) · VITA-004:** botón "Nuevo evento" con relleno salvia pálido y texto salvia → **3.77:1** (bajo AA) y estilo distinto al resto de CTAs primarias (S2). Evidencia: `desktop/calendario__desktop__default.png`.
- **P2:** en un día sin eventos, "Agenda del día" es un **panel casi de pantalla completa vacío** con un "Día libre" diminuto al centro (S8). Error sin "Reintentar" (S5).
- **Criterio de aceptación:** "Nuevo evento" = botón primario estándar ≥4.5:1; el vacío de "Día libre" no ocupa >~40% de alto en escritorio.

### Finanzas — 82
- **Funciona:** 7 secciones reales (Resumen con dona + saldos + avance de metas + cerrar mes; Movimientos; Presupuesto con previsto-de-proyectos; Tarjetas; Créditos; Metas con avance de proyectos; Cuentas entre personas/Tricount). Export PDF. Todos los estados con `ErrorEnTarjeta`/`_Vacio`.
- **P2:** los chips de sección usan estilo `ChoiceChip` Material (checkmark en el activo) (S4). El panel "SALDOS" queda vacío y grande junto a la dona en escritorio (S8). Evidencia: `desktop/finanzas__desktop__default.png`.
- **P2:** en móvil la fila de chips hace scroll horizontal sin afordancia visible (se corta "Presupuesto"). Evidencia: `mobile/finanzas__mobile__default.png`.
- **P3:** `warning` `#B7860B` (montos/avisos) sobre tarjeta = 3.21:1 (bajo AA para texto chico).
- **Criterio de aceptación:** chips propios (sin checkmark Material); SALDOS no deja un panel vacío grande; contraste de montos ≥4.5.

### Ajustes — 80
- **Funciona:** cuenta editable, recordatorios (`Activar recordatorios` = botón primario correcto, 4.90 ✓), copiar enlace, cerrar sesión. Voz clara.
- **P2:** en escritorio, columna angosta (~590 px) centrada con enorme vacío alrededor y debajo (S8). Evidencia: `desktop/ajustes__desktop__default.png`.
- **Criterio de aceptación:** el contenido de Ajustes ocupa mejor el alto/ancho en escritorio (o se acepta explícitamente como pantalla mínima).

### Login — 80
- **Funciona:** correo + contraseña + "Iniciar sesión"; traduce errores de Supabase a español; sin registro (cerrado). Botón primario correcto.
- **P2:** en escritorio, formulario centrado en un lienzo crema enorme, sin identidad de marca (solo texto). El error de credenciales solo aparece como snackbar efímero (sin superficie persistente).
- **Criterio de aceptación:** login con más presencia en escritorio; error visible de forma persistente además del snackbar.

---

## 7. Design System

**Tokens/uso correcto:** `AppColors`, `AppSpacing`, `AppTheme`, `VitaCard`, `ErrorEnTarjeta`, `DonutChart`, `moneda.dart` — bien adoptados.

**Tokens incorrectos / faltantes:**
- `AppColors.accentSoft` usado como color de texto en eyebrows: **falla AA**. Necesita un token de texto-acento accesible (p. ej. `accent` `#4E7A63` da 4.47 — límite; conviene un `#3C614E`/`accentDeep`, hoy definido pero **sin uso**, 6.9:1 aprox → ideal para eyebrows).
- No hay tokens de **radio** ni de **tamaño tipográfico**: 12 radios y ~12 tamaños sueltos.
- `accentDeep` definido y nunca usado; **tema oscuro** cableado (`app.dart:23`) pero inalcanzable (`themeMode: ThemeMode.light` fijo).

**Componentes duplicados / a consolidar:**
- `Eyebrow` × 3 → 1 componente.
- `catColor` / `areaColor` / `_paletaCategorias` → 1 paleta de dominio.
- Superficies tipo tarjeta ad-hoc (`_PanelHero`, `_Panel`, `Container(decoration:BoxDecoration(...))` en Calendario) → converger a `VitaCard` con variantes.

**Patrones faltantes (crear e incorporar al DS):**
- `Eyebrow` (accesible), `VitaPrimaryButton` (un solo estilo), `VitaEmptyState` (unificar los ~8 vacíos actuales), `VitaError` (con reintentar, para reemplazar `_ErrorPanel`/`_ErrorCarga`), `SectionChips` (chips propios, sin Material), tokens `radius`/`textStyle`.

**Muerto a eliminar/migrar:** `core/design/tokens/` (8 archivos, 0 imports), `accentDeep` (o usarlo en eyebrows), rama de tema oscuro (o habilitarla).

---

## 8. Accesibilidad (contrastes calculados, WCAG 2.1)

Cálculo real (luminancia relativa) con los hex vigentes de `app_colors.dart`:

| Par | Ratio | AA (normal 4.5 / grande 3.0) |
|---|---|---|
| ink `#2B2620` sobre bg `#FBF4E4` | **13.68** | ✓ |
| ink sobre panel `#FFFDF7` | **14.74** | ✓ |
| muted `#756D5C` sobre bg | **4.68** | ✓ |
| muted sobre panel | **5.04** | ✓ |
| blanco sobre accent `#4E7A63` (botón primario) | **4.90** | ✓ |
| accent `#4E7A63` sobre bg (links: "Agregar prioridad", "Copiar enlace") | **4.47** | ✗ normal (✓ grande) — al límite |
| **accentSoft `#7FA790` sobre bg (EYEBROWS)** | **2.45** | **✗ FALLA** |
| **accentSoft sobre panel (EYEBROWS)** | **2.64** | **✗ FALLA** |
| success `#3E8E5A` sobre panel | 3.95 | ✗ normal (✓ grande) |
| warning `#B7860B` sobre panel (montos/avisos) | 3.21 | ✗ normal (✓ grande) |
| danger `#B5563F` sobre panel | 4.73 | ✓ |
| "Nuevo evento" accent sobre relleno pálido `≈#E3E3D2` | **3.77** | ✗ normal (✓ grande) |

**Lecturas:** el texto de cuerpo y el botón primario oscuro **cumplen**. Fallan de forma **sistémica los eyebrows** (2.45–2.64) y, para texto chico, `warning`/`success` y el botón "Nuevo evento". Los links en `accent` quedan al límite (4.47).

**No observable en CanvasKit (declarado como riesgo, no como aprobado):** navegación por teclado, orden y visibilidad de foco, roles/labels semánticos, escalado de texto del sistema, `prefers-reduced-motion`. Flutter tiene una capa de semántica que se activa bajo lector de pantalla; conviene **verificarla con VoiceOver/TalkBack** en una fase dedicada.

---

## 9. Responsive (por breakpoint)

- **320 px:** sin desbordamiento horizontal ✓. **Las etiquetas del `NavigationBar` se parten** en dos líneas ("Proyecto s", "Calendar io"); fila de salud apretada. Evidencia: `states/mi-vida__w320__default.png`.
- **390 px (móvil):** sólido. 6 tabs entran en una línea; tarjetas a una columna; chips de Finanzas con scroll horizontal.
- **768 px (tablet):** muy bueno. Tarjetas full-width, rejillas 2-col (TU DÍA / PROYECTO PRINCIPAL). Evidencia: `tablet/mi-vida__tablet__default.png`.
- **1440 px (escritorio):** bien en Mi Vida/Finanzas/Mi Mes; **paneles vacíos** en Calendario/Proyectos-hero; Ajustes/Login con vacío.
- **1920 px:** el contenido **respeta un ancho máximo** (no se estira) ✓; pero el wordmark queda a la izquierda lejos del contenido centrado, y el `NavigationBar` separa mucho los ítems. Evidencia: `states/mi-vida__w1920__default.png`.

---

## 10. Errores técnicos observados

- **Consola:** **0 errores** en las 7 rutas × 3 breakpoints (registro en `screenshots/../console-and-network.json`).
- **Red:** **0 solicitudes fallidas**.
- **Rutas:** todas cargan; hash-routing (`#/…`); redirección a `/login` sin sesión correcta.
- **Performance percibida:** arranque en frío de Flutter ~5–6 s con canvas en blanco (sin splash/skeleton propio más allá del de Flutter); descarga de CanvasKit (wasm) pesada. Tras el arranque, la navegación entre pestañas es fluida.
- **Datos simulados en producción:** ninguno (todo lee Supabase).

---

## 11. Qué todavía parece Flutter/Material (concreto)

1. Indicador de pestaña activa del `NavigationBar`: **píldora Material 3** (óvalo detrás del ícono).
2. Chips de sección de Finanzas: **`ChoiceChip` con checkmark** al seleccionar.
3. **Tooltips Material** (recuadro oscuro "Opciones") sobre los `PopupMenuButton` (⋮).
4. **Ripples** de `InkWell`/botones (efecto de onda Material al tocar).
5. Tipografía **Roboto/SF** (Material por defecto), no Inter.
6. `showDatePicker`/`showTimePicker`: **calendarios/relojes Material** estándar en editores.

---

## 12. Qué impide que VITA se sienta premium (sin vaguedad)

1. **Eyebrows al 2.45:1**: las etiquetas guía se ven "lavadas"/desteñidas en toda la app → sensación de borrador.
2. **Inter ausente**: Roboto delata "app Flutter". Inter (o una serif/humanista para títulos) elevaría de inmediato.
3. **Vacío del escritorio**: paneles gigantes vacíos (Calendario, Proyectos-hero, SALDOS) y columnas centradas en un mar crema (Ajustes/Login) → parece incompleto en pantallas grandes.
4. **Dos botones primarios distintos** y un CTA "Nuevo evento" desteñido → falta de sistema.
5. **Restos Material** (píldora de nav, checkmark de chip, tooltips, ripples) → rompen la promesa "no se siente Flutter".
6. **Bug del hero de Proyectos**: un panel vacío en la pantalla insignia del módulo lee como "roto".

---

## 13. Plan de corrección (por fases, con dependencias)

**Fase 1 — Críticos + base del sistema** (habilita el resto)
1. `VITA-001` Reparar el hero de Proyectos (defecto de render).
2. `VITA-002` Token/`Eyebrow` accesible (usar `accentDeep`/`#3C614E`) — arregla el contraste sistémico en las 7 rutas de una vez. *(dep: define token de texto-acento)*
3. `VITA-003` `VitaPrimaryButton` único + `VITA-004` arreglar "Nuevo evento". *(dep: token de botón)*
4. `VITA-010` Actualizar `VITA_MASTER §4` a la realidad (tema claro salvia+crema; estado de Inter) — evita que la doc contradiga al producto.

**Fase 2 — Módulos principales**
5. `VITA-005` Quitar CTA "Nuevo proyecto" duplicada (móvil).
6. `VITA-006` `VitaError` con reintentar en Proyectos y Calendario.
7. `VITA-007` Consolidar paletas de categoría (1 fuente) y `Eyebrow` (1 widget).
8. `VITA-013` Decidir/uniformar escala de salud (palabra vs número) — quitar "x de y" si se opta por palabra.

**Fase 3 — Estados y responsive**
9. `VITA-008` Rediseñar vacíos anchos (Calendario/Proyectos-hero/SALDOS/TU DÍA) → `VitaEmptyState` contenido, sin estirar.
10. `VITA-009` Etiquetas de `NavigationBar` que no se partan a 320 (labels cortas o `labelBehavior`).
11. `VITA-011` Ajustes/Login con mejor uso del escritorio.
12. Chips de sección propios (sin checkmark Material) + afordancia de scroll en móvil.

**Fase 4 — Pulido premium**
13. `VITA-012` Aplicar **Inter** (y considerar una tipográfica de títulos). *(dep: `--dart-define`/assets; MASTER §12)*
14. Reemplazar indicador de nav, tooltips y ripples por tratamientos propios.
15. `VITA-014` Splash/skeleton de arranque; tokens de radio/tamaño; revisión de foco/teclado con lector de pantalla.

---

## 14. Decisiones que requieren tu aprobación (estratégicas)

1. **Tema como fuente de verdad.** Confirmar que el **tema claro salvia+crema** es la dirección definitiva (para corregir `MASTER §4`, que aún describe "oscuro oliva + Inter"). ¿Actualizo la doc a lo que ya aprobaste?
2. **Inter.** ¿Invierto en aplicar Inter (y quizá una tipográfica de títulos)? Sube peso de descarga; es la mejora premium de mayor impacto.
3. **Escala de salud.** ¿Métricas como **palabra** ("Energía buena") en vez de **"3/5"**, para respetar "sin marcadores x de y"? Cambia una interacción que ya conoces.
4. **Salud como módulo propio** (roadmap): ¿lo priorizamos o sigue dentro de Mi Vida?
5. **Escritorio.** ¿VITA es "móvil primero" y aceptamos escritorio más sobrio, o invertimos en layouts de escritorio ricos (menos vacío)?

---

## 15. Cosas que puedo corregir sin preguntarte (seguras, reversibles)

- `VITA-001` hero de Proyectos (bug).
- `VITA-002` eyebrows accesibles (cambio de color de token de texto).
- `VITA-004` botón "Nuevo evento" al estilo primario estándar.
- `VITA-005` quitar CTA "Nuevo proyecto" duplicada en móvil.
- `VITA-006` reintentar en errores de Proyectos/Calendario.
- `VITA-007` consolidar paletas y `Eyebrow`.
- `VITA-009` etiquetas de nav que no se parten a 320.
- `VITA-010` actualizar la doc del tema.
- Tokens de radio/tamaño y limpieza de `core/design/tokens/` muerto.

Backlog completo y ejecutable: **`VITA_FIX_BACKLOG.md`**.
