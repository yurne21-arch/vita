# VITA — Arquitectura del Motor de IA

*Etapa 4 de 5 (PRD ✅ → Arquitectura ✅ → Modelo de datos ✅ → **Motor de IA** → Sprints). Construida sobre lo aprobado. No contiene código. Me detengo al final para tu validación antes de la Etapa 5.*

*Principio que gobierna todo el motor: la IA **analiza → propone → explica**; la usuaria **decide**. El motor está diseñado para que sea técnicamente imposible que la IA invente datos o aplique algo importante por su cuenta.*

---

## 1. Cómo funciona el Context Snapshot

Es el primer paso obligatorio de **toda** operación de IA. Vive en el servidor (Edge Functions).

**Flujo de construcción:**
```
1. Disparador (madrugada vía pg_cron, o bajo demanda)
2. Lee SOLO las vistas de estado actual de cada dominio
   (current_weight, latest_sleep, current_cycle, agenda_hoy,
    menú_vigente, programa_entrenamiento, proyectos_activos,
    metas_financieras, modo_de_vida_actual, hitos relevantes…)
3. FILTRO DE PRIVACIDAD:
   • datos de menores (reforzado) → NO se incluyen para IA externa
   • datos sensibles → se minimizan y seudonimizan
4. Compone el "expediente vivo" en JSON estructurado y versionado
5. Lo guarda en context_snapshots → devuelve snapshot_id
```

**Regla de oro:** el snapshot se arma desde datos reales (vistas), nunca desde la memoria del modelo. La IA no "recuerda" a la usuaria: lee su expediente actual cada vez. Esto elimina de raíz la posibilidad de inventar su estado.

---

## 2. Cómo se genera una propuesta

Una "propuesta" es cualquier sugerencia de la IA. Se genera en una tubería de cinco fases con separación estricta entre **lógica determinista** (reglas de negocio, en código) y **juicio del modelo** (lenguaje y composición, en el LLM):

```
TAREA (ej: "arma el día", "evalúa progresión")
  │
  ▼
1. SNAPSHOT  ── obligatorio (snapshot_id)
  │
  ▼
2. RAZONADOR DE DOMINIO  ── un "asesor" por área (salud, nutrición…)
     • aplica reglas DETERMINISTAS (≤3 proyectos, ciclo de 12s,
       restricciones alimentarias, deferencia médica)
     • llama al LLM solo para lo que requiere juicio/redacción,
       dándole únicamente el snapshot como verdad
  │
  ▼
3. VALIDADORES / GUARDARRAÍLES
     • esquema (JSON correcto)
     • reglas de negocio (no viola límites)
     • seguridad (sin contenido médico prescriptivo; deferencia activa)
     • grounding (el rationale cita datos del snapshot)
     → si falla, la propuesta se descarta; nunca se muestra
  │
  ▼
4. SE GUARDA como proposals.status = 'pending'  (con rationale obligatorio)
  │
  ▼
5. SE MUESTRA a la usuaria → Aceptar | Modificar | Rechazar
     • solo al ACEPTAR se escribe el cambio en el _events del dominio
```

El LLM **nunca** escribe en las tablas de dominio. La cuenta de servicio que usa el orquestador solo tiene permiso de `INSERT` en `proposals`. Aunque el modelo "quisiera" aplicar algo, no puede.

---

## 3. Tipos de propuestas

Todas comparten la misma entidad `proposals`; cambian `domain` y `type`:

| Dominio | Tipos de propuesta |
|---|---|
| Mi Vida | tarjeta del día, 3 prioridades, sugerencia de familia, cierre nocturno |
| Salud | resumen semanal/mensual, alerta de tendencia, ajuste temporal por fatiga |
| Nutrición | menú semanal, cambio de comida, lista de compras, ajuste por modo |
| Entrenamiento | progresión (peso/reps/series/caminata), deload, propuesta de nuevo ciclo |
| Ciclo | adaptación de nutrición/entrenamiento según fase |
| Espiritual | enseñanza, reflexión, oración, recordar un momento "Dios ha sido fiel" |
| Proyectos | descomposición en fases/tareas, proyecto del mes, pausar proyecto estancado |
| Calendario | plan del día, replanificación por imprevisto, recordatorio inteligente |
| Finanzas | análisis de compra importante, avance de meta, recordatorio financiero |
| Informes | semanal, mensual, trimestral |

---

## 4. Cómo aprende la IA

Sin reentrenar modelos. Aprende **en contexto**, a partir del historial real de decisiones:

```
Cada propuesta resuelta guarda:
  • resolution (aceptó / modificó / rechazó)
  • outcome (qué pasó al aplicarla)
  • learning (qué se infiere)

Un agregador construye personalization_signals:
  • qué tipos de propuesta acepta / rechaza
  • a qué horas rinde mejor
  • qué comidas bloquea, qué ejercicios modifica
  • patrones por día de semana, por modo de vida

Esas señales se incluyen en el SIGUIENTE snapshot →
la IA propone cada vez mejor, fundamentada en SU historial real.
```

Ejemplo: si rechaza repetidamente entrenamientos largos los jueves, la señal entra al snapshot y las futuras propuestas de jueves se ajustan solas, **explicando** el porqué. Es personalización real, no estética, y siempre auditable (cada propuesta guarda el snapshot con el que se generó).

*(Futuro: memoria semántica con embeddings y, eventualmente, ajuste fino. No en el MVP.)*

---

## 5. Cómo se evita que la IA invente o decida sola

Siete barreras, varias a nivel de arquitectura (no de "buena voluntad" del modelo):

1. **Grounding total:** el modelo solo ve el snapshot (datos reales). Se le instruye que si un dato falta, lo diga o pregunte; nunca lo invente.
2. **Salida estructurada y restringida:** responde en JSON con esquema; el texto libre vive solo en `rationale`.
3. **Reglas deterministas en código:** los límites duros (≤3 proyectos, estabilidad de 12 semanas, alergias/restricciones, deferencia médica) los aplica el código, no el modelo. El LLM opera *dentro* de rieles que no puede sobrepasar.
4. **Rationale obligatorio + validador de grounding:** una propuesta cuyo rationale no cite datos del snapshot se rechaza automáticamente.
5. **La IA solo crea propuestas `pending`:** no puede marcar `accepted` ni escribir en dominios. Permiso de BD limitado a `INSERT` en `proposals`.
6. **Guardarraíles médicos:** en salud, ciclo, embarazo, postparto y enfermedad, se exige marca de deferencia profesional y se bloquea cualquier contenido que parezca prescripción médica.
7. **Humano en el lazo:** nada importante se aplica solo. Sin decisión de la usuaria, la propuesta caduca.

---

## 6. Proveedor de IA recomendado inicialmente

*(Precios verificados a junio 2026; el adaptador agnóstico permite cambiarlos sin tocar la app.)*

Panorama actual (USD por millón de tokens, entrada/salida):

| Proveedor | Económico | Potente | Notas |
|---|---|---|---|
| **Anthropic** | Haiku 4.5 $1.00 / $5.00 | Sonnet 4.6 $3.00 / $15.00; Opus 4.8 $5.00 / $25.00 | caché de prompt ~90% y Batch API 50%; 1M de contexto sin recargo |
| OpenAI | GPT-5.4 Nano (~$0.20 in) | GPT-5.4 $2.50/$15; GPT-5.5 $5/$30 | en general más barato a tiers equivalentes |
| Google | — | Gemini 3.1 Pro ~$2/$12 | duplica tarifa sobre 200K tokens |

**Recomendación para arrancar: Anthropic, dos niveles —** Haiku 4.5 (económico, para tareas rutinarias) + Sonnet 4.6 (potente, para decisiones complejas), reservando Opus 4.8 solo para lo que lo justifique. Justificación:

- **Encaja con el patrón de VITA:** mucho trabajo es nocturno y por lotes (planes, menús, informes) → **Batch API −50%**; y el system-prompt + contexto estable se repiten → **caché −90%**. Estas dos palancas dominan el costo real.
- **1M de contexto sin recargo:** el snapshot + historial caben holgados.
- **Calidad en español** y **salida estructurada** sólidas; alineación de seguridad relevante para una app de bienestar con datos de un menor.

*Alternativa válida:* OpenAI suele ser algo más barato en tiers equivalentes y es perfectamente viable; la decisión no es crítica porque la capa agnóstica (sección 7) permite cambiar de proveedor sin reconstruir. Para un solo usuario (tú) el costo es prácticamente nulo; lo que importa es que la arquitectura no quede amarrada.

---

## 7. Cómo se mantiene la arquitectura agnóstica del proveedor

Un puerto único `AIProviderPort` con adaptadores intercambiables:

```
RAZONADORES DE DOMINIO
        │  (piden: prompt + esquema + nivel económico/potente)
        ▼
  AIProviderPort   ← interfaz estable, no sabe de marcas
        │
   ┌────┼─────┬──────────┐
   ▼    ▼     ▼          ▼
 Anthropic  OpenAI   Gemini   (futuros)
 adapter    adapter  adapter
```

- El resto del sistema nunca llama a un proveedor directamente: siempre al puerto.
- Cada adaptador traduce a la API del proveedor y normaliza la **salida estructurada** (function-calling / JSON schema).
- El **nivel** (económico/potente) y el proveedor se eligen por **configuración**, no por código.
- Las llaves viven solo en variables de entorno del servidor.

---

## 8. Cómo se manejarán los costos

Cinco palancas, en orden de impacto:

1. **Procesamiento por lotes (Batch −50%):** los ciclos diario/semanal/mensual/trimestral corren de madrugada, donde unas horas de latencia no importan. Data processing, generación de contenido y resúmenes offline deben usar Batch cuando no se necesita respuesta en tiempo real.
2. **Caché de prompt (−90% en lo cacheado):** el system-prompt y el contexto estable se cachean entre llamadas.
3. **Enrutamiento por niveles:** tareas simples → modelo económico (varias veces más barato); solo lo complejo → modelo potente.
4. **Recorte de contexto:** el snapshot lleva solo lo necesario para la tarea, no todo el historial.
5. **Límites de salida:** `max_tokens` razonables para evitar respuestas desbordadas.

**Estimación (orden de magnitud, MVP):** con estas palancas, el costo realista ronda **menos de ~1–3 USD por usuaria al mes**, dominado por los informes mensuales/trimestrales si usan modelo potente. Para una sola usuaria es insignificante. La estimación se recalibrará con uso real (no la doy como cifra cerrada).

---

## 9. Ciclos diario, semanal, mensual y trimestral

Orquestados por **pg_cron + Edge Functions**, en Batch:

| Ciclo | Cuándo | Qué hace |
|---|---|---|
| **Diario** | Madrugada | Reconstruye snapshot, arma el plan del día, elige 3 prioridades, prepara Mi Vida. Queda cacheado para uso offline. |
| **Semanal** | Domingo | Revisión breve (qué avanzó, qué quedó, qué priorizar) + planificación de la semana. |
| **Mensual** | Día 1 | Informe ejecutivo (lo mejor, lo difícil, lo aprendido, qué mantener/cambiar) + propuesta del mes. |
| **Trimestral** | Cada 3 meses | Evolución completa de toda la vida + propuesta de nuevo ciclo (incluye nuevo programa de 12 semanas). |

Todos producen **propuestas**, nunca cambios automáticos.

---

## 10. Cómo trabaja la IA con cada dominio

- **Salud:** lee tendencias (peso, sueño, energía, ánimo, medidas) del snapshot; ante fatiga sostenida propone ajuste temporal de entrenamiento; señala cuándo una métrica merece atención. Nunca diagnostica.
- **Nutrición:** genera el menú semanal respetando preferencias, restricciones y objetivo; guarda **porción visual y gramos**; al aprobar, genera la lista de compras; se adapta al modo (viaje, embarazo). Las alergias/restricciones son límites duros que el validador hace cumplir.
- **Entrenamiento:** dentro del ciclo de 12 semanas, evalúa reglas de progresión deterministas (fin de ciclo, estancamiento detectado en `training_events`, cambio de modo) y propone subir peso/reps/series/caminata con su porqué. No cambia a mitad de ciclo sin motivo. El historial real nunca se sobreescribe: las progresiones aceptadas actualizan los workouts *futuros*.
- **Ciclo femenino:** usa `cycle_events` para informar la fase y proponer adaptaciones de nutrición/entrenamiento y expectativas de energía; aprende patrones personales; no asume un patrón universal; deferencia médica.
- **Espiritualidad:** elige el versículo del día del plan y genera enseñanza, reflexión y oración adaptadas al contexto (inicio de proyecto → sabiduría/perseverancia; etapa difícil → esperanza). **Nunca altera el texto bíblico.** Puede recordar un momento "Dios ha sido fiel" cuando detecta una etapa dura.
- **Proyectos:** descompone un proyecto nuevo en fases → tareas → calendario; elige el proyecto del mes; muestra solo el siguiente paso en Mi Vida; hace cumplir el ≤3; agenda según disponibilidad y energía reales; propone pausar proyectos estancados.
- **Calendario:** construye el día cada madrugada; replanifica ante imprevistos sin perder el objetivo semanal; elige las 3 prioridades; respeta horarios "no tocar" (cansancio, cumpleaños del hijo).
- **Finanzas básicas (MVP):** muestra avance de la meta principal, próximo gasto importante y recordatorio financiero; ante una compra importante, la analiza contra los objetivos (ventajas, riesgos, alternativas, impacto) y propone, sin imponer. Sin contabilidad completa.

---

## 11. Qué entra en el MVP del Motor de IA

- Context Snapshot completo (con filtro de privacidad) y su barrera obligatoria.
- Pipeline Único de Propuestas con los 7 guardarraíles.
- Razonadores de dominio para: **Mi Vida, Dios, Salud, Nutrición, Entrenamiento, Ciclo (simple), Proyectos, Calendario y Finanzas básicas.**
- Ciclos **diario y semanal** completos; **mensual** en versión básica.
- Aprendizaje en contexto (resolution/outcome/learning → personalization_signals).
- Capa agnóstica con **un proveedor** (Anthropic, dos niveles) y las 5 palancas de costo.

## 12. Qué queda para fases futuras

- Razonadores de Empresa, Sueños, Familia (completo), Finanzas avanzadas, Armario, Viajes, Documentos.
- Ciclo **trimestral** completo e informes anuales tipo "libro del año".
- Modos de Vida avanzados como entradas del razonamiento (Embarazo, Lactancia, Recuperación, Viaje, Vacaciones).
- Memoria semántica (embeddings) y posible ajuste fino.
- Multi-proveedor activo en paralelo y predicción avanzada de patrones.

---

## Decisiones que requieren tu visto bueno en esta etapa

1. **Proveedor inicial:** ¿confirmas **Anthropic (Haiku 4.5 + Sonnet 4.6)** para arrancar, con la capa agnóstica lista para cambiar? ¿O prefieres iniciar con OpenAI por costo?
2. **Aprendizaje en contexto (sin reentrenar) para el MVP:** ¿de acuerdo con dejar embeddings/ajuste fino para después?
3. **Informe mensual básico en el MVP** (no completo) y trimestral para después: ¿lo confirmas?
4. El resto del motor lo propongo como definitivo salvo que quieras ajustar algo.

---

*Fin de la Arquitectura del Motor de IA. Espero tu validación antes de avanzar a la Etapa 5: Plan de Implementación por Sprints — la última etapa de diseño antes de empezar a programar.*
