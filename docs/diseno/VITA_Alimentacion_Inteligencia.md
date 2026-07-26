# VITA · Alimentación — Capa de inteligencia silenciosa

> El diseño visual está **congelado** (ver `VITA_Alimentacion_UX_Rediseño.md` +
> prototipo aprobado). Este documento define **solo la experiencia**: cómo el
> módulo se convierte en el mejor asistente de alimentación, **sin agregar
> funciones, botones, pantallas ni UI nueva**.
>
> **Principio:** cada vez que Yurby abre el módulo, VITA **ya hizo el trabajo**.
> Nunca administra comidas; se siente acompañada. La inteligencia es **silenciosa**
> (no chatbot): actúa **reordenando, rellenando y ocultando decisiones**, y solo
> habla en los espacios que ya existen (la línea de sugerencia de Hoy/Menú, los
> estados, el orden de compra). Costo objetivo **$0**, determinista.

## 0. Filtro de admisión (para todo lo que se muestre o se calcule)

Antes de mostrar un dato o proponer una acción, debe pasar **las cinco**:
**¿Reduce trabajo? ¿Reduce decisiones? ¿Reduce tiempo? ¿Reduce estrés? ¿Hace
sentir acompañada?** Si alguna es "no", **no se muestra** (se calcula en silencio
o se elimina). No queremos información; queremos **decisiones ya tomadas**.

## 1. Qué observa VITA (señales — todas ya existen o son gratis)

| Señal | Fuente (ya construida) |
|---|---|
| Qué hay en casa y cuánto | `nutrition_pantry` (despensa) |
| Qué vence y cuándo | despensa `fecha_vencimiento` · conservación `fecha_max`/`descongelar` |
| Qué se cocinó / porcionó / guardó | producciones · recipientes (estado) |
| Qué comió / cambió / omitió / llevó | estados de comida (marcado que **ya existe** en el diseño) |
| Qué le gusta / rechaza / le da igual | `nutrition_ratings` (afinidad, `ultimo_contexto`, veces sugerido/aceptado/rechazado) |
| Peso y tendencia | `nutrition_weight_log` |
| Qué compró / marcó "ya tengo" / precio | compras (`comprado`, `ya_tengo`, `precio`) |
| Días con compromisos / salidas | feature **`agenda`** (calendario), vía `core` |
| Gasto del mes | feature **`finanzas`**, vía `core` |
| Clima (opcional) | API libre sin llave (open-meteo) — **fase 2**, única señal externa |

> Nada de esto es UI nueva: son datos que el sistema ya guarda al usarlo. El
> **aprendizaje** nace de los estados que Yurby ya marca (comí / cambié / omití /
> llevé); **no se agrega ningún control de "calificar".**

## 2. Inteligencia silenciosa — detección → acción automática → dónde se ve

Cada regla **actúa sola**; solo aparece en un espacio **ya existente**.

| VITA detecta | Acción automática | Dónde se ve (slot existente) |
|---|---|---|
| Queda arroz/pollo en despensa | Reordena el menú para consumirlo **primero**; baja la cantidad en compras | Compras: "VITA reordenó el menú" · lista con menos cantidad |
| Un alimento vence mañana | Reorganiza el menú para usarlo hoy/mañana | Hoy: línea de sugerencia ("Usa el X hoy") |
| Hoy tocaría descongelar, pero conserva mejor mañana | **No** descongelar hoy | Hoy: "Deja el salmón para mañana" (ya en el diseño) |
| Quedan 2 porciones para hoy | **No cocinar** | Hoy: "Hoy no cocinas — usa lo que queda" |
| Mañana hay reunión / salida (agenda) | Deja el recipiente listo hoy; adelanta lo llevable | Hoy: "También" / recipiente marcado |
| Mañana sale temprano | Sugiere dejar el desayuno adelantado esta noche | Hoy (noche): línea de sugerencia |
| Semana con días largos (agenda) | Mueve las recetas largas al **sábado**; entre semana solo ensamblar | Menú: se ve el reparto ya hecho |
| (Fase 2) Llueve / hace frío | Prioriza sopa/guiso de la biblioteca aprobada | Menú: plato ya elegido |
| (Fase 2) Calor | Prioriza comidas frescas aprobadas | Menú: plato ya elegido |
| Juan Miguel rechazó una verdura | La retira ahora; la **reintroduce ~2 semanas después, presentada distinto** | Cocina: adaptación del niño (ya existe) |

Regla de oro: si una detección obliga a Yurby a **decidir**, VITA falló. La
detección **toma la decisión** y solo deja el resultado.

## 3. Anticipación (VITA se adelanta)

- **Víspera de compromiso:** la noche anterior, Hoy prioriza "deja listo el
  recipiente de mañana".
- **Sobrante planificado:** si el conteo de recipientes cubre el día → "hoy no
  cocinas". Nunca proponer cocinar si ya hay porción.
- **Descongelado justo a tiempo:** avisa **la víspera**, no el día (textura).
- **Reposición de frescos:** aparece sola a mitad de quincena, sin que la busque.
- Todo esto usa **conservación + recipientes + agenda**, que ya existen.

## 4. Memoria (VITA recuerda, no solo planifica)

Desde `nutrition_ratings` + histórico de estados y compras:

- **Rechazo previo** (rating `no_me_gusta`/`nunca_sugerir`) → no se vuelve a
  sugerir (el motor ya lo respeta).
- **Aceptación del niño** (comida adaptada marcada "comida", no "omitida") →
  se **repite** esa presentación (p. ej. brócoli con queso).
- **Compra recurrente de más** (comprado > consumido en N quincenas) → baja la
  cantidad por defecto (ej. bananas).
- **Contexto de no-elección** (`ultimo_contexto`) → distingue "no le gustó" de
  "no tocaba ese día" para no penalizar de más.

## 5. Aprendizaje (mejora sola con el uso)

Bucle determinista, sin ML ni servidor: los **estados que Yurby ya marca** ajustan
los **pesos de selección del motor** (`motor.dart`) y las cantidades de compra.

Aprende y aplica a los siguientes menús:
- Qué días cocina / compra / llega tarde → dónde ubicar recetas largas y el prep.
- Qué desayuna de verdad → fija sus desayunos frecuentes.
- Qué desperdicia / congela siempre / compra de más → ajusta cantidades y
  congelación por defecto.
- Qué repite / nunca come → sube o retira de la rotación.

**Cada semana el plan siguiente ya viene corregido por lo aprendido.** Yurby no
configura nada; solo usa el módulo y este mejora.

## 6. Momentos WOW (uno por pantalla, medido, nunca exagerado)

Se computan de datos reales; aparecen **solo cuando son ciertos**.

| Pantalla | Momento | Se calcula de |
|---|---|---|
| Hoy | "Hoy no tienes nada pendiente. Disfruta." | 0 acciones abiertas |
| Menú | "Esta semana no desperdiciaste nada." | despensa sin vencidos + recipientes consumidos |
| Cocina | "Terminaste 18 min más rápido que la vez pasada." | duración de la sesión vs. histórico |
| Compras | "Gastaste $12.000 menos que el mes pasado." | precios de compras vs. finanzas |
| (Familia) | "Juan Miguel probó una fruta nueva." | comida infantil nueva marcada "comida" |

Uno por pantalla, breve. Si no es cierto, **no aparece** (nada de decoración).

## 7. Lo que NO se hace (para que las 10 funciones sean extraordinarias)

- **No** chatbot, **no** más módulos, botones, ajustes, pantallas ni opciones.
- **No** UI nueva: la inteligencia vive en slots existentes (sugerencia, estados,
  orden). Si algo exige un control nuevo, se descarta o se infiere de un estado
  que ya existe.
- **No** pedir calificaciones explícitas: se aprende del comportamiento.

## 8. Mapa a lo ya construido

- **Motor** (`domain/motor.dart`): gana entradas de *pesos aprendidos*,
  *prioridad por despensa/caducidad* y *reparto por agenda*. Sigue determinista y
  cerrando el día en tolerancia.
- **Tablas** (`0017`): afinidad, despensa, conservación, peso ya soportan memoria
  y anticipación. `0018` (cuando toque construir) añade estados de comida/recipiente,
  compra quincenal e histórico de sesión — **sin** UI nueva, solo persistencia.
- **Cross-feature** vía `core`: leer agenda (compromisos) y finanzas (gasto). Los
  features no se importan entre sí.

## 9. Criterio de terminado (para cada regla, antes de implementarla)

Se implementa solo si: **reduce trabajo · reduce decisiones · reduce tiempo ·
reduce estrés · acompaña.** Si el usuario en algún punto siente que debe organizar
algo manualmente, la regla **no está terminada**.

---

**Esta capa no cambia una sola pantalla; cambia cuánto piensa Yurby (nada).**
Cuando la apruebes, la implementación se hace pieza por pieza sobre el diseño
congelado y el motor ya construido, empezando por lo más deterministic-de-hoy
(despensa que reordena, conservación que anticipa, sobrante que evita cocinar) y
sumando memoria y aprendizaje a medida que se acumulan datos de uso.
