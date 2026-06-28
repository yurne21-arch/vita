# VITA — Plan de Implementación por Sprints (Etapa 5)

*Última etapa de diseño (PRD ✅ → Arquitectura ✅ → Modelo de datos ✅ → Motor de IA ✅ → **Sprints**). Construido sobre todo lo aprobado y bajo las reglas "gratis primero" y "lente de costo". No contiene código. Al validarse, queda completa la fase de diseño y puede comenzar el desarrollo (Sprint 0) cuando lo autorices.*

---

## 0. Decisión pendiente resuelta: Offline (Drift+Outbox vs. Brick)

Evalué ambas contra tus cuatro criterios.

| Criterio | Drift + Outbox | Brick (offline_first_with_supabase) |
|---|---|---|
| **Menor complejidad** | Mental model simple y transparente; tú ves qué pasa. Escribes la cola de sync. | Abstrae el sync, pero suma un framework con generación de código (`build_runner`, modelos `.model.dart`) que "puede ser abrumador". |
| **Menor mantenimiento** | Mantienes tu cola de sync (pequeña, gracias al modelo append-only). | Menos código de sync propio, pero dependes de que el framework siga el ritmo de Supabase; no todos los operadores de Supabase están soportados. |
| **Mayor estabilidad** | Comunidad enorme, soporte a 10 años casi garantizado, riesgo de framework casi nulo. | Probado en producción 5+ años, pero nicho; mayor riesgo de framework en el largo plazo. |
| **Integración con Supabase** | Manual (tú conectas Supabase + caché local). | **Integración oficial** lista para usar (su mayor fortaleza). |

**Recomendación: Drift + Outbox.** Justificación técnica:

1. **Encaja con tu forma de construir (IA-asistida, en solitario):** Drift es mainstream; las herramientas de IA generan y depuran código Drift mucho mejor que código Brick (nicho). Para ti, eso significa menos fricción y menos errores difíciles de resolver.
2. **Estabilidad a 10 años y cero lock-in:** Drift es "solo SQLite" — sin amarre a un framework. Esto es coherente con tu filosofía de no quedar condicionada a dependencias (la misma que aplicaste con la IA).
3. **El modelo append-only neutraliza la única desventaja real de Drift:** como casi todo es inserción (no sobreescritura), la cola de sync es pequeña y simple, no el componente complejo que suele ser.
4. **El alcance offline del MVP es acotado:** ver el plan del día ya generado, leer el versículo guardado y registrar datos simples. No requiere sincronización bidireccional pesada en tiempo real, que es justo donde Brick brillaría.

**Cuándo reconsiderar Brick o PowerSync:** si la paridad offline sobre muchas entidades con consultas remotas complejas se vuelve central, o si mantener la cola propia resulta costoso. PowerSync queda como escalón de pago futuro, solo con evidencia.

**Costo de esta decisión:**
| | Drift+Outbox (recomendado) | Brick | PowerSync (futuro) |
|---|---|---|---|
| Costo mensual | $0 | $0 | de pago (verificar al decidir) |
| Costo anual | $0 | $0 | de pago |
| Alternativa gratuita | — (ya es gratis) | — (ya es gratis) | Drift+Outbox |
| Ventaja | control, estabilidad, sin lock-in | menos código de sync | sync gestionada robusta |
| Desventaja | escribes la cola | framework nicho, lock-in | costo + dependencia |
| Cuándo pagar | nunca, salvo evidencia futura | — | solo con necesidad real comprobada |

---

## 1. Plan por sprints (MVP)

Sprints orientados a resultado (≈1–2 semanas cada uno para desarrollo en solitario asistido por IA). Cada sprint tiene una **definición de "hecho"** que es su propia puerta de validación. Todos corren sobre **capa gratuita** (costo de servicios: **$0**), salvo el matiz de IA indicado en la sección 2.

| Sprint | Objetivo | Entregables | "Hecho" (validación) |
|---|---|---|---|
| **0. Cimientos** | Infra + esqueleto | Proyecto Supabase (free), Auth, migraciones de las tablas núcleo del MVP, RLS, Storage con niveles de privacidad (incluido reforzado de menor). App Flutter con Clean Architecture, Riverpod, i18n base, tema claro/oscuro. Drift + `SyncPort` + esqueleto de outbox. `AIProviderPort` (sin lógica aún). | La app compila, inicia sesión, escribe una fila en Supabase y en local; RLS verificada. |
| **1. Design System + Navegación** | Identidad visual y shell | Tokens (verde oliva, tipografía, espaciado), componentes base (tarjetas, botón único principal), shell de 5 pestañas **dinámicas**, scaffold vacío de Mi Vida. | Navegación inteligente funciona; componentes con estética premium; claro/oscuro. |
| **2. Núcleo de datos** | Append-only + Snapshot + Propuestas (sin IA) | Tablas `_events` + vistas de estado actual del MVP. Constructor de Context Snapshot (Edge Function) con filtro de privacidad. Tabla `proposals` y ciclo de vida, probado con propuestas manuales. | Se construye un snapshot; una propuesta de prueba se acepta y aplica a un evento de dominio. |
| **3. Motor de IA mínimo** | Propuestas simples reales | Adaptador `AIProviderPort` (dev: Gemini free), salida estructurada, dos niveles. Uno o dos razonadores de dominio extremo a extremo con los **7 guardarraíles** (incluido permiso de BD solo-`INSERT` en `proposals`). | snapshot → propuesta `pending` con rationale → aceptar → aplica. El lazo completo funciona. |
| **4. Mi Vida** | Pantalla principal viva | Los bloques del MVP curados por las propuestas del día: bienvenida, versículo, estado general, 3 prioridades, agenda, menú de hoy, entrenamiento de hoy, proyecto principal, **tarjeta básica de Finanzas**, cierre nocturno. Dinámica (oculta tarjetas sin datos). | Abrir la app muestra el día curado en <2 min; visible offline. |
| **5. Dios diario** | Experiencia espiritual + historial | Capa de contenido bíblico desacoplada (versículos cargables), `daily_verse_plan`, enseñanza/reflexión/oración por IA, `spiritual_events`, favoritos, "Dios ha sido fiel". | Experiencia diaria con historial completo desde el MVP. |
| **6. Salud + Ciclo simple** | Registro y evolución | Eventos tipados (peso, sueño, energía, ánimo, medidas, fotos) + vistas + gráficos. `cycle_events` simple (period_start/end, symptom, mood, energy). Registro de baja fricción. | Registrar y ver salud y ciclo; los datos llegan al snapshot. |
| **7. Nutrición semanal** | Menú + compras | Recetas, generación de menú semanal (propuesta IA), **porción visual + gramos**, lista de compras por categorías, preferencias/restricciones como límites duros. | La IA propone menú; aprobar → lista de compras; editar comidas. |
| **8. Entrenamiento 12 semanas** | Programa estable + progresión | Programa, workouts, ejercicios, `training_events` (historial real), propuestas de progresión **sin sobreescribir historial**, progresión de caminadora. | Existe un programa de 12s; se propone/acepta una progresión; el historial se conserva. |
| **9. Proyectos + Calendario** | Prioridad y tiempo | Proyectos (≤3 activos), descomposición fases→tareas→calendario, proyecto del mes. Calendario interno + recordatorios + 3 prioridades diarias + replanificación. | Crear proyecto, la IA lo descompone, las tareas caen en el calendario; el día respeta la agenda. |
| **10. Finanzas + Dashboard + Mi Historia** | Visión ejecutiva | `financial_goals`/`reminders`/`important_purchases` mínimos; tarjeta de Finanzas; Dashboard (≤8 tarjetas con estados); `timeline_entries` auto-alimentada. | Tarjeta de finanzas con meta/próximo gasto/recordatorio; Dashboard legible en <5 min; timeline se puebla. |
| **11. Ciclos automáticos + Notificaciones** | La IA en segundo plano | pg_cron + Edge Functions para ciclos diario y semanal (mensual básico), en lotes. Los 4 niveles de notificación (incluido silenciosa). | El trabajo nocturno prepara el día siguiente; revisión semanal; notificaciones según nivel. |
| **12. Pulido** | Estabilidad y confianza | Endurecer offline (casos límite del outbox), accesibilidad, animaciones <300 ms, pruebas unitarias de lógica crítica (guardarraíles, ≤3 proyectos, append-only), auditoría de datos de menor, ruta de borrado de cuenta, export PDF básico. | MVP estable, accesible, privado, listo para usar varios meses. |

Alineación con las 12 fases del Manual 15: Sprint 0 = Infra; 1 = Diseño; 2–3 = Motor IA; 4 = Mi Vida; 5 = Espiritualidad; 6 = Salud (+Ciclo); 7 = Nutrición; 8 = Entrenamiento; 9–10 = Productividad/Finanzas; 11 = Automatizaciones; 12 = Optimización. Empresa y Familia completas quedan para después del MVP.

---

## 2. Impacto económico consolidado (formato obligatorio)

Solo tres decisiones del MVP tienen dimensión de costo. El resto del stack (Flutter, Riverpod, Drift) es gratis y permanente.

### 2.1 Backend — Supabase
- **Costo mensual:** $0 (capa gratuita).
- **Costo anual:** $0.
- **Alternativa gratuita:** es la propia capa gratuita; alternativas self-host existen pero suben el costo de mantenimiento.
- **Ventajas:** Postgres + Auth + RLS + Storage + Edge Functions + cron en un solo lugar; cabe una usuaria con holgura.
- **Desventajas:** límites de la capa gratuita (almacenamiento, egress, pausa por inactividad del proyecto).
- **Cuándo empezar a pagar:** cuando se acerquen los límites por uso real (más fotos/almacenamiento, varios usuarios, o necesidad de que el proyecto no se pause). El plan Pro es el primer escalón; se evalúa con datos de uso.

### 2.2 Inteligencia Artificial
- **Costo mensual (desarrollo):** $0 — capa gratuita de Gemini (Flash) con datos no sensibles.
- **Costo mensual (uso real con datos sensibles):** estimado **<1–3 USD** con lotes y caché.
- **Costo anual estimado:** ~$12–36 en uso real para una usuaria.
- **Alternativa gratuita:** la capa gratuita de los proveedores, pero **entrena con tus datos** → no apta para datos sensibles reales.
- **Ventajas:** arquitectura agnóstica; cambias de proveedor sin reescribir; costo mínimo a una usuaria.
- **Desventajas:** un gasto pequeño aparece cuando uses datos reales sensibles.
- **Cuándo empezar a pagar:** **no ahora.** El proveedor definitivo y la capa de pago se deciden cuando el MVP funcione y puedas comparar privacidad/calidad/costo con pruebas reales (tu decisión 2 y 3 de la adenda). Durante el desarrollo, todo gratis.

### 2.3 Offline — PowerSync (solo futuro)
- **Costo mensual/anual:** $0 en el MVP (usamos Drift+Outbox). PowerSync es de pago (a verificar al decidir).
- **Alternativa gratuita:** Drift+Outbox (la recomendada).
- **Ventajas (de PowerSync):** sync gestionada robusta multi-dispositivo.
- **Desventajas:** costo + dependencia de servicio.
- **Cuándo empezar a pagar:** solo si aparece evidencia real de necesidad (conflictos multi-dispositivo, paridad offline compleja) que Drift+Outbox no cubra bien.

**Resumen:** el MVP completo se construye y opera **prácticamente a $0**, con un único gasto mínimo y opcional (IA sobre datos reales) que se decide más adelante, con pruebas.

---

## 3. Gobierno del desarrollo

- Cada sprint se valida con su "definición de hecho" antes de pasar al siguiente (misma disciplina de puertas que usamos en el diseño).
- Toda nueva herramienta que surja durante el desarrollo se evaluará con el **formato de costo obligatorio** antes de adoptarse.
- Ninguna decisión importante se aplica sin tu aprobación; la IA solo propone.

---

## 4. Después del MVP (medir antes de invertir)

Tras usar VITA durante varios meses, mediremos uso real y decidiremos, con evidencia, dónde invertir: proveedor de IA definitivo, plan de Supabase, PowerSync, y los módulos avanzados (Empresa, Familia completa, Finanzas avanzadas, Armario, Viajes, Documentos, Sueños) y los Modos de Vida avanzados.

---

## Decisiones que requieren tu visto bueno

1. **Offline: Drift + Outbox** como opción única del MVP (PowerSync diferido). ¿Aprobado?
2. **Plan de 13 sprints (0–12)** con sus puertas de validación. ¿Aprobado, o quieres reordenar prioridades?
3. **Impacto económico:** ¿de acuerdo con que el MVP opere a ~$0 y posponer toda decisión de pago a "después de medir"?

---

*Con esto se completa la Etapa 5 y toda la fase de diseño. Al validarla, la documentación estará lista y podremos comenzar el desarrollo por el Sprint 0 — solo cuando tú lo autorices. No escribo código todavía.*
