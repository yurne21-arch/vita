# VITA — Alimentación · Biblioteca maestra (borrador vivo, modelo por componentes)

> **Modelo:** INGREDIENTES → **PREPARACIONES** (se cocinan en tanda) → **ENSAMBLES**
> (comidas servidas). Se cocina poco y de ahí salen muchas comidas distintas.
> Solo comidas reales de Yurby + Juan, con sus ingredientes, simples, **aliño base
> suave** (el aliño fuerte se agrega al ensamblar, por porción).
> Estado: ✅ ok · ✏️ ajustar · ❌ quitar · (vacío = revisar).

Etiquetas del motor: `congelable` · `<30min` · `meal_prep` · `solo_finde` ·
`favorita` · `económica` · `alta_proteína` · `invitados` · `rápida` · `usa_despensa`.

---

## A) PREPARACIONES base (lo que se cocina en tanda)

### Proteínas
| Prep | Proteína | Etiquetas | ❄️ |
|---|---|---|---|
| Pollo a la plancha | pollo | meal_prep, alta_proteína, económica | ❄️ |
| Pollo desmenuzado (guiso suave) | pollo | meal_prep, económica, favorita | ❄️ |
| Pollo al horno | pollo | meal_prep, invitados | ❄️ |
| Carne a la plancha | vacuno | alta_proteína | ❄️ |
| Carne mechada | vacuno | meal_prep, favorita | ❄️ |
| Carne al horno | vacuno | invitados | ❄️ |
| Carne molida / boloñesa | molida | meal_prep, económica | ❄️ |
| Atún (mezcla con cebolla) | atún | rápida, <30min, económica | |
| Salmón a la plancha/horno | salmón | alta_proteína | |
| Cerdo *(ocasional)* | cerdo | — | ❄️ |
| Huevo (revuelto/plancha/perico) | huevo | rápida, <30min · **≤2–3/sem** | |
| Caraotas *(ocasional)* | legumbre | económica | ❄️ |
| Lentejas *(ocasional)* | legumbre | económica | ❄️ |

### Bases (carbohidrato)
Arroz `meal_prep, económica ❄️` · Papa (cocida/al horno) · Pasta · **Arepa**
`favorita` · Puré *(poco)*.

### Verduras
Ensalada base (tomate, pepino, zanahoria) `rápida` · Verduras salteadas
(zanahoria, pimentón, brócoli) · Brócoli al vapor.

### Frescos / extras
Queso · quesillo · queso blanco · jamón · palta · tomate · choclo · plátano
*(tajadas ocasional)*.

---

## B) DESAYUNOS (salados · huevo ≤2–3/sem · nunca dulce)
Arepa con: **quesillo · queso · queso derretido · jamón y queso · carne mechada ·
pollo desmenuzado · atún · palta y tomate**. · Tostadas **jamón y queso**. ·
Tostada palta/tomate/quesillo. · **Queso blanco a la plancha con tomate**. ·
**Paquecas/wafles con queso** (salado). · Perico con arepa *(huevo)*. · Huevo a la
plancha + palta + arepa *(huevo)*. · Sándwich de pollo desmenuzado.

## C) ALMUERZOS (Lun–Vie · generados desde las preparaciones)
Pollo: **+ arroz + ensalada · + solo ensalada · + pasta · salteado con verduras ·
al horno · desmenuzado + arroz + brócoli**. Carne (vacuno): **a la plancha + arroz ·
al horno · + solo ensalada · + pasta · mechada**. Molida: **boloñesa · + papas +
choclo**. Atún: **pasta con atún**. Salmón: **+ papas + brócoli · + arroz +
ensalada**. Lasaña **de carne** / **de pollo**. Caraotas con pasta y tajada
*(ocasional)*. Lentejas *(ocasional)*.
*(Quitados: mechada+arroz+tajadas como fija — tajadas solo especial; cerdo+puré —
cerdo muy ocasional y puré poco.)*

## D) MERIENDAS (livianas · última comida antes del ayuno · **no siempre pan/arepa**)
Fruta sola · Fruta + queso/quesillo · **Plátano con leche** · Batido de leche con
fruta *(ocasional)* · **1 proteína rica + leche** (batido/snack proteico que sepa
rico) · Arepa/pan chico *(ocasional, no la base)*.

## E) FIN DE SEMANA (Sáb–Dom · cocina Juan · variado y elaborado)
Pastas distintas (varias salsas) · **Parrilla** · Pollo entero al horno · Carne al
horno · Costillar *(ocasional)* · **Pizza casera** · **Empanadas caseras** · Arroz
chino casero · **Fajitas** · **Tacos** · **Shawarma casero** · Milanesa de
pollo · Hamburguesas caseras · Venezolana ocasional (pabellón, etc.).

---

**Cómo se ve en la práctica ("compré pollo"):** el motor cocina *pollo desmenuzado*
+ *pollo a la plancha* el domingo, y durante la semana genera: pollo+arroz+ensalada
(lun), arepa con pollo (desayuno mar), pollo+pasta+verduras (mar), mini sándwich de
pollo (merienda mié), pollo+solo ensalada (jue)… misma compra, cero sensación de
repetir. Igual con carne, molida, salmón.
