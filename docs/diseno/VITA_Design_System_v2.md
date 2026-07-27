# VITA · Design System v2 — Sistema visual (Fase A)

> **Estado:** propuesta para aprobación. **No se implementa en Flutter** hasta el
> visto bueno. Este documento es la **fuente única** de color, tipografía,
> espaciado, radios, iconografía, componentes, navegación, patrones responsive y
> plantillas de composición. Ninguna pantalla vuelve a definir valores sueltos:
> todo depende de **tokens globales**.
>
> **Sensación buscada:** luminosa, viva, femenina sin ser infantil, moderna y
> premium. VITA debe **dar ganas de abrirla**. Nada de crema amarillento, negro
> dominante ni interfaces grises; nada saturado ni infantil. Base clara de marfil
> muy suave con acentos con vida.

---

## 1. Principios de marca

- **Calma con energía.** Superficies limpias y aire; el color aparece como
  acento vivo, no como bloque saturado.
- **Un producto, no muchas apps.** Todos los módulos comparten tokens, tipografía,
  botones e iconos; solo cambia la **plantilla de composición** (§10).
- **Luminosa, no plana.** Base marfil/porcelana muy clara; profundidad por
  **jerarquía y hairlines**, no por sombras pesadas ni cajas grises.
- **Femenina y premium.** Verde jade mineral + una familia de acentos cálido-fríos
  (coral, cielo, lavanda, oro, terracota) apenas insinuados en los fondos de módulo.

---

## 2. Color — paleta completa (HEX + uso exacto)

### 2.1 Neutros — base luminosa (nunca amarilla, nunca gris dominante)

| Token | HEX | Uso |
|---|---|---|
| `--bg` | `#F5F6FA` | Fondo principal de la app (porcelana luminosa, leve frío) |
| `--surface` | `#FFFFFF` | Tarjetas y paneles |
| `--surface-sunken` | `#EEF0F7` | Rellenos suaves: chips, inputs, campos, celdas |
| `--surface-elev` | `#FFFFFF` + sombra `--shadow` | Superficie elevada/flotante (menús, hojas) |
| `--hairline` | `#E6E8F1` | Bordes y divisiones suaves |
| `--hairline-strong` | `#D8DBE8` | Divisiones que necesitan más presencia |
| `--ink` | `#22263A` | Texto primario (índigo-carbón, **no** negro puro) |
| `--ink-2` | `#565B72` | Texto secundario |
| `--muted` | `#8B90A6` | Texto terciario / metadatos / iconos apagados |

### 2.2 Marca — verde jade mineral

| Token | HEX | Uso |
|---|---|---|
| `--brand` | `#17A088` | Color de marca (acento vivo) |
| `--brand-deep` | `#0E7C68` | Estado **activo**/hover/pressed; texto de marca sobre blanco (AA) |
| `--brand-soft` | `#7ECBBB` | Iconos decorativos, trazos suaves |
| `--brand-wash` | `#E4F5F0` | Fondo apenas tintado (secciones de marca) |

### 2.3 Estados semánticos (separados del acento)

| Token | HEX | Uso |
|---|---|---|
| `--success` | `#1E9E76` | Confirmación, positivo |
| `--warning` | `#C8992F` | Advertencia (oro apagado) |
| `--danger` | `#CF5A44` | Error/destructivo (terracota controlada, **no** rojo fuego) |
| `--info` | `#3E86C4` | Información |

### 2.4 Familia de acentos por área (cada módulo su color, apenas tintado)

Cada acento trae `base` (línea/acento), `wash` (fondo apenas tintado) y `deep`
(texto/estado sobre claro, accesible).

| Acento | base | wash | deep | Área |
|---|---|---|---|---|
| **Jade** (marca) | `#17A088` | `#E4F5F0` | `#0E7C68` | **Mi Vida** (centro) · Salud |
| **Coral** | `#F4785C` | `#FDEDE8` | `#D85A3E` | **Comida** (energía) |
| **Cielo** | `#3E86C4` | `#E7F1FA` | `#2C6EA6` | **Calendario** / trabajo |
| **Lavanda** | `#9B84D9` | `#F0EBFB` | `#7C63C0` | **Mi Mes** / reflexión |
| **Oro** | `#C8992F` | `#F7F0DE` | `#A67C1E` | **Finanzas** / logros |
| **Petróleo** | `#2A7B8C` | `#E6F1F4` | `#1F5E6C` | **Proyectos** |
| **Terracota** | `#C56A4E` | `#F8E9E2` | `#A9503A` | Alertas suaves / **Hogar** |

**Reglas de uso del color:**
- Los fondos de módulo son **apenas tintados** (usar `wash`, nunca el `base` como
  bloque). El color vive en acentos: eyebrow, línea, icono, punto de estado.
- El texto siempre en `--ink`/`--ink-2`; el color de área nunca se usa como fondo
  de texto largo.
- **Contraste:** `--ink` sobre `--bg`/`--surface` ≥ 7:1; `deep` de cada acento
  sobre blanco ≥ 4.5:1 para texto; `base` solo para elementos ≥ 24 px o decorativos.

### 2.5 Modo oscuro (opcional, nunca obligatorio)

Se define después de aprobar el claro, con los mismos tokens semánticos
(`--bg #14161C`, `--surface #1C1F27`, `--ink #ECEEF5`, marca `#3BBBA2`, acentos
suavizados). El claro es el modo por defecto y el que aprobamos primero.

---

## 3. Tipografía

- **Familia:** Inter (ya en el repo). Una sola familia, jerarquía por tamaño/peso.
- **Escala** (px / peso / tracking):

| Rol | Tamaño | Peso | Tracking |
|---|---|---|---|
| Display (hero saludo) | 24–28 | 600 | -0.5 |
| Título de pantalla | 22 | 650 | -0.4 |
| Sección | 18 | 650 | -0.2 |
| Subtítulo/lista fuerte | 16–17 | 600 | 0 |
| Cuerpo | 15 | 400/500 | 0 |
| Secundario | 13.5 | 400 | 0 |
| Caption/metadato | 12.5 | 500 | 0 |
| Eyebrow | 11 | 700 | +1.4 (MAYÚS) |

Números tabulares (`tabular-nums`) en tablas, montos y horas.

---

## 4. Espaciado, radios, sombras, bordes

- **Espaciado** (base 4): `4 · 8 · 12 · 16 · 24 · 32 · 48`. Ritmo de secciones: 32.
- **Radios:** `sm 10` (chips/inputs) · `md 14` (botones/campos) · `lg 20`
  (tarjetas/paneles) · `pill 999`. **Nada de 5/6/13/22 sueltos.**
- **Sombras:** por defecto **elevación 0** (profundidad con hairline). Una sola
  sombra premium para lo verdaderamente flotante: `0 2px 8px rgba(34,38,58,.05),
  0 14px 34px rgba(34,38,58,.06)`.
- **Bordes:** `1px --hairline`. `--hairline-strong` solo para separar zonas.

---

## 5. Iconografía

- **Un solo set:** iconos de línea (stroke 1.7, esquinas redondeadas), tamaño
  18/20/24. Color `--muted` (inactivo) o color de área (activo).
- **Emojis:** solo donde aportan emoción real (estado de ánimo, comida de fin de
  semana). Nunca como iconografía estructural.

---

## 6. Botones (un estilo por jerarquía)

| Tipo | Aspecto |
|---|---|
| **Primario** | Relleno `--brand` (o color de área), texto blanco, radio `md`, alto 48, peso 600 |
| **Secundario** | Contorno `1px --hairline-strong`, texto `--ink`, mismo alto |
| **Terciario / enlace** | Texto `--brand-deep`, sin fondo, con chevron cuando navega |
| **Destructivo** | Texto/relleno `--danger` según peso de la acción |
| **FAB** | **Único patrón:** extendido con icono + etiqueta; color de área |

Nunca tres estilos para la misma jerarquía. `backgroundColor` nunca se repite a
mano: sale del tema.

---

## 7. Inputs, tarjetas, listas, estados

- **Inputs:** `--surface-sunken`, sin borde, radio `md`, alto consistente, foco con
  anillo `--brand`. Igual en toda la app.
- **Tarjetas/superficies:** `--surface`, radio `lg`, `1px --hairline`, elevación 0.
  **Evitar tarjeta-dentro-de-tarjeta:** agrupar por secciones internas con hairlines
  dentro de **un** panel (ver §9 contexto).
- **Listas:** mismo ritmo (fila con hairline superior, padding vertical 12–14),
  iconografía consistente.
- **Estados vacíos:** un solo patrón, transmiten calma (nunca error): icono suave +
  frase humana + **qué hacer**.
- **Loading:** un solo spinner (sin colorear salvo en contexto de área). **Error:**
  `ErrorEnTarjeta` + `mensajeDeError` (ya existente), sin jerga técnica.

---

## 8. Navegación

- **Barra inferior** idéntica en toda la app (ya centralizada). El **icono/color
  activo** usa el color del área.
- **Encabezados:** misma lógica — título a la izquierda, `titleSpacing` unificado;
  el saludo/hero editorial reemplaza al AppBar seco **solo** en Home operativo.
- **Mi Vida es el centro:** los bloques enlazan a su módulo ("Ver calendario",
  "Ver comida", "Ver mes"); los módulos no necesitan un botón de volver (la barra
  inferior lo resuelve), pero comparten el mismo lenguaje.

---

## 9. Patrón de "contexto unificado" (clave)

La columna/zona de contexto **no** es una colección de tarjetas. Es **un solo
panel** (`--surface`, radio `lg`) con **secciones internas** separadas por
hairlines. Cada sección lleva un eyebrow con el color de su área. Así se elimina
"tarjeta por cada cosa", bordes repetidos y radios excesivos.

---

## 10. Plantillas de composición (NO una sola para todo)

Todas comparten tokens/tipografía/botones/iconos, pero **distinta distribución**:

- **A · Home operativo** (Mi Vida): hero compacto → **foco** (prioridades) →
  detalle (agenda) → **panel de contexto unificado** (§9). Escritorio 2 zonas
  (≈62/38); tablet reorganiza; teléfono 1 columna, foco primero.
- **B · Datos densos** (Finanzas): **resumen/KPIs** arriba → **navegación
  secundaria** (segmentos) → **contenido denso** (lista/tabla) + contexto de
  presupuesto/cuentas. Es un **dashboard**, no cards apiladas.
- **C · Tiempo** (Calendario): **controles temporales** (mes/semana + navegación) →
  **vista principal** (grilla/agenda) → **panel contextual** (día seleccionado /
  pendientes). Estilo Notion/Google Calendar.
- **D · Proceso** (Cocina de la semana): **progreso** → **pasos** → **detalle
  contextual**.
- **E · Colección** (Proyectos/metas/créditos): **resumen** → **rejilla/lista
  adaptativa** (1–3 columnas según ancho).
- **F · Configuración** (Ajustes): **navegación lateral** (escritorio) o **grupos
  claros** (móvil) + contenido; sensación premium, no temporal.

---

## 11. Patrones responsive (diseñado por dispositivo, no estirado)

- **Escritorio (≤1400 px útiles):** 2 zonas (principal + contexto). Densidad buena,
  sin espacios muertos ni desperdiciar el 40%.
- **Tablet:** **reorganiza**, no encoge. Puede ser híbrido (principal ancho +
  contexto debajo o a un lado equilibrado). Toques amplios; contenido principal
  **antes** que el contexto; sin tarjetas estrechas.
- **Teléfono:** **1 columna**. Encabezado **compacto**. **Acción principal
  primero.** Prioridades fáciles de marcar; agenda resumida; contexto plegable.
  Barra inferior sin tapar contenido; **sin scroll horizontal**.

---

## 12. Accesibilidad

- Contraste AA (texto ≥ 4.5:1, UI ≥ 3:1). Toques ≥ 48 dp. Texto escalable.
- Foco visible (anillo `--brand`). Respeta *reduced motion*. Color nunca es el
  único portador de significado (siempre icono/etiqueta acompaña al estado).

---

## 13. Qué se reutiliza / modifica / sustituye (mapa)

| Actual | Acción |
|---|---|
| `core/theme/app_colors.dart` | **Sustituir** valores por estos tokens (crema → porcelana; añadir familia de acentos por área) |
| `core/theme/app_theme.dart` | **Modificar** (mapear ColorScheme + botones/inputs a los tokens nuevos) |
| `core/theme/app_spacing.dart` | **Modificar** (radios `sm/md/lg` + escala) |
| `VitaCard`, `Eyebrow`, `ErrorEnTarjeta` | **Reutilizar** (ajustan color vía tokens) |
| Pills/badges (7 versiones) | **Sustituir** por un componente único con color de área |
| Estados vacíos (4 layouts) | **Sustituir** por un patrón único |
| Paleta local `_Tok` de Comida | **Eliminar** (usa el tema global) |
| Composición de cada pantalla | **Rediseñar** según su plantilla (§10), sin tocar lógica/navegación/datos |

---

## 14. Estado de esta Fase A

- [x] Sistema cromático (§2) — **para tu revisión ahora**.
- [x] Tokens, tipografía, espaciado, plantillas, responsive (§3–§11).
- [ ] Mi Vida v2 (prototipo, 3 dispositivos) — **entregado con este documento**.
- [ ] Prototipos de referencia: Calendario, Finanzas, Comida, Proyectos, Ajustes.
- [ ] Specs finos de componentes (botón/input/tabla) — se cierran tras aprobar color.

> El color es la **puerta**: si la base luminosa y la familia de acentos te
> convencen en Mi Vida v2, extiendo el sistema a los prototipos de referencia
> (Calendario y Finanzas primero, por ser los casos más distintos) antes de tocar
> Flutter.
