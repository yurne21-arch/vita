# VITA — Adenda Técnica: Regla de "gratis primero" en el MVP

*Esta adenda registra una nueva regla obligatoria del proyecto y revisa las decisiones técnicas afectadas. Reemplaza, donde corresponda, las recomendaciones previas de la Etapa 2 (offline) y la Etapa 4 (proveedor de IA). No contradice ningún manual: refina la filosofía técnica.*

---

## 1. Nueva regla obligatoria (vinculante)

1. Durante el MVP queda **prohibido incorporar herramientas de pago** si existe una alternativa gratuita que logre al menos el **90%** del resultado.
2. Una herramienta de pago solo se aprueba con **evidencia técnica y económica** de un beneficio importante en rendimiento, escalabilidad o experiencia de usuario (o, como veremos, en privacidad de datos sensibles).
3. **Validar primero, optimizar después.** Usar la app varios meses; luego decidir dónde invertir.
4. **Toda recomendación técnica incluirá desde ahora su costo de implementación y mantenimiento.**

---

## 2. Revisión — Sincronización offline (reemplaza T2)

**Antes:** PowerSync recomendado.
**Ahora:** PowerSync **no se aprueba** para el MVP. Se construye con herramientas gratuitas y la arquitectura queda preparada para incorporarlo solo si aparece una necesidad real.

**Enfoque gratuito para el MVP:**
- **Almacén local:** SQLite vía **Drift** (open source, gratis).
- **Sincronización:** patrón **repositorio + outbox** propio contra Supabase. Como los datos clave son *append-only*, los conflictos son mínimos (se agregan, no se sobreescriben); para campos simples, última-escritura-gana.
- **Alternativa gratuita a evaluar:** **Brick** (framework offline-first open source con soporte Supabase), que reduce código propio de sincronización. Se compara con Drift+outbox al inicio del desarrollo y se elige el que dé menos costo de mantenimiento.

**Puerto `SyncPort`:** la sincronización vive detrás de una interfaz. Si más adelante hay necesidad real (multi-dispositivo intensivo, conflictos complejos), se evalúa PowerSync u otra opción **con evidencia**, sin reescribir la app.

**Costo:** implementación = esfuerzo de desarrollo (sin tarifa de servicio); mantenimiento = bajo para una usuaria y datos append-only. **$0 en servicios.**

**Tradeoff honesto:** PowerSync resuelve solo casos límite (sync en tiempo real, conflictos multi-dispositivo, sync parcial). Para una usuaria con datos append-only, el enfoque gratuito cubre bastante más del 90% del resultado. Se reconsidera con datos de uso real.

---

## 3. Revisión — Proveedor de IA (reemplaza la recomendación de la Etapa 4)

**Antes:** recomendar Anthropic para arrancar.
**Ahora:** **no se define un proveedor definitivo.** La arquitectura es 100% agnóstica (puerto `AIProviderPort`); el proveedor se elige por configuración, sin dependencia técnica, y se puede cambiar entre OpenAI, Anthropic, Gemini u otro sin tocar la arquitectura.

Bajo la regla "gratis primero", separo dos fases:

**Fase de desarrollo / prototipo (datos sintéticos o no sensibles):**
- Usar la **capa gratuita de Gemini** (familias Flash y Flash-Lite). Es la opción gratuita más completa hoy: sin tarjeta de crédito y sin expiración, con función de llamada a herramientas, modo JSON, embeddings y 1M de contexto, y límites amplios para prototipar (Gemini 3.1 Flash-Lite con 15 solicitudes por minuto; del orden de 1.500 solicitudes por día). **Costo: $0.**
- Esto permite construir y probar todo el Pipeline de Propuestas sin gastar.

**Fase real con tus datos sensibles (salud, ciclo, finanzas y datos del menor):**
- Aquí aparece un **bloqueo de privacidad**: en la capa gratuita de Gemini, Google puede usar las entradas y salidas para mejorar sus modelos; la capa de pago y Vertex AI no lo hacen. Para datos de salud y de un menor, esto es inaceptable.
- Por lo tanto, para uso real con datos sensibles se usa una **capa de pago** (de cualquier proveedor, vía el mismo puerto). El costo a una usuaria es **insignificante** (del orden de **<1–3 USD/mes** con lotes y caché; p. ej. Gemini 2.5 Flash a 0,30/1,50 USD por millón, o Haiku 4.5 a 1,00/5,00 USD).

**Esta es exactamente la excepción que la regla permite:** el pago se justifica por un beneficio importante e innegociable —la **privacidad de datos sensibles**—, no por optimización prematura. Y el monto es mínimo.

**Resumen de la decisión:** arquitectura agnóstica; **desarrollar gratis** (Gemini free) con datos no sensibles; **operar con datos reales** en una capa de pago económica que no entrene con tus datos; cambiar de proveedor cuando convenga, sin reescribir nada.

---

## 4. Verificación del resto del stack bajo el lente de costo

| Componente | Estado de costo | Nota |
|---|---|---|
| **Flutter** | Gratis | Open source. |
| **Riverpod** | Gratis | Open source. |
| **Supabase (Postgres, Auth, RLS, Storage)** | **Capa gratuita** suficiente para el MVP | Una usuaria cabe holgada. Vigilar límites de la capa gratuita (almacenamiento, egress, pausa por inactividad). |
| **Edge Functions + pg_cron** | Incluidos en Supabase | La capa gratuita tiene límites de invocación; suficientes para una usuaria. |
| **Drift / Brick (offline)** | Gratis | Reemplazan a PowerSync en el MVP. |
| **IA (desarrollo)** | Gratis | Gemini free tier. |
| **IA (datos reales sensibles)** | Pago mínimo justificado | Privacidad; <1–3 USD/mes. |
| **Mapas / clima (futuro)** | Diferido | Muchos con capa gratuita; no en MVP. |

**Conclusión:** el MVP de VITA puede construirse y operar **prácticamente a costo cero**, con un único gasto mínimo y justificado (la IA de pago sobre datos sensibles, por privacidad). No hay otras herramientas de pago en el MVP.

---

## 5. Cómo afecta esto a las decisiones aún abiertas de la Etapa 4

- **Proveedor inicial:** ya no se "confirma Anthropic". Se confirma **arquitectura agnóstica + Gemini free para desarrollo + capa de pago económica para datos reales**. ¿De acuerdo?
- **Embeddings/ajuste fino para después:** sigue en pie y además refuerza la regla (menos costo ahora). *Nota:* los embeddings de Gemini son gratuitos en su capa gratuita, así que cuando lleguen podrán evaluarse sin costo.
- **Informe mensual básico en el MVP:** sin cambios.

---

## 6. Regla permanente para las próximas entregas

A partir de aquí, **cada recomendación técnica** (incluido el Plan de Sprints de la Etapa 5) indicará explícitamente:
- Si la herramienta es **gratuita o de pago**.
- Si es de pago, **qué alternativa gratuita** existe y por qué no alcanza el 90%.
- El **costo de implementación y mantenimiento** estimado.

---

## Decisiones que requieren tu visto bueno

1. **Offline gratuito (Drift+outbox o Brick) en el MVP, PowerSync diferido detrás de `SyncPort`.** ¿Aprobado?
2. **IA agnóstica + Gemini free para desarrollo + capa de pago mínima para datos reales sensibles (por privacidad).** ¿Aprobado?
3. **Resto del stack en capa gratuita de Supabase para el MVP**, vigilando sus límites. ¿Aprobado?

---

*Con esta adenda integrada, la siguiente y última etapa de diseño es el Plan de Implementación por Sprints (Etapa 5), que ya vendrá con el lente de costo aplicado. Espero tu validación antes de avanzar.*
