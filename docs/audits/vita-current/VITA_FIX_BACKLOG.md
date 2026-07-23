# VITA — Backlog de correcciones (ejecutable)

Cada ítem es implementable y verificable. Prioridades: **P0** crítico · **P1** importante · **P2** mejora · **P3** pulido.
Evidencia en `docs/audits/vita-current/screenshots/`. No hay ítems P0 (sin pérdida de datos, bloqueo, crash ni fallo de seguridad).

**Conteo corregido (2026-07-22):** **P0 = 0 · P1 = 5 · P2 = 8 · P3 = 4** (17 ítems).
Corrección: VITA-012 (Inter) se reclasifica a **P1** por ser una decisión cerrada del Documento 6 (no un pulido opcional). VITA-010 se reformula (la doc es fuente de verdad; el tema NO se documenta como claro).
Los P1 son: **VITA-001, VITA-002, VITA-003, VITA-004, VITA-012** (5).

---

## VITA-001 · El hero "Proyecto principal" renderiza un panel vacío
**Prioridad:** P1
**Ruta:** `/proyectos`
**Problema:** En la tarjeta hero "PROYECTO PRINCIPAL", debajo del anillo y el título, aparece un panel grande con solo un ícono de flecha; no se ve el texto del próximo paso ("Instalar las ventanas") ni el botón "Avanzar". El mismo dato SÍ se muestra correctamente en la tarjeta de "Activos" de abajo y en la tarjeta de Mi Vida.
**Evidencia:** `screenshots/desktop/proyectos__desktop__default.png`, `screenshots/mobile/proyectos__mobile__default.png`. Contraste: `tablet/mi-vida__tablet__default.png` (misma info renderiza bien).
**Impacto:** La pantalla insignia de Proyectos parece rota/incompleta; la acción "Avanzar" del hero no está disponible. Es la "bandera grande" reportada por la usuaria.
**Solución:** Investigar `BarraProximoPaso` dentro de `_HeroPrincipal`: el `Row` (ícono + `Expanded(texto)` + botón) no está pintando su contenido textual ni el botón. Verificar que `proximoTexto`/`tienePasos`/`activo` lleguen con valores y que ningún `SizedBox`/constraint colapse el `Expanded`; comparar con la tarjeta `_TarjetaProyecto` que sí funciona con el mismo provider `proximoPasoProvider(id)`.
**Archivos probables:** `app/lib/features/proyectos/presentation/proyectos_screen.dart` (`_HeroPrincipal`), `app/lib/features/proyectos/presentation/proyectos_widgets.dart` (`BarraProximoPaso`).
**Criterios de aceptación:**
- Con proyecto principal + próximo paso: el hero muestra "PRÓXIMO PASO", el texto del paso y el botón "Avanzar".
- Sin pasos: muestra "Agrega tu primer paso" + botón "+ Paso".
- No queda ningún panel vacío mayor a su contenido.
**Validación:** recargar `/proyectos` en 390/768/1440 y comparar con las capturas.
**Dependencias:** ninguna.

---

## VITA-002 · Eyebrows fallan contraste AA (sistémico)
**Prioridad:** P1 — **DIFERIDO en esta fase** (el color se resuelve con la migración de tema VITA-010; el color final define el par de contraste). Sí se ejecuta la parte estructural: consolidar en un único componente `Eyebrow` (VITA-007), sin recolorear todavía.
**Ruta:** todas.
**Problema:** Las etiquetas guía en mayúsculas (`VERSÍCULO DEL DÍA`, `HOY IMPORTA`, `PROYECTO PRINCIPAL`, `EL ESPEJO DEL MES`, `SALDOS`, etc.) usan `AppColors.accentSoft` `#7FA790` ~11 px → **2.45:1 sobre página / 2.64:1 sobre tarjeta**, bajo el mínimo AA (4.5).
**Evidencia:** cálculo en `VITA_PRODUCT_AUDIT.md §8`; visible en todas las capturas.
**Impacto:** Texto estructural ilegible para baja visión; "aspecto desteñido" que baja la sensación premium en toda la app.
**Solución:** Introducir un token de texto-acento accesible y usarlo en el componente `Eyebrow`. `AppColors.accentDeep` `#3C614E` (hoy definido y sin uso) da ≈6.9:1. Cambiar el color del/los eyebrow(s) a ese token.
**Archivos probables:** `app/lib/core/theme/app_colors.dart`, `proyectos_widgets.dart:201` (`Eyebrow`), `mi_vida_screen.dart:1285` (`_Eyebrow`), `mi_mes_screen.dart:684` (`_Eyebrow`).
**Criterios de aceptación:**
- Todos los eyebrows ≥4.5:1 sobre `lightBg` y `lightPanel`.
- Existe un único componente `Eyebrow` reutilizado (ver VITA-007).
**Validación:** recalcular contraste del color elegido sobre `#FBF4E4` y `#FFFDF7`.
**Dependencias:** se resuelve junto con VITA-007.

---

## VITA-003 · Un único botón primario ("crear")
**Prioridad:** P1
**Ruta:** transversal (Proyectos, Calendario, Ajustes, Finanzas, Mi Vida).
**Problema:** Coexisten dos estilos de botón primario para la misma intención: relleno salvia oscuro + texto blanco (correcto, 4.90:1) vs relleno salvia pálido + texto salvia (Calendario, 3.77:1).
**Evidencia:** `desktop/ajustes__desktop__default.png` (correcto) vs `desktop/calendario__desktop__default.png` (desteñido).
**Impacto:** Inconsistencia sistémica; el CTA de crear evento se lee como deshabilitado.
**Solución:** Crear `VitaPrimaryButton` (relleno `accent`, texto blanco, radio y padding tokenizados) y reemplazar los `FilledButton`/tonales de "crear" por él.
**Archivos probables:** `core/widgets/` (nuevo), y usos en `calendario_screen.dart`, `finanzas_screen.dart`, `proyectos_screen.dart`, `ajustes_screen.dart`, `mi_vida_screen.dart`.
**Criterios de aceptación:** todos los botones "crear/primario" comparten un solo componente y ≥4.5:1.
**Validación:** revisar visualmente los 6 módulos.
**Dependencias:** token de botón.

---

## VITA-004 · "Nuevo evento" (Calendario) de bajo contraste
**Prioridad:** P1 — **contraste/recolor DIFERIDO** (depende del color final, VITA-010). Sí se ejecuta la parte estructural: pasar el botón al componente `VitaPrimaryButton` (VITA-003) manteniendo el color actual del sistema; el ajuste fino de contraste se cierra con la migración de tema.
**Ruta:** `/calendario`
**Problema:** Botón "Nuevo evento" con relleno salvia pálido y texto salvia → 3.77:1.
**Evidencia:** `desktop/calendario__desktop__default.png`.
**Impacto:** Acción principal del módulo poco legible; parece inactiva.
**Solución:** Usar `VitaPrimaryButton` (VITA-003).
**Archivos probables:** `app/lib/features/agenda/presentation/calendario_screen.dart`.
**Criterios de aceptación:** botón ≥4.5:1, mismo estilo que "Nuevo proyecto".
**Validación:** captura comparada.
**Dependencias:** VITA-003.

---

## VITA-005 · CTA "Nuevo proyecto" duplicada en móvil
**Prioridad:** P2
**Ruta:** `/proyectos` (móvil)
**Problema:** En <700 px aparecen a la vez el botón ancho "Nuevo proyecto" (en la columna) y un FAB "Nuevo proyecto"; el FAB tapa la 2.ª tarjeta.
**Evidencia:** `mobile/proyectos__mobile__default.png`.
**Impacto:** Dos acciones primarias compitiendo; solapamiento.
**Solución:** Mostrar solo una: el botón inline se condiciona a escritorio (o se elimina) y el FAB queda para móvil (o al revés). En `proyectos_screen.dart`, el `Align(FilledButton 'Nuevo proyecto')` del cuerpo se muestra siempre; condicionarlo a `mostrarBotonArriba` (o quitar el FAB).
**Archivos probables:** `app/lib/features/proyectos/presentation/proyectos_screen.dart`.
**Criterios de aceptación:** exactamente una CTA "Nuevo proyecto" visible por breakpoint; sin solapamientos.
**Validación:** capturas 390 y 1440.
**Dependencias:** ninguna.

---

## VITA-006 · Errores sin "Reintentar" en Proyectos y Calendario
**Prioridad:** P2
**Ruta:** `/proyectos`, `/calendario`
**Problema:** `_ErrorPanel` (Proyectos) y `_ErrorCarga` (Calendario) muestran texto plano; el estándar `ErrorEnTarjeta` incluye botón "Reintentar".
**Evidencia:** código `proyectos_screen.dart:730`, `calendario_screen.dart:376`; comparar `errores.dart:51`.
**Impacto:** Ante fallo de red la usuaria queda en un callejón sin acción de recuperación.
**Solución:** Reemplazar por `ErrorEnTarjeta` (o un `VitaError` unificado) con `onReintentar` que invalide el provider correspondiente.
**Archivos probables:** `proyectos_screen.dart`, `calendario_screen.dart`, `core/widgets/errores.dart`.
**Criterios de aceptación:** ambos estados de error ofrecen "Reintentar" y recargan.
**Validación:** simular error (cortar red) y verificar botón.
**Dependencias:** ninguna.

---

## VITA-007 · Consolidar paletas de categoría y componente Eyebrow
**Prioridad:** P2
**Ruta:** transversal
**Problema:** `catColor` (`calendario_screen.dart:17`) y `areaColor` (`proyectos_widgets.dart:11`) son la misma lista de 8 colores duplicada; `_paletaCategorias` (`finanzas_screen.dart:32`) re-declara colores ya tokenizados. `Eyebrow` existe 3 veces.
**Evidencia:** `VITA_PRODUCT_AUDIT.md §5 (S1, S3)`.
**Impacto:** Deriva; cambiar un color exige tocar 2–3 archivos.
**Solución:** Mover la paleta de dominio a `core/theme` (una fuente) y crear un único `Eyebrow` en `core/widgets`.
**Archivos probables:** `core/theme/app_colors.dart` (o nuevo `domain_palette.dart`), `core/widgets/eyebrow.dart` (nuevo), y los 3 archivos que hoy duplican.
**Criterios de aceptación:** una sola definición de la paleta de categorías; un solo `Eyebrow`.
**Validación:** `grep` no encuentra duplicados; UI sin cambios de color no deseados.
**Dependencias:** se combina con VITA-002.

---

## VITA-008 · Vacíos que estiran/derrochan espacio (escritorio)
**Prioridad:** P2
**Ruta:** `/calendario`, `/proyectos`, `/finanzas`, `/mi-vida`
**Problema:** Paneles vacíos grandes: "Agenda del día" (Calendario) casi pantalla completa; "SALDOS" (Finanzas) panel vacío junto a la dona; "TU DÍA" (Mi Vida) estirado para igualar la tarjeta vecina.
**Evidencia:** `desktop/calendario__desktop__default.png`, `desktop/finanzas__desktop__default.png`, `desktop/mi-vida__desktop__scroll.png`.
**Impacto:** Sensación de incompleto en pantallas anchas.
**Solución:** `VitaEmptyState` compacto (altura intrínseca, no estirada); en rejillas 2-col, no forzar igualdad de alto (`CrossAxisAlignment.start`) o colapsar la celda vacía.
**Archivos probables:** widgets de esas secciones; nuevo `core/widgets/vita_empty_state.dart`.
**Criterios de aceptación:** ningún estado vacío ocupa >~40% del alto del viewport en escritorio.
**Validación:** capturas 1440.
**Dependencias:** ninguna.

---

## VITA-009 · Etiquetas del NavigationBar se parten a 320 px
**Prioridad:** P2
**Ruta:** transversal (barra inferior)
**Problema:** A 320 px, "Proyectos"→"Proyecto s" y "Calendario"→"Calendar io" (2 líneas).
**Evidencia:** `states/mi-vida__w320__default.png`.
**Impacto:** Navegación descuidada en pantallas pequeñas.
**Solución:** `NavigationBar.labelBehavior` adaptativo, etiquetas más cortas ("Calendario"→"Agenda"?) o `MediaQuery.textScaler`/tamaño reducido bajo 360.
**Archivos probables:** `app/lib/core/widgets/app_shell.dart`.
**Criterios de aceptación:** a 320 px ninguna etiqueta se parte.
**Validación:** captura 320.
**Dependencias:** decisión de naming (Calendario vs Agenda).

---

## VITA-010 · Divergencia de tema: la IMPLEMENTACIÓN debe migrar a la identidad aprobada
**Prioridad:** P2 (migración) — **DIFERIDO en esta fase** (decisión del PO 2026-07-22: el color/tema se deja pendiente).
**Ruta:** global (tema) + docs.
**Problema:** La identidad aprobada (Documento 6 / `MASTER §4`) es **tema OSCURO cálido oliva**; la implementación quedó en **claro salvia+crema**. La documentación **NO se cambia**: es la fuente de verdad. Lo que se corrige es la **implementación**, acercándola gradualmente al Documento 6.
**Evidencia:** `app_colors.dart` (claro) vs `VITA_MASTER §4` (oscuro oliva, verdad).
**Impacto:** El producto no refleja aún la identidad aprobada.
**Solución (fase futura):** migrar desde el nivel sistémico más alto — `ColorScheme`/`AppTheme` y tokens de `core/theme` — a superficies oscuras cálidas + acento oliva contenido, contraste AA. NO diseñar tema claro, NO añadir selector, NO duplicar tokens; solo garantizar que la arquitectura no cierre la puerta a un claro futuro.
**Origen del claro actual a mapear antes de migrar:** tokens globales (`AppColors.light*`), `ThemeData` (`AppTheme.light` + `themeMode: ThemeMode.light` fijo en `app.dart`), componentes locales, colores hardcodeados, estilos duplicados.
**Archivos probables:** `core/theme/app_colors.dart`, `core/theme/app_theme.dart`, `app/lib/app.dart`.
**Criterios de aceptación:** implementación alineada con Documento 6; la doc permanece intacta como fuente de verdad.
**Dependencias:** PENDIENTE por decisión del PO. Los ítems de contraste que dependen del color final (**VITA-002** eyebrows, **VITA-004** CTA) se resuelven junto con esta migración.

---

## VITA-011 · Escritorio de Ajustes/Login muy vacío
**Prioridad:** P3
**Ruta:** `/ajustes`, `/login`
**Problema:** Columna angosta (~420–590 px) centrada en un lienzo de 1440+, con vacío arriba/abajo/lados.
**Evidencia:** `desktop/ajustes__desktop__default.png`, `states/login__desktop__default.png`.
**Impacto:** Se ve inacabado en escritorio.
**Solución:** Añadir presencia (marca/ilustración sobria en Login; agrupar Ajustes con mejor uso del alto) o aceptar explícitamente el estilo mínimo (decisión 5).
**Archivos probables:** `login_screen.dart`, `ajustes_screen.dart`.
**Criterios de aceptación:** el contenido no queda como una isla pequeña centrada; equilibrio visual en 1440.
**Validación:** capturas 1440.
**Dependencias:** decisión 5.

---

## VITA-012 · Aplicar tipografía Inter
**Prioridad:** **P1** (decisión cerrada, Documento 6) — **se ejecuta en Fase 1 (color-neutral)**.
**Ruta:** global
**Problema:** La app usa Roboto/SF (Material). Documento 6 exige Inter; el token de tipografía está muerto.
**Evidencia:** `VITA_PRODUCT_AUDIT.md §11`.
**Impacto:** "Se siente Flutter/Material".
**Solución:** Inter **autoalojada** (assets locales, no CDN/Google Fonts), instancias **estáticas**, subset **Latin + Latin-ext**, pesos **400 y 600** (500 solo si hay necesidad concreta), fallback de sistema, precarga donde aplique, **cifras tabulares** (`FontFeature.tabularFigures`) en datos financieros/columnas numéricas. Aplicar en `AppTheme.textTheme`.
**Archivos probables:** `pubspec.yaml` (assets), `app/lib/core/theme/app_theme.dart`, `app/assets/fonts/`, `moneda.dart`/estilos numéricos.
**Criterios de aceptación:** todo el texto en Inter; ñ/á-é-í-ó-ú/¿¡ correctos; etiquetas 12 px legibles; números tabulares en dinero; sin FOUT notorio; peso de descarga razonable.
**Validación:** inspección visual + captura + peso.
**Dependencias:** ninguna (no depende del color).

---

## VITA-013 · Escala de salud: "3/5" vs palabra
**Prioridad:** P2
**Ruta:** `/mi-vida`
**Problema:** "Energía 3/5", "Ánimo 4/5" (marcador "x de y") conviven con "Sueño: Regular" (palabra). MASTER §5 pide "sin marcadores x de y".
**Evidencia:** `desktop/mi-vida__desktop__default.png`.
**Impacto:** Inconsistencia interna y tensión con la filosofía.
**Solución:** Unificar a palabra ("Energía buena", "Ánimo alto") — como ya hace Mi Mes — o mantener número justificándolo. (Decisión 3.)
**Archivos probables:** `mi_vida_screen.dart` (`_EstadoGeneral`).
**Criterios de aceptación:** las 4 métricas usan la misma escala.
**Validación:** captura Mi Vida.
**Dependencias:** aprobación humana (decisión 3).

---

## VITA-014 · Arranque en frío sin splash/skeleton
**Prioridad:** P3
**Ruta:** global (primera carga)
**Problema:** ~5–6 s de canvas en blanco al primer arranque (descarga CanvasKit + boot Flutter) sin splash propio ni skeleton.
**Evidencia:** medición de arranque en la captura.
**Impacto:** Primera impresión lenta.
**Solución:** Splash HTML/CSS ligero en `web/index.html` mientras Flutter arranca; evaluar renderer/peso.
**Archivos probables:** `app/web/index.html`.
**Criterios de aceptación:** el usuario ve marca/indicador durante el arranque, no un blanco.
**Validación:** recarga en frío.
**Dependencias:** ninguna.

---

## VITA-015 · Chips de sección y restos Material
**Prioridad:** P2/P3
**Ruta:** transversal
**Problema:** `ChoiceChip` con checkmark (Finanzas), píldora del `NavigationBar`, tooltips Material, ripples.
**Evidencia:** `VITA_PRODUCT_AUDIT.md §11`.
**Impacto:** "Se siente Flutter".
**Solución:** Chips propios (`SectionChips`), indicador de nav propio, tooltips/`splashFactory` personalizados o desactivados.
**Archivos probables:** `finanzas_screen.dart`, `app_shell.dart`, `app_theme.dart`.
**Criterios de aceptación:** ningún checkmark Material en chips; indicador de nav propio.
**Validación:** capturas.
**Dependencias:** ninguna.

---

## VITA-016 · Tokens de radio y tamaño tipográfico
**Prioridad:** P3
**Ruta:** DS
**Problema:** 12 radios distintos (`5,6,7,8,9,10,12,14,16,18,20,22`) y ~12 tamaños de fuente sueltos.
**Evidencia:** inventario de código.
**Impacto:** Inconsistencia y deriva.
**Solución:** Definir escala de radios (p. ej. `sm 8 / md 12 / lg 16 / xl 20`) y de tamaños en `AppSpacing`/`AppTheme`, y migrar usos.
**Archivos probables:** `core/theme/app_spacing.dart`, `app_theme.dart`, features.
**Criterios de aceptación:** ≤5 radios en uso; tamaños vía `textTheme`.
**Validación:** `grep` de `BorderRadius.circular(` y `fontSize:`.
**Dependencias:** ninguna.

---

## VITA-017 · Limpiar código muerto del design system
**Prioridad:** P3
**Ruta:** `core/design/tokens/`, tema oscuro, `accentDeep`
**Problema:** `core/design/tokens/` (8 archivos) sin imports; `AppTheme.dark()` inalcanzable; `accentDeep` sin uso.
**Evidencia:** inventario de código §10.
**Impacto:** Confusión sobre cuál es la fuente de verdad.
**Solución:** Eliminar `core/design/tokens/`; usar `accentDeep` (eyebrows, VITA-002) o quitarlo; decidir si se habilita tema oscuro o se retira.
**Archivos probables:** `core/design/tokens/*`, `app.dart`, `app_theme.dart`, `app_colors.dart`.
**Criterios de aceptación:** sin directorios/tokens muertos; una sola fuente de verdad visual.
**Validación:** compila; `grep` sin referencias.
**Dependencias:** VITA-002 (uso de accentDeep).
