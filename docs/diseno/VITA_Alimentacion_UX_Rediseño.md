# VITA · Alimentación — Rediseño estructural de la experiencia (UX)

> **Estado:** propuesta para aprobación. **No se implementa nada** hasta el visto
> bueno. Conserva la **lógica útil** (motor determinista, biblioteca, macros,
> producciones, conservación, agregación de compras); **reemplaza** la arquitectura
> visual, la jerarquía, la navegación interna y el flujo operativo.
>
> Flujo que el módulo debe habilitar de punta a punta:
> **planificar → comprar → cocinar → porcionar → guardar → llevar → comer → marcar.**
> Yurby es la protagonista; la familia (Juan · Juan Miguel, 5 años) afecta cuánto se
> compra, cuánto se cocina y cuántas porciones se preparan — **no** invade su pantalla.

---

## 1. Diagnóstico preciso de la implementación actual

La versión desplegada (commits hasta `5679406`) es técnicamente correcta pero es un
**planificador en una sola columna**, no una herramienta operativa:

| # | Problema | Causa raíz en el código |
|---|---|---|
| 1 | En escritorio parece app móvil estirada | `_Pagina` fuerza `ConstrainedBox(maxWidth: 860)` + columna única en todos los tabs |
| 2 | Todo en una columna vertical | Cada tab es `SingleChildScrollView > Column(stretch)` |
| 3 | Tarjetas enormes para poca info | `VitaCard` a ancho completo por ítem (`_TarjetaComida`, `_TarjetaNinoDia`) |
| 4 | Mucho espacio vacío | Sin grilla ni densidad; una tarjeta = una fila |
| 5 | El menú es una lista, no herramienta | `_TabSemana` = `Column` de 7 tarjetas apiladas, sin estados ni acciones |
| 6 | "Hoy cocinas" no guía de verdad | `_TabCocina` lista producciones, sin cronograma, sin dependencias, sin checkboxes |
| 7 | Compras = lista de gramos | `_TabCompras` muestra `2,9 kg`, `604 g`; sin período, fecha ni unidades humanas |
| 8 | Juan sigue en la pantalla personal | `_DetallePersonas` expande "Para Juan" en cada comida de Hoy |
| 9 | Juan Miguel mal integrado | `_TabFamilia` como pestaña aparte; no hay adaptación por plato |
| 10 | No hay gestión de recipientes/porciones | No existe el concepto de recipiente ni su estado |
| 11 | No puedo marcar cociné/guardé/llevé/comí | No hay estados de comida ni de recipiente; todo es de solo lectura |
| 12 | Hoy no dice la acción a realizar | `_TarjetaDecision` da un mensaje, no una **próxima acción** accionable |
| 13 | Sin integración con el dashboard de VITA | No hay widget en Mi Vida |
| 14 | No se siente premium ni coherente | Densidad baja, jerarquía plana, todo son tarjetas iguales |
| 15 | Emojis decoran una arquitectura débil | Emoji como iconografía en lugar de sistema visual |

**Conclusión:** el problema no es de texto ni de color; es de **arquitectura de
información y de interacción**. Se rehace.

---

## 2. Componentes que se ELIMINAN o sustituyen

De `presentation/alimentacion_screen.dart` (se reescribe completo):

- `_Pagina` (columna única con `maxWidth 860`) → **eliminado**; se sustituye por un
  **scaffold responsive de grilla** (`_LayoutAlimentacion` con 1/2/3 columnas).
- `_TabHoy` (bienvenida grande + tarjetas apiladas) → **reemplazado** por `HoyView`
  de dos columnas (65/35) + fila de recipientes.
- `_TarjetaDecision` → **reemplazado** por `AccionSiguienteBar` (compacta) dentro de
  "Organización de hoy".
- `_TarjetaComida` + `_DetallePersonas` (tarjetón con expand de Juan) → **reemplazado**
  por `ComidaFila` compacta (estado + acción + "tu porción") con "Ver detalle familiar"
  en un panel/hoja secundaria.
- `_TabSemana` (lista vertical) → **reemplazado** por `MenuGrid` (cuadrícula semanal).
- `_TabCocina` ("Hoy cocinas", lista de producciones) → **reemplazado** por
  `PrepararView` (Resumen + Cronograma + Porcionado + Desayunos).
- `_TabFamilia` (pestaña separada) → **eliminado como pestaña**; se integra en
  "Ver detalle familiar" (secundario) y en el **Porcionado** de Preparar.
- `_TarjetaNinoHoy`, `_TarjetaNinoDia` → **reemplazados** por `AdaptacionInfantil`
  embebida en cada comida (chip + detalle), no tarjetas independientes.
- `_TabCompras` (checklist de gramos) → **reemplazado** por `ComprasView` (sistema
  quincenal calendarizado con unidades humanas).
- Emojis como iconografía → **reemplazados** por iconos Material coherentes con VITA
  (los emojis quedan, a lo sumo, como acento mínimo, nunca como estructura).

---

## 3. Componentes / lógica que se REUTILIZAN

Se conserva **toda la capa de dominio y datos** (es la parte fuerte, 9.8/10):

- `domain/motor.dart` — motor determinista: selección de menú, **cierre por día
  (±5% · proteína ≥ meta)**, roll-up de producciones base→terminaciones, conservación,
  agregación de compras. Se **extiende**, no se rehace.
- `domain/biblioteca_seed.dart` — biblioteca aprobada. Se **enriquece** (platos reales
  con salsa/acompañamiento/adaptación infantil/unidades de compra).
- `domain/alimentacion.dart` — entidades (`Macros`, `Alimento`, `Preparacion`,
  `Ensamble`, `PerfilNutricional`…). Se **amplían** con campos nuevos.
- `domain/cocina_familiar.dart` — lógica del niño (`planNino`, presentación). Se
  **reencuadra** hacia "adaptación por plato".
- `data/alimentacion_repository.dart`, `presentation/alimentacion_controller.dart` —
  repositorio y providers. Se **amplían** (estados, recipientes, compras).
- Migración `0017` y sus 8 tablas — **base**; se añade `0018` (no se edita `0017`).
- Sistema de diseño: `core/theme` (`AppColors`, `AppSpacing`), `core/widgets`
  (`VitaCard`, `Eyebrow`, `ErrorEnTarjeta`), patrón `AsyncValue.when`, `RefreshIndicator`.

---

## 4. Nueva arquitectura de información

**Cuatro vistas** (sin pestañas redundantes). Se elimina "Familia" como pestaña.

```
Alimentación
├─ Hoy       ← centro operativo (2 columnas en escritorio)
├─ Menú      ← cuadrícula semanal con estados y acciones
├─ Preparar  ← sesión de producción del domingo (guiada)
└─ Compras   ← sistema quincenal calendarizado
```

Conceptos transversales (viven en el dominio, se muestran donde corresponde):

- **Comida planificada** con **estado** (§10) y **próxima acción**.
- **Recipiente** (porción física) con **estado** (§11), etiqueta `Persona · día`.
- **Adaptación infantil** por plato (§14) — no es una pantalla, es un atributo.
- **Compra quincenal** con período, fecha elegida y seguimiento (§12).
- **Detalle familiar** — panel secundario bajo demanda (Juan nunca en primer plano).

Jerarquía de la pantalla principal (Hoy): **acción siguiente > mi comida de hoy >
recipientes de hoy > organización (recordatorios) > detalle familiar (oculto)**.

---

## 5. Flujo completo de usuario

```
                 ┌──────────── COMPRAS (quincenal) ────────────┐
                 │ elegir día → recordatorio en calendario VITA │
                 │ comprar (unidades humanas) → marcar comprado │
                 └───────────────────┬──────────────────────────┘
                                     ▼
                        ┌──────── PREPARAR (domingo) ────────┐
                        │ cronograma paralelo → cocinar bases │
                        │ separar porción infantil            │
                        │ porcionar → etiquetar → refri/cong. │
                        └───────────────┬─────────────────────┘
                                        ▼
   ┌──────── MENÚ ────────┐   ┌──────────── HOY ─────────────┐
   │ ver semana en grilla │◄─►│ ¿qué como? ¿qué recipiente?  │
   │ estados por comida   │   │ ¿está listo? próxima acción  │
   │ cambiar / marcar     │   │ descongelar / llevar / comí  │
   └──────────────────────┘   └───────────────┬──────────────┘
                                               ▼
                              DASHBOARD VITA (widget "Tu alimentación de hoy")
```

Ciclo diario de Yurby: abre **Hoy** → ve su próxima acción (ej. "Toma el recipiente
Yurby·lunes del refri") → marca **Ya lo llevé** → al comer marca **Ya lo comí** → si
cambia algo, **Cambiar**. El estado se refleja en **Menú** y en el **widget del dashboard**.

---

## 6. Wireframes textuales detallados

### 6.1 HOY (escritorio, 2 columnas 65/35)

```
┌───────────────────────────────────────────────────────────────────────────┐
│  Alimentación                                     Próxima compra: mié 29 jul │
│  Hola, Yurby · miércoles 30                                    [Ver compra]  │
├──────────────────────────────────────────────┬────────────────────────────┤
│  TU ALIMENTACIÓN DE HOY                       │  ORGANIZACIÓN DE HOY        │
│                                               │                            │
│  ┌── Desayuno · 07:00 ───────────────────┐    │  ▸ Descongelar salmón      │
│  │ Arepa con pollo            ✓ Comido    │    │    (para el jueves)  [Hecho]│
│  │ tu porción · 5 min                     │    │  ▸ Llevar recipiente        │
│  └────────────────────────────────────────┘    │    "Yurby · miércoles"[Ok]  │
│                                               │  ▸ Comprar leche      [Ok]  │
│  ┌── Almuerzo · 13:00 ───────────────────┐    │  ▸ Preparar arepa de mañana │
│  │ Pollo en salsa suave con arroz         │    │  ▸ Mini-prep del miércoles  │
│  │ Estado: recipiente listo (refri)       │    │  ─────────────────────────  │
│  │ Próxima acción: toma "Yurby · mié"     │    │  Faltan 3 días para la      │
│  │ tu porción · listo para llevar         │    │  compra quincenal.          │
│  │ [Ya lo llevé][Ya lo comí][Cambiar][▾]  │    │                            │
│  └────────────────────────────────────────┘    │  [Ver detalle familiar]     │
│                                               │  (Juan · Juan Miguel)       │
│  ┌── Merienda · 16:00 ───────────────────┐    │                            │
│  │ Plátano con leche          Pendiente   │    │                            │
│  │ tu porción · sin preparación           │    │                            │
│  └────────────────────────────────────────┘    │                            │
├──────────────────────────────────────────────┴────────────────────────────┤
│  RECIPIENTES DE HOY   ▢ Yurby·mié (refri)  ▢ Juan·mié  ▢ Juan Miguel·mié    │
└───────────────────────────────────────────────────────────────────────────┘
```

- **Bienvenida pequeña** (una línea con fecha). Sin héroe gigante.
- Cada comida: hora · nombre · descripción real · **estado** · **próxima acción** ·
  "tu porción" · tiempo · acciones (`Ver preparación`, `Cambiar`, `Ya lo comí`,
  y para el almuerzo `Ya lo llevé`).
- "Tu porción" **sin números de Juan**. El detalle familiar y las cantidades por
  persona viven detrás de **[Ver detalle familiar]** (§6.5).
- Columna derecha = **solo acciones/recordatorios** accionables + cuenta regresiva de compra.

### 6.2 MENÚ (escritorio, cuadrícula 4+3)

```
┌───────────────────────────────────────────────────────────────────────────┐
│  Menú de la semana        ● refri  ❄ congelado          [Regenerar semana]  │
├───────────────┬───────────────┬───────────────┬───────────────────────────┤
│ LUNES         │ MARTES        │ MIÉRCOLES     │ JUEVES                     │
│ Des Arepa/pollo✓│ Des Perico   │ Des Arepa/queso│ Des Huevo/palta          │
│ Alm Pollo salsa│ Alm Carne pl. │ Alm Pasta atún │ Alm Pollo salteado       │
│   ● listo      │   ● listo     │   ● por servir │   ❄ descongelar hoy       │
│ Mer Plátano    │ Mer Manzana   │ Mer Batido     │ Mer Uvas                 │
│ [Ver día][⋯]   │ [Ver día][⋯]  │ [Ver día][⋯]   │ [Ver día][⋯]             │
├───────────────┴───────────────┴───────────────┴───────────────────────────┤
│ VIERNES               │ SÁBADO (especial)       │ DOMINGO (especial+prep)  │
│ Des Tostada palta     │ Des Arepa jamón/queso    │ Des Paquecas             │
│ Alm Boloñesa          │ Alm Salmón al horno      │ Alm Carne al horno       │
│   ❄ descongelar jue   │   familiar · 45 min      │   familiar · 60 min      │
│ Mer Plátano           │ Mer Manzana              │ Mer Plátano con leche    │
│ [Ver día][⋯]          │ [Ver día][⋯]             │ [Ver día][⋯]             │
└───────────────────────────────────────────────────────────────────────────┘
```

- Toda la semana visible casi sin scroll (7 tarjetas **compactas**, no 7 tarjetones).
- Cada día: 3 momentos en 1–2 líneas c/u + **indicador de estado del almuerzo**
  (● refri / ❄ congelado / ✓ comido / por servir / descongelar hoy).
- **Marcado directo** desde la semana (tap en el estado lo avanza) + `Cambiar` (`⋯`).

### 6.3 PREPARAR — "Preparar la semana" (escritorio)

```
┌───────────────────────────────────────────────────────────────────────────┐
│  Preparar la semana · domingo                                               │
├───────────────────────────────────────────────────────────────────────────┤
│  RESUMEN (tiles compactos)                                                  │
│  ┌─────────┐┌─────────┐┌─────────┐┌─────────┐┌─────────┐┌─────────┐        │
│  │85 min   ││4 bases  ││12 recip.││Refri 7  ││Cong. 5  ││Mié mini │        │
│  │activos  ││         ││         ││         ││         ││-prep    │        │
│  └─────────┘└─────────┘└─────────┘└─────────┘└─────────┘└─────────┘        │
├──────────────────────────────────────────┬────────────────────────────────┤
│  CRONOGRAMA INTELIGENTE (paralelo)        │  PORCIONADO (por día)          │
│  ▢ 00:00 Precalentar horno                │  LUNES                         │
│  ▢ 00:05 Poner arroz            18 min    │   Yurby   Pollo+arroz   refri  │
│  ▢ 00:08 Sazonar pollo                    │          [Pendiente ▸ Listo]   │
│  ▢ 00:15 Pollo al horno         25 min    │   Juan    Pollo+arroz   refri  │
│  ▢ 00:20 Preparar salsa                   │          [Pendiente ▸ Listo]   │
│  ▢ 00:30 Cortar vegetales                 │   J.Miguel Pollo s/salsa+arroz │
│  ▢ 00:45 SEPARAR porción infantil ⬅ niño  │           aparte · infantil    │
│  ▢ 01:00 Porcionar                        │          [Pendiente ▸ Listo]   │
│  ▢ 01:15 Etiquetar                        │  MARTES … (colapsable)         │
│  ▢ 01:25 Refrigerar y congelar            │                                │
│  (cada paso: duración·ingredientes·       │  Se ve SOLO estado actual +    │
│   utensilios·adaptación niño·dependencias)│  acción siguiente, no todos.   │
├──────────────────────────────────────────┴────────────────────────────────┤
│  DESAYUNOS Y MERIENDAS — qué adelanto / qué hago al momento                 │
│  Arepa con pollo →  Domingo: porcionar pollo, dejar masa lista              │
│                     Lunes AM: calentar y rellenar · 5 min                   │
└───────────────────────────────────────────────────────────────────────────┘
```

### 6.4 COMPRAS (escritorio)

```
┌───────────────────────────────────────────────────────────────────────────┐
│  Compras                                                                    │
│  ┌─────────────────────────── COMPRA QUINCENAL ──────────────────────────┐ │
│  │ Cubre: 3 – 16 de agosto        Personas: Yurby · Juan · Juan Miguel    │ │
│  │ Recomendado: entre lun 27 y vie 31 jul   Estado: pendiente            │ │
│  │ ¿Qué día la haces?  [Lun 27][Mar 28][Mié 29][Jue 30][Vie 31]          │ │
│  │ Presupuesto estimado: $XX.XXX        Comprado: 0%   ▱▱▱▱▱▱▱▱▱▱         │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│  Reposición de frescos · vie 8 ago (mitad de quincena)      [Ver lista]      │
├───────────────────────────────────────────────────────────────────────────┤
│  LISTA (por categoría, unidades de supermercado)                            │
│  🥩 Carnes y proteínas          🥦 Verduras            🥛 Lácteos            │
│  ▢ 2,5 kg de pollo   $____      ▢ Tomates    (ya tengo)▢ 3 L de leche  $__  │
│  ▢ 1 bandeja salmón  $____      ▢ Lechuga             ▢ Quesillo            │
│  ▢ 12 huevos         $____      ▢ 2 paltas             Despensa             │
│  [comprado][ya tengo][editar][sustituir]  …            ▢ 1 pqt harina maíz  │
│                                                          Subtotal: $XX.XXX   │
└───────────────────────────────────────────────────────────────────────────┘
```

### 6.5 DETALLE FAMILIAR (panel secundario, se abre bajo demanda)

Hoja lateral / modal desde `[Ver detalle familiar]`. **No** está en la vista principal.

```
┌── Detalle familiar · Almuerzo ─────────────────────────────┐
│ Pollo en salsa suave con arroz                             │
│ ────────────────────────────────────────────────────────  │
│  Yurby      porción media   1 recipiente   refri           │
│  Juan       porción mayor   1 recipiente   refri           │
│  Juan Miguel porción infantil · adaptada   1 recipiente     │
│                                                            │
│  (cantidades y macros por persona aquí, no en Hoy)         │
│  Total a cocinar: pollo ~X · arroz ~Y · salsa ~Z          │
└────────────────────────────────────────────────────────────┘
```

### 6.6 ADAPTACIÓN DE JUAN MIGUEL (embebida en la comida)

Chip "Niño" en la comida → despliega la adaptación (no es tarjeta aparte):

```
Pollo en salsa suave con arroz            [Niño ▾]
  └ Para Juan Miguel (5 años · porción infantil):
     • Reservar pollo ANTES de la salsa
     • Arroz servido aparte
     • Sin champiñones / sin cebolla
     • Cortado pequeño
     • Ofrecer aparte: bastones de zanahoria (opcional)
```

### 6.7 WIDGET DEL DASHBOARD (Mi Vida)

```
┌── Tu alimentación de hoy ───────────────────────────┐
│ Desayuno   Arepa con pollo                          │
│ Almuerzo   Pollo en salsa con arroz   ● listo       │
│ Próxima acción: toma "Yurby · miércoles" del refri  │
│ Mañana: descongelar salmón                          │
│ Compra: faltan 3 días                    [Ver →]    │
└──────────────────────────────────────────────────────┘
```

Sin macros de Juan. Mismo lenguaje visual de las tarjetas de Mi Vida.

---

## 7. Distribución en ESCRITORIO (≥ 1000 px, útil 1200–1400)

- Contenedor central `maxWidth ≈ 1360`, padding 32.
- **Hoy:** `Row` → `Expanded(flex 65)` (comidas) + `Expanded(flex 35)` (organización);
  franja inferior full-width de recipientes. (En Flutter: `LayoutBuilder` + `Row/Flexible`;
  "CSS Grid equivalente" = `GridView`/`Wrap`/`Table` según bloque.)
- **Menú:** `GridView`/`Wrap` de 4 columnas (fila 1: Lun–Jue) + 3 (fila 2: Vie–Dom);
  tarjetas de alto fijo compacto.
- **Preparar:** Resumen = `Wrap` de tiles; cuerpo = `Row` (Cronograma 55% | Porcionado 45%);
  Desayunos full-width.
- **Compras:** header quincenal full-width; lista = `Wrap`/grid de 2–3 columnas de categorías.

## 8. Distribución en TABLET (600–1000 px)

- **Hoy:** 2 columnas si ≥ 760; si no, comidas arriba / organización abajo.
- **Menú:** grilla de 2–3 columnas (auto-fit por ancho).
- **Preparar:** Cronograma y Porcionado apilados (Cronograma primero).
- **Compras:** categorías en 2 columnas.

## 9. Distribución en MÓVIL (< 600 px)

- Una columna. **Prioriza la próxima acción**: arriba una barra "Tu próxima acción"
  con un solo CTA; luego las 3 comidas compactas; "Organización" colapsada.
- **Menú:** días apilados pero **compactos** (no tarjetones); estado tocable.
- **Preparar:** cronograma como lista con checkboxes; porcionado por día colapsable.
- **Compras:** header quincenal + categorías como acordeón.

---

## 10. Estados de COMIDA

`Planificado → Por preparar → Preparado → Refrigerado / Congelado → Descongelar hoy
→ Llevado → Consumido`; transversales: `Cambiado`, `Omitido`.

- Se muestra **un** estado (el actual) + la acción que lo avanza; nunca la lista completa.
- Color/icono por estado (coherente con `AppColors`: `accent`, `warning`, `success`, `muted`).
- Marcado desde **Hoy** y desde **Menú**.

## 11. Estados de RECIPIENTE (porción física)

`Pendiente → Porcionado → Etiquetado → Refrigerado / Congelado → Descongelado
→ Llevado → Consumido`.

- Un recipiente = (comida, persona, día). Etiqueta visible `Persona · día`.
- Se generan en **Preparar** (Porcionado) y se consumen en **Hoy**.
- La UI muestra estado actual + siguiente acción; el historial no satura la vista.

---

## 12. Flujo de COMPRA QUINCENAL

1. El motor calcula el período (14 días) y **cantidades en unidades humanas** para las
   3 personas (los gramos quedan internos).
2. Vista Compras muestra **período**, **fecha recomendada** (rango), selector de **día**.
3. Al elegir día: se guarda, se **crea recordatorio en el calendario de VITA** (feature
   `agenda`, vía `core`), aviso el día anterior, y se muestra la **lista definitiva**.
4. **Reposición de frescos** a mitad de quincena (su propia fecha/lista).
5. Lista por categorías (Carnes, Verduras, Frutas, Lácteos, Despensa, Congelados,
   Bebidas, Otros). Por artículo: `comprado` · `ya tengo` · `editar cantidad` ·
   `sustituir` · `precio` · **subtotal** y **% comprado**.

## 13. Flujo de PREPARACIÓN DOMINICAL

1. **Resumen**: tiempo activo, nº de bases, porciones totales, recipientes, refri/cong.,
   aviso del mini-prep del miércoles.
2. **Cronograma inteligente**: tareas ordenadas para **paralelizar** (horno + arroz +
   sazón simultáneos). Cada paso: checkbox · duración · ingredientes · utensilios ·
   **adaptación infantil** (p. ej. "separar porción del niño antes de la salsa") ·
   dependencias.
3. **Porcionado por día**: por persona, recipiente marcable con su estado (§11);
   Juan Miguel aparece con su **adaptación**, no con gramos.
4. **Desayunos y meriendas**: distingue *se prepara el domingo* / *se adelanta parcial* /
   *se hace en la mañana*, con el paso exacto y su tiempo.

---

## 14. Integración de JUAN MIGUEL (5 años)

- **No** es un adulto reducido por porcentaje ni entra al cierre de macros.
- Come **porción infantil pequeña** de la **misma preparación base**, **adaptada**.
- Cada `Ensamble` gana un objeto **`AdaptacionInfantil`** con acciones tipadas:
  `reservar_sin_salsa`, `acompañamiento_aparte`, `sin_cebolla`, `sin_vegetales_mezclados`,
  `cortar_pequeño`, `porcion_infantil`, `ofrecer_vegetal_aparte`, `cambiar_acompañamiento`,
  `no_requiere_porcion`.
- Ejemplo (plato: *Pollo en salsa suave de champiñones con papas al horno*):
  reservar pollo sin salsa · papas aparte · sin champiñones · porción infantil.
- **Mejora progresiva**: campo para "vegetal a ofrecer aparte" que rota suave, sin
  obligar a cocinar otro plato.
- Se refleja en: chip "Niño" en la comida (Hoy/Menú), paso "separar porción infantil"
  en el Cronograma, y su recipiente propio en Porcionado.

---

## 15. Integración con el DASHBOARD principal de VITA (Mi Vida)

- Nuevo widget `TuAlimentacionHoyCard` en `features/mi_vida/presentation/mi_vida_screen.dart`.
- Contenido: desayuno · almuerzo (+estado) · **próxima acción** · "mañana:" · cuenta de
  compra · botón `[Ver alimentación]` → `/alimentacion`.
- **Sin** macros ni nombre de Juan. Reutiliza el lenguaje visual de las tarjetas de Mi Vida
  (`VitaCard`, tipografías, `accent`). Comunicación cruzada vía `core/` (los features no se
  importan entre sí): un provider expuesto en `core` o leído por un puerto.

---

## 16. Componentes reutilizables NUEVOS (a construir)

- `AlimentacionScaffold` — grilla responsive (1/2/3 col) + breakpoints estándar.
- `ComidaFila` — comida compacta con estado + próxima acción + acciones.
- `EstadoChip` — chip de estado (comida/recipiente) con icono+color por estado.
- `AccionSiguiente` — CTA de la próxima acción (usado en Hoy, móvil y widget).
- `DiaMenuCard` — tarjeta compacta de día (3 momentos + estado + marcar).
- `TileResumen` — mini-tile de estadística (Preparar).
- `PasoCronograma` — paso con checkbox/duración/ingredientes/dependencias/adaptación.
- `RecipienteChip` / `PorcionRecipiente` — recipiente marcable con su estado.
- `AdaptacionInfantil` — bloque desplegable de la adaptación del niño.
- `CompraQuincenalHeader`, `CategoriaCompra`, `ItemCompra` (con acciones/precio/subtotal).
- `DetalleFamiliarPanel` — hoja/modal secundaria con cantidades por persona.
- `TuAlimentacionHoyCard` — widget del dashboard.

Reutilizados: `VitaCard`, `Eyebrow`, `ErrorEnTarjeta`, `AppColors`, `AppSpacing`.

---

## 17. Criterios de aceptación (visual y funcional)

Se dará por correcto solo si cumple **todos**:

1. En escritorio **no** parece app móvil ampliada. 2. Aprovecha el ancho (2–3 col).
3. La semana se ve casi completa sin scroll largo. 4. Hoy muestra la **próxima acción**.
5. Juan **no** domina la pantalla (macros/nombre ocultos en secundario). 6. Juan Miguel
integrado por **adaptaciones**. 7. Se sabe **cuántos recipientes** preparar. 8. Cada
recipiente es **marcable**. 9. El domingo hay **guía paso a paso** (cronograma).
10. Los desayunos dicen qué se **adelanta** y qué se hace **al momento**. 11. Compras con
**período y fecha**. 12. Se puede **elegir el día** de compra. 13. **Unidades reales** de
supermercado. 14. Seguimiento `comprado/ya tengo/sustituir`. 15. El **dashboard** muestra
la alimentación del día. 16. No depende de **emojis** para el diseño. 17. Coherente con VITA.
18. No parece Excel. 19. No parece recetario. 20. No parece colección de listas.

**Funcionales extra:** estados persisten (no se pierden al recargar); marcar en Menú se
refleja en Hoy y en el widget; el cierre de macros (±5% · prot ≥ meta) se mantiene para
Yurby y Juan; regenerar semana es determinista.

---

## 18. Archivos actuales a modificar o reemplazar

| Archivo | Acción |
|---|---|
| `presentation/alimentacion_screen.dart` | **Reescribir** (nueva arquitectura de 4 vistas + grilla) |
| `presentation/alimentacion_controller.dart` | **Ampliar** (estados, recipientes, compra quincenal, familia) |
| `data/alimentacion_repository.dart` | **Ampliar** (planes, estados, recipientes, compras, precios) |
| `domain/motor.dart` | **Ampliar** (unidades de compra humanas, período quincenal, recipientes, cronograma) |
| `domain/biblioteca_seed.dart` | **Enriquecer** (platos reales: cocción/salsa/acompañamiento/bebida/esfuerzo/adaptación infantil/unidad de compra) |
| `domain/alimentacion.dart` | **Ampliar** entidades (`Ensamble`: cocción, salsa, acompañamiento, vegetales, bebida, conservación, esfuerzo, `AdaptacionInfantil`; `Alimento`: unidad de compra + factor) |
| `domain/cocina_familiar.dart` | **Reencuadrar** (de "plan del niño" a "adaptación por plato" + porción infantil) |
| `core/router/app_router.dart` | Ruta intacta; el módulo cambia por dentro |
| `core/widgets/app_shell.dart` | Pestaña "Comida" intacta |
| `features/mi_vida/presentation/mi_vida_screen.dart` | **Añadir** `TuAlimentacionHoyCard` (widget dashboard) |
| `docs/diseno/VITA_Alimentacion_*.md` | Actualizar coherencia (niño 5 años, platos reales, compras humanas) |

---

## 19. Cambios en DATOS y TABLAS (migración `0018`, forward-only)

`0017` no se edita. `0018` añade:

- **`nutrition_plans`** — semana/quincena: `fecha_inicio`, `fecha_fin`, `estado`.
- **`nutrition_plan_meals`** — comida por (plan, fecha, momento): `assembly_id`,
  `estado` (§10), `alternativa_id`, marcas de tiempo (llevado/comido).
- **`nutrition_recipientes`** — porción física por (plan_meal, persona): `estado` (§11),
  `etiqueta`, `ubicacion`, `fecha_congelacion`, `fecha_descongelar`, `fecha_max`.
- **`nutrition_shopping`** — compra: `tipo` (`quincenal`|`reposicion`), `periodo_inicio/fin`,
  `fecha_recomendada_ini/fin`, `fecha_elegida`, `estado`, `presupuesto`, `pct_comprado`.
- **`nutrition_shopping_items`** — `food_id`, `cantidad`, `unidad_humana`, `comprado`,
  `ya_tengo`, `sustituto`, `precio`, `categoria`.
- **Ampliar `nutrition_foods`**: `compra_unidad` (`unidad`|`kg`|`litro`|`paquete`|`bandeja`),
  `compra_factor` (g o ml por unidad de compra), `redondeo`.
- **Ampliar `nutrition_assemblies`**: `coccion`, `condimentos`, `salsa`, `acompanamiento`,
  `vegetales`, `bebida`, `conservacion`, `esfuerzo`, y `adaptacion_infantil` (JSONB o tabla
  hija `nutrition_child_adaptations`).
- **Familia**: `nutrition_profiles.es_nino boolean` + permitir `objetivo = 'nino'`
  (o tabla `nutrition_family_members`). Juan Miguel deja de ser solo constante en código.
- **Calendario**: sin tabla nueva; se usa el feature `agenda` para el recordatorio de compra.

Todas con RLS `user_id = auth.uid()`, triggers `updated_at`, e idempotencia (patrón `0017`).

---

## 20. Plan de implementación por fases

> Cada fase entra con `flutter analyze` sin warnings nuevos, tests en verde y `main`
> desplegable. Se avanza fase por fase, con tu revisión entre medio.

- **Fase 0 — Datos y contenido.** Migración `0018` (estados, recipientes, compras
  quincenal, `es_nino`, riqueza de platos, unidades de compra). Enriquecer la biblioteca
  con platos reales (§6) y adaptaciones infantiles. Unidades humanas en el motor.
- **Fase 1 — Andamiaje responsive.** `AlimentacionScaffold` + breakpoints; grilla base de
  las 4 vistas (sin lógica de estados aún). Aquí ya "no parece app móvil estirada".
- **Fase 2 — Hoy operativo.** `ComidaFila`, `EstadoChip`, `AccionSiguiente`, recipientes de
  hoy, marcar `llevé/comí`; columna "Organización de hoy".
- **Fase 3 — Menú cuadrícula.** `DiaMenuCard` con estados y marcado directo; `Cambiar`.
- **Fase 4 — Preparar.** Resumen + Cronograma inteligente (paralelo, dependencias,
  adaptación infantil) + Porcionado marcable + Desayunos (adelanto/al momento).
- **Fase 5 — Compras quincenal.** Header con período/fecha/selector de día + recordatorio
  en calendario; categorías con unidades humanas y seguimiento (comprado/ya tengo/
  sustituir/precio/subtotal); reposición de frescos.
- **Fase 6 — Dashboard.** `TuAlimentacionHoyCard` en Mi Vida (vía `core`).
- **Fase 7 — Pulido premium.** Densidad, jerarquía, iconografía coherente, responsive
  tablet/móvil, verificación contra los 20 criterios (§17).

---

**Espero tu aprobación de este rediseño antes de escribir una sola línea de código.**
Si algo del flujo, la jerarquía o el alcance no calza con lo que imaginas, lo ajusto aquí
—en el diseño— antes de construir.
