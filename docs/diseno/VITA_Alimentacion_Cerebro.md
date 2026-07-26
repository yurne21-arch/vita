# VITA — Alimentación Inteligente · El cerebro nutricional (diseño)

> **Estado:** diseño, **sin construir**. Módulo "Nutrición" del roadmap (MASTER §6).
> **Regla de oro:** esto **no es un recetario ni una app de dieta**. Es un sistema
> operativo nutricional **automático** que minimiza decisiones, tiempo de cocina y
> desperdicio. La calidad del sistema depende **100% de la biblioteca de comidas
> reales** de la usuaria — por eso se construye la biblioteca ANTES de programar.

---

## 0. Principios (no negociables)

Gobiernan cada regla del motor:

1. **Cocinar lo menos posible entre semana.** El motor agrupa la cocina en 1–2
   días de *meal prep* y reutiliza preparaciones.
2. **Una sola preparación sirve para todos.** Lo único que cambia son las
   **porciones** por integrante (multiplicador de porción). Nunca "un plato para
   ella y otro distinto para él".
3. **Nada de comida "fitness" ni ingredientes que no le gustan.** La biblioteca
   solo contiene comidas que ella comería durante años.
4. **Ventana de alimentación 7:00–16:00** (configurable). El motor solo agenda
   momentos dentro de la ventana.
5. **Compra quincenal por defecto** (cada 15 días); el meal prep resuelve la
   conservación de la segunda semana (congelar / descongelar).
6. **Cero decisiones diarias.** Una sola pantalla responde: *¿qué como hoy?, ¿qué
   cocino hoy?, ¿qué compro?*
7. **Funciona sin IA.** El motor es un **sistema de reglas determinista**
   (gratis, MASTER §11). La IA es una mejora futura (mejores combinaciones,
   aprender gustos), nunca un requisito.

---

## 0.b Reglas específicas de la usuaria (capturadas 2026-07)

- **Ayuno 7–16.** Desayuno ~07:00, almuerzo 12:30–13:30, merienda 15:30–16:00.
  **Sin media mañana fija**: solo aparece como excepción si al día le faltan
  calorías/proteína.
- **Desayunos salados** (nunca dulces). Prohibido: pancakes de avena, bowls de
  yogurt, granola, y en general "desayuno dulce/fitness".
- **Huevos 2–3 veces por semana**, no todos los días.
- **Entre semana vs fin de semana:** Lun–Vie = *meal prep* (reutilizar,
  mínima cocina, prep fuerte el **domingo**, prep chica opcional el **miércoles**).
  **Sáb–Dom = recetas variadas y frescas** (cocina el esposo, quiere variar): el
  motor prioriza **variedad**, no reutilización, esos dos días.
- **Una preparación para los dos, distinta porción.** Juan solo baja 2–3 kg
  (déficit suave); ella déficit mayor. Misma comida, `factor_porcion` distinto
  (Juan porción mayor → más calorías).
- **Aliño suave.** A Juan no le gustan mucho los aliños → **preparaciones base
  poco aliñadas**; el aliño fuerte se agrega **al final por porción**. (Nuevo
  campo en `Comida`: `aliño_base` = suave, con `aliños_al_final` opcionales.)
- **Simplicidad:** pocas recetas complicadas, pocos ingredientes por comida,
  nada de ingredientes difíciles de conseguir.

## 0.c Biblioteca de alimentos (capturada)

- **Proteínas** (favoritas): pollo *(principal)*, vacuno, carne molida, atún,
  salmón; cerdo *(ocasional)*; huevos *(2–3/sem)*. **Evitar:** mariscos, cordero.
- **Verduras** (que sí come): tomate, pepino, zanahoria, brócoli, pimentón,
  cebolla *(en preparaciones)*, palta, choclo. *Meta: comer más verduras, pero
  de estas.*
- **Carbohidratos:** arroz, papas, pasta, **arepas** *(favoritas)*, pan *(a
  veces)*. **Evitar como base:** quinoa, avena, camote, "fitness".
- **Frutas:** manzana, plátano, frutillas, uvas.
- **Lácteos:** leche, queso, quesillo. **Yogurt: no como base.**
- **Prohibido/nunca:** lo que ella marcó como "no me gusta" — el sistema jamás
  lo sugiere y **aprende** con el tiempo (feedback).

## 0.d Los 10 principios del motor (validados 2026-07)

Estas son las **leyes** del cerebro. Todo lo de abajo las implementa.

1. **Piensa en PRODUCCIONES, no en recetas.** Planifica primero qué cocinar en
   tanda (domingo); las comidas de la semana **se ensamblan** de ahí. (§2 paso 2,
   §2.1)
2. **Aprende de la usuaria.** Sube la prioridad de lo que repite (→ favorita),
   baja la de lo que nunca elige; con el tiempo acierta más. Recomendador
   **determinista** (sin IA). (§2.2)
3. **Nunca cocinar dos comidas distintas.** Una sola preparación para toda la
   familia; **solo cambian las porciones** por objetivo (`factor_porcion`).
4. **Optimiza las compras como un administrador.** Reutiliza ingredientes, reduce
   desperdicio, agrupa comidas que comparten ingredientes; a futuro, aprovecha
   ofertas/precios para sugerir recetas más convenientes. (§2.5)
5. **Cada comida tiene metadatos inteligentes** (§1.2): esfuerzo, tiempo real,
   utensilios, si ensucia, si genera sobrantes, si congela, rinde, días en refri,
   si es reutilizable.
6. **Se adapta a la realidad.** Día cansada → algo rápido con lo ya preparado.
   Modo **"Hoy no tengo ganas de cocinar"** = solo congelados, listos, <10 min o
   ingredientes ya preparados. (§2.3)
7. **Ingredientes antes que recetas.** Con lo que hay en despensa, genera todas
   las combinaciones posibles **antes** de mandar a comprar. (§2.3)
8. **Siempre piensa en el objetivo nutricional.** Verifica solo que el día cierre
   en calorías y macros; la usuaria **nunca** calcula nada, solo come lo que VITA
   indica. (§2 paso 3, §2.4)
9. **Cambia de objetivo sin cambiar recetas.** El mismo motor sirve para déficit,
   mantención, ganancia, **embarazo, lactancia, adultos mayores**: cambian las
   **porciones y la distribución de macros**, no las recetas. (§2.4)
10. **Se siente como un asistente personal**, no como una dieta. La usuaria solo
    ve: qué comer, qué cocinar, qué comprar, qué descongelar, qué preparar el
    domingo. (§3)

## 1. Arquitectura de datos (la biblioteca es el corazón)

Tres bibliotecas + perfiles. Todo lo demás (planes, listas, prep) se **calcula**.

### 1.1 `Alimento` — biblioteca de alimentos
El "átomo". Un ingrediente comprable.
- `id`, `nombre`, `categoria` (Carnes · Verduras · Frutas · Lácteos · Congelados ·
  Despensa · Condimentos) — categorías = secciones de la lista de compras.
- `unidad_compra` (ej. kg, docena, paquete) + `unidad_uso` (ej. g, unidad) +
  `factor` de conversión.
- `precio_estimado` por `unidad_compra` (CLP).
- `macros_por_100` : { kcal, prot, grasa, carb }.
- `se_congela` (bool), `vida_refrigerado_dias`, `vida_congelado_dias`.

> **Modelo en 3 niveles (corregido 2026-07):**
> **PRODUCCIÓN BASE → TERMINACIÓN → ENSAMBLE.**
> - **Producción base:** lo que se cuece una vez (ej. *pollo cocido*, *carne
>   cocida*, *arroz*).
> - **Terminación:** cómo se remata una parte de esa base (ej. del *pollo cocido*:
>   una parte *a la plancha*, otra *desmenuzada*). **No cuenta como una producción
>   nueva** → así medimos bien cuántas producciones reales hay el domingo.
> - **Ensamble:** la comida servida (ej. *arepa con pollo*, *pollo con arroz*).
> Cada nivel guarda su tiempo/esfuerzo; el domingo se miden **producciones base**,
> no ensambles.

> **Cambio de concepto (clave):** el motor NO piensa en "recetas fijas". Piensa en
> **INGREDIENTES → PREPARACIONES (componentes) → ENSAMBLES (comidas)**. Se cocinan
> pocas preparaciones base y de ahí se **generan** muchas comidas distintas. Así,
> "compré pollo" produce solo: pollo+arroz, pollo+ensalada, pollo+pasta, arepa con
> pollo, mini sándwich, pollo salteado… sin sentir que se come lo mismo.

### 1.2 `Preparacion` — componente base (el nuevo corazón)
Lo que se cocina en **tanda (batch)**. No es un plato servido; es una **pieza**
reutilizable.
- `id`, `nombre` (ej. "pollo desmenuzado", "pollo a la plancha", "carne mechada",
  "boloñesa", "arroz", "papa cocida", "ensalada base").
- `proteina_principal` (o `null` si es carbo/verdura).
- `ingredientes` : `{ alimento_id, cantidad_base, unidad }` — rinde **1 porción**.
- `aliño_base` = **suave** (los aliños fuertes se agregan **al ensamblar**, por
  porción — así una misma tanda sirve para Yurby y para Juan).
- `etiquetas` (§1.6).
- `tipo` : `base` | `terminación` (+ `deriva_de` = producción base de la que sale).
- `frecuencia` : `favorita_frecuente` | `frecuente` | `ocasional` | `solo_finde` |
  `antojo_planificado`. (Ej.: arepa salada = frecuente; **paquecas con queso =
  ocasional**; carne mechada **no obligatoria semanal** → alternar con plancha /
  horno / molida según esfuerzo disponible.)
- **Metadatos inteligentes** (el motor decide con estos):
  - `tiempo_real_min` (no "teórico": lo que de verdad toma).
  - `nivel_esfuerzo` (1–5).
  - `num_utensilios` y `ensucia` (poco/medio/mucho) → carga de lavado.
  - `rinde_porciones` (por tanda) y `genera_sobrantes` (bool).
  - `se_congela`, `vida_refrigerado_dias`, `vida_congelado_dias`.
  - `reutilizable` (bool) → sirve como pieza de otros ensambles.
- **Derivados:** macros y costo por porción (de sus ingredientes).

### 1.3 `Ensamble` — una comida servida (componentes + frescos)
Un **momento** + combinación de preparaciones + elementos frescos = plato.
- `id`, `nombre` (ej. "Arepa con pollo desmenuzado", "Pollo + arroz + ensalada").
- `momento` : desayuno | almuerzo | merienda | finde. *(Sin cena, ventana 7–16.)*
- `componentes` : `[preparacion_id…]` + `frescos` `[alimento…]` (arepa, pan, palta,
  tomate…).
- `etiquetas`. Puede ser **curado** (favoritos, finde elaborado) o **generado**
  por la gramática (§1.4).

### 1.4 Gramática de ensamble (las reglas para *generar* comidas)
El motor **arma** comidas válidas por momento (no elige de una lista cerrada):
- **DESAYUNO_SALADO** = base *(arepa | pan | tostada | paqueca/wafle salado)* +
  relleno *(queso | jamón+queso | quesillo | queso derretido | palta+tomate |
  proteína_prep [pollo/mechada/atún] | huevo\*)*. \*huevo ≤ 2–3/sem. **Nunca dulce.**
- **ALMUERZO** = 1 `proteína_prep` + 1 carbo *(arroz | papa | pasta)* + 1
  verdura/ensalada. Variante: "solo proteína + ensalada".
- **MERIENDA** (liviana, última comida) = fruta · fruta+lácteo · plátano+leche ·
  proteína_rica+leche · batido *(ocasional)*. **No siempre pan/arepa.**
- **FINDE** (Sáb–Dom, cocina Juan) = receta **elaborada y variada** (parrilla,
  pizza casera, empanadas, lasaña, fajitas, tacos, arroz chino, shawarma, pollo
  entero al horno, venezolana ocasional…). Prioriza **variedad**, no reutilización.

### 1.5 `PerfilNutricional` — por integrante
- `nombre`, `sexo`, `edad`, `estatura`, `peso_actual`, `objetivo`.
- **Cálculo del perfil (provisional hasta calcularlo):** los kcal/macros **no** se
  fijan a mano; se **calculan** desde: sexo · edad · estatura · peso · objetivo ·
  **actividad cotidiana real** (sin ejercicio por ahora en Yurby) · evolución
  reciente del peso · ritmo de pérdida deseado.
- **Se guarda y se puede auditar** (nunca un número "que aparece y ya"):
  `mantenimiento_estimado`, `deficit_aplicado`, `kcal_objetivo`, `macros`
  (prot/grasa/carbo), `fecha_calculo`, `formula_usada`, `motivo_de_cada_ajuste`.
- `ventana` (default 7:00–16:00). `restricciones`, `gustos`, `alimentos_prohibidos`.
- **Porción por comida (no un multiplicador global).** No existe un `factor` fijo
  1,45×. La porción de cada integrante se calcula **por comida** para cerrar **sus
  propias** kcal/macros del día. (En ejemplos se muestra un factor solo para
  ilustrar; en producción es por comida y por persona.)

### 1.6 `Etiqueta` — las etiquetas que deciden
Se ponen en preparaciones **y** ensambles. El motor las **pondera** según
objetivo, tiempo disponible, presupuesto, despensa y planificación:
`congelable` · `<30min` · `ideal_meal_prep` · `solo_finde` · `favorita` ·
`económica` · `alta_proteína` · `para_invitados` · `rápida` · `usa_despensa`
(ya tengo los ingredientes). Ej.: día apurado → prioriza `rápida`/`<30min`;
poco presupuesto → `económica`; despensa llena → `usa_despensa`; domingo →
`ideal_meal_prep`; fin de semana → `solo_finde`.

### 1.7 `Despensa`, `Historial`, `Peso`
- **Despensa:** `{ alimento_id, cantidad_disponible }` — se **descuenta** de la
  lista de compras.
- **Historial:** planes generados (para no repetir y para aprender gustos).
- **Peso y progreso:** serie temporal, ya existe el registro de peso en Salud
  (reutilizar), aquí se cruza con el objetivo.

---

## 2. El motor: "Generar quincena" (piensa en ingredientes, no en recetas)

Un botón. Entra: perfiles + rango + despensa + preferencias. Sale: **menú + lista
+ meal prep + costo + tiempo.** Determinista (sin IA; la IA solo mejora después).

Piensa **al revés que una app de recetas**: primero decide **qué preparaciones
cocinar**, luego **ensambla comidas distintas** con ellas.

1. **Slots** por momento dentro de 7–16 (desayuno, almuerzo, merienda), separando
   **Lun–Vie** (meal prep) de **Sáb–Dom** (variado).
2. **Elegir las preparaciones base de la quincena** (Lun–Vie): un set de proteínas
   + bases (ej. pollo desmenuzado, pollo plancha, carne mechada/boloñesa, arroz,
   ensalada base) dimensionadas para cubrir los días. Prioriza `ideal_meal_prep`,
   `congelable`, `económica` y lo que ya está en despensa (`usa_despensa`).
3. **Generar ensambles Lun–Vie** desde esas preparaciones (gramática §1.4),
   maximizando "se siente distinto": variar formato/carbo/verdura cada día aunque
   la proteína se repita; **nunca el mismo almuerzo dos días seguidos**; cuadrar el
   déficit con la **porción** de cada perfil (Juan porción mayor → menos déficit).
4. **Generar fin de semana** (Sáb–Dom): ensambles `solo_finde` **elaborados y
   variados**; aquí prima la variedad (y `para_invitados` si aplica).
5. **Excepción media mañana:** solo si al día le faltan calorías/proteína, sumar
   una merienda extra liviana.
6. **Agregar ingredientes** de todo (preparaciones × porciones + frescos) → restar
   despensa → **lista de compras por categoría** con cantidades y **costo**.
7. **Plan de meal prep:** qué preparaciones cocinar el **domingo** (y una chica el
   miércoles si hace falta), **cuánto** (Σ porciones de la quincena), **qué
   congelar** (lo que exceda su vida en refri) y **cuándo descongelar**.
8. **Guardar en Historial** (no-repetición + aprendizaje de gustos con el tiempo).

**Por qué así:** la inteligencia vive en las **preparaciones + la gramática + las
etiquetas + los pesos**. Cambiar comidas, agregar alimentos o adaptar (embarazo,
vacaciones, enfermedad) = **editar datos/pesos, no reescribir código**. Es un
nutricionista + chef + comprador, no un recetario.

### 2.1 Producciones (el lote del domingo)
Una **`Produccion`** = el conjunto de preparaciones de una sesión de cocina
(**domingo** fuerte; **miércoles** chica si hace falta). El motor calcula qué
preparar y **cuánto** (Σ porciones de la quincena que lo usan), respetando vidas
(refri/congelado) y una **capacidad razonable** por sesión (no 8 ollas el domingo).
Meta: **mínimas sesiones de cocina** para toda la quincena.

### 2.2 Aprendizaje — `afinidad` (recomendador determinista, sin IA)
Cada preparación/ensamble tiene una `afinidad` (0–1) que se ajusta con eventos del
Historial:
- Elegida y **comida** (no reemplazada) → `+`. Repetida por gusto → `+` (tiende a
  `favorita`).
- **Rechazada/cambiada** al proponerla → `−`. Sin usarse **N semanas** → **decae**.
- 👍/👎 explícito de la usuaria → ajuste fuerte.
El motor pondera candidatos por `afinidad × etiquetas × ajuste-objetivo`.
Transparente y simple; la IA futura solo lo refina, no lo reemplaza.

### 2.3 Modos y contexto (adaptarse a la realidad)
- **Energía de hoy:** normal · cansada · sin-tiempo (entrada rápida).
- **Modo "Hoy no tengo ganas de cocinar":** filtro **duro** → solo congelados ya
  listos, preparaciones ya hechas en refri, ensambles `<10min`, o ingredientes ya
  preparados. **Nada de cocinar de cero.**
- **Cocina con lo que tengo (ingredientes-primero):** antes de proponer compras,
  corre la gramática (§1.4) sobre la **despensa + preparaciones ya hechas** y
  genera todas las comidas posibles con eso. Solo si no alcanza, sugiere comprar.

### 2.4 Objetivo intercambiable (mismo motor, distinta salida)
El objetivo **no cambia las recetas**; cambia **porciones y distribución de
macros**. `objetivo` → `perfil_de_metas` (kcal + reparto prot/grasa/carbo) por
integrante:
- déficit (Yurby) · déficit suave (Juan) · mantención · ganancia.
- **adultos mayores:** mismos platos, metas/porciones ajustadas (más proteína,
  fraccionamiento…) — otro `perfil_de_metas`, sin tocar la biblioteca.
- **embarazo · lactancia (CANDADO):** **no** son "las mismas comidas con otra
  porción". Tienen **reglas nutricionales y de seguridad propias** (nutrientes
  críticos, alimentos a evitar, sin déficit de pérdida de peso). Quedan
  **bloqueados** para configuración/validación **médica profesional**; el motor
  **nunca** activa pérdida de peso en estos modos.
Al ensamblar el día, el motor ajusta la **porción** de cada integrante para cerrar
sus metas; si falta, añade una merienda liviana (excepción media mañana). La
usuaria **nunca ve macros**; solo come.

### 2.5 Compras como administrador (no solo una lista)
- **Consolida** ingredientes iguales de todo el plan en una cantidad de compra.
- **Reduce desperdicio:** prefiere planes donde lo comprado se **consume completo**
  (evita comprar algo para una sola comida si sobra).
- **Agrupa** comidas que comparten ingredientes (la compra rinde más).
- **Resta despensa** antes de comprar.
- **Dos compras, no una** (clave — no comprar 15 días de frescos para botarlos):
  - **Compra principal quincenal:** proteínas, congelados, despensa, leche larga
    vida, y todo lo que **dura 2 semanas** (a futuro, aseo asociado).
  - **Reposición semanal de frescos:** frutas, verduras, palta, pan, quesillo,
    leche fresca — **vida útil corta**.
- **Sabe dónde va cada cosa:** refrigerador vs congelador vs "consumir primero".
  Registra **fecha de preparación** y **fecha límite** de cada preparación.
  **Regla:** preparación refrigerada se consume en **3–4 días** o se **congela a
  tiempo** — nunca se planifica indefinidamente en refri.
- **Futuro (precio-aware):** si un ingrediente baja/está en oferta, sube la
  prioridad de ensambles que lo usan y los sugiere. (Requiere datos de precio; hoy,
  estimado.)

### 2.6 Reglas finas validadas (2026-07)
- **Peso por tendencia, no por semana.** Evalúa la **tendencia de 3–4 semanas** (el
  peso varía por líquidos, ciclo, sal, digestión). Si no avanza, **sugiere** un
  ajuste pequeño; **nunca** recorta agresivo ni **automático**: **muestra el cambio
  antes**. Prioriza adherencia, proteína suficiente, saciedad, energía, masa
  muscular y sostenibilidad — nunca hambre.
- **Seguridad de ajustes.** Cambiar calorías/macros exige: tendencia (no un dato
  aislado) + hambre + energía + adherencia + ciclo + **comidas realmente cumplidas**
  + ≥3 semanas de datos. Todo ajuste importante **se explica antes**.
- **Proteína: practicidad antes que variedad.** Una proteína puede repetirse
  **3–4×/sem** si cambia la presentación (pollo+arroz, ensalada con pollo, arepa con
  pollo, pasta con pollo). No imponer variedad artificial si sube compras,
  desperdicio o trabajo. **Nunca el mismo plato exacto dos días seguidos**, salvo
  aprobación o `favorita`.
- **Capacidad del meal prep (medida).** ≤ 4–5 preparaciones, pero además calcula
  **tiempo activo (~90 min techo)**, esfuerzo, utensilios, **espacio refri/
  congelador** y procesos simultáneos. La cocción pasiva (horno) no cuenta como
  trabajo activo. Miércoles opcional **20–30 min**, solo para reponer frescos o
  terminar una proteína.
- **Aprendizaje con contexto (no castigar el silencio).** No elegir algo **no** baja
  su afinidad si fue por: *no se ofreció / faltaba el ingrediente / mucho trabajo /
  ya comí algo parecido / caso excepcional*. Solo **baja fuerte** con **rechazo real
  o 👎**. Escala por comida: **Me encanta · Me gusta · Me da igual · Solo
  ocasionalmente · No me gusta · Nunca sugerir**.
- **3 momentos, merienda inteligente.** Desayuno ~07:00 · almuerzo ~13:00 · merienda
  15:30–16:00. **Sin media mañana fija**; solo si hay hambre real, falta
  proteína/energía, caso especial, o ella la activa. La **merienda no es siempre
  fruta**: revisa si el día necesita **proteína/saciedad** y elige fruta / leche /
  batido / proteína rica según lo que falte.
- **Contingencia (cada día tiene plan B).** Toda comida principal tiene una
  **alternativa realista**: congelado, sobras, ingredientes disponibles, receta
  **<10 min**, o **compra externa pre-aprobada**. Comer en la calle **no es
  fracaso**: VITA elige una opción compatible y **reajusta** el resto del día.
- **Sobrante planificado (no accidental).** La producción se calcula con: **porción
  Yurby + porción Juan + días + merma + sobrante reservado + reutilización**
  (desayunos/meriendas). Desde que se cocina se sabe **cuánto se reserva** para otra
  comida.

### 2.7 Correcciones finales validadas (2026-07)
- **Solo alimentos aprobados; nunca inventar combinaciones.** El motor rellena
  huecos SOLO con comidas/ingredientes **aprobados** en la biblioteca. Nada de
  "fruta+quesillo" u otros combos no aprobados.
- **Meriendas (lista cerrada):** fruta sola · batido de leche con fruta *(ocasional)*
  · plátano con leche · batido de proteína rico *(opcional)*. **Prohibido** como
  merienda: fruta+queso, fruta+quesillo, quesillo solo.
- **Batidos con tope.** Máx **2 batidos/semana**; el de proteína es **opcional**.
  Primero cerrar macros **ajustando porciones de comidas reales**; proteína en polvo
  solo si es práctica/necesaria. **Pendiente:** elegir una proteína en polvo real,
  revisar ingredientes y **registrar sus macros reales** (no asumir que todas son
  iguales).
- **Conservación asignada desde el domingo** (no "todo al refri"): porciones
  **Lun–Mié → refri**; **Jue–Vie / semana siguiente → congelador**. Cada porción
  guarda `fecha_prep`, `fecha_congelacion`, `fecha_descongelar`, `fecha_max_consumo`.
  Cocido en refri ≈ **3–4 días**; el resto se congela a tiempo.
- **Ensalada concreta, por estados** (no genérica): es una **plantilla** (lechuga,
  tomate, pepino, zanahoria, palta…) y cada semana el motor elige una **combinación
  concreta** aprobada. Distingue verduras **lavadas · cortadas · conservadas
  separadas · que se cortan el mismo día** (palta, tomate) · **aliño solo al
  servir**. No se mezcla toda para 5 días; el corte diario va en la reposición del
  miércoles.
- **Fin de semana concreto** (nunca "pizza/parrilla" ni "liviana"): elige una
  **principal específica** + **alternativa**, con **porciones, ingredientes y efecto
  nutricional**. Ej. Principal: *pizza casera de pollo y vegetales*; Alternativa:
  *parrilla (carne + ensalada + acompañamiento definido)*.

### 2.8 Tolerancias y cierre del día (cómo "cierra" de verdad)
El día **no cierra** por aproximación; cierra dentro de tolerancias explícitas:
- **kcal:** dentro de **±5 %** de la meta.
- **proteína:** **≥** objetivo diario (mínimo; nunca por debajo).
- **grasa:** **≥** mínimo configurado (no bajar).
- **carbohidrato:** completa el resto según la distribución.
Si queda **fuera de tolerancia**, el motor **ajusta una porción aprobada ya
presente ese día** (arroz, arepa, pollo, leche, plátano…) — **nunca inventa otra
comida**. **No** agrega comida solo por calorías si la persona ya está satisfecha;
pero **tampoco declara "cerrado"** si está muy por debajo de la meta. Registra
**qué cantidad ajustó** y por qué.
**Macros auditables:** kcal · proteína · carbohidrato · grasa · **fibra**, **por
comida y total diario, por perfil**. En pantalla van resumidos/ocultos; el motor
los **explica y audita**.

---

## 3. La interfaz (una sola pantalla manda)

Debe sentirse como una **agenda personal**, no como una dieta. Pantalla principal
= *Hoy*, responde de un vistazo:

- **¿Qué me toca comer hoy?** → los momentos del día con su comida y porción.
- **¿Qué debo cocinar hoy?** → si es día de prep: qué y cuánto. Si no: "nada 🎉".
- **¿Qué debo descongelar hoy?** → para que mañana esté listo.
- Atajo a **la lista de compras** (cuando toca comprar).

El resto (biblioteca, perfiles, planificador, despensa, historial, macros) vive
"detrás", se toca poco. La usuaria vive en *Hoy*.

---

## 4. Arquitectura técnica (cuando se construya)

- Feature `features/alimentacion/` (Clean Architecture, aislado; se comunica por
  `core/`). Dominio Dart puro para el **motor de reglas** (testeable sin UI ni DB).
- Tablas Supabase con RLS `user_id = auth.uid()`: `food_items`, `meals`,
  `meal_ingredients`, `nutrition_profiles`, `meal_plans`, `plan_slots`,
  `shopping_lists`, `pantry_items`, `prep_tasks`. Migraciones forward-only.
- **Biblioteca:** el motor no depende de IA. La IA (Motor de IA, MASTER §12),
  cuando exista, solo **propone** mejores combinaciones; la usuaria decide.

---

## 5. Decisiones tomadas por la usuaria (2026-07) + pendientes

**Tomadas:**
- **Integrantes:** **Yurby + Juan** (2 perfiles). Una preparación, distinta
  porción por perfil (`factor_porcion`).
- **Objetivo:** **bajar de peso** — déficit **suave y sostenible**, sin hambre,
  respetando la ventana 7–16.
- **Macros:** **no visibles**. El motor los cuida internamente (referencia); la
  usuaria no los mira.
- **Compra:** **quincenal** (cada 15 días) — compra grande + meal prep que
  congela para la 2ª semana.

**Pendientes:**
1. **Momentos del día:** confirmar desayuno + almuerzo + merienda dentro de 7–16;
   ¿algún "media mañana"?
2. **Biblioteca maestra:** las 40–60 comidas reales — se construye **con ella**
   (en curso, el paso más importante).

---

## 6. Biblioteca maestra — método para construirla con la usuaria

Se llena por rondas fáciles (no pedir 60 comidas de golpe):
1. **Marco:** integrantes, objetivo, ventana, día(s) de cocina preferidos.
2. **Alimentos:** proteínas que ama / verduras que ama / lo que odia / lo
   **prohibido** (nunca).
3. **Comidas por momento:** sus desayunos de siempre → almuerzos → meriendas.
   Para cada una: ingredientes aproximados, si se congela, cuánto tarda.
4. **Preparaciones base** que ya hace (arroz, pollo, carne, legumbres…) para el
   motor de reutilización.
5. Iterar hasta ~40–60 comidas. Ese es el corazón del sistema.
