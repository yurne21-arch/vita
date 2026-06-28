# VITA — Arquitectura Técnica Definitiva

*Etapa 2 de 5 (PRD ✅ → **Arquitectura** → Modelo de datos → Motor de IA → Sprints). Construida sobre el PRD Consolidado v1 aprobado. No contiene código. Me detengo al final para tu validación antes de la Etapa 3.*

*Stack fijado por los manuales: Flutter (iOS, Android, Web) con Clean Architecture y offline-first; Supabase (PostgreSQL, RLS, Auth, Storage, Edge Functions); IA modular, agnóstica del proveedor, como servicio independiente.*

---

## 1. Arquitectura por capas

Clean Architecture estricta. Cada capa depende solo de la de adentro; el dominio no conoce ni a Flutter ni a Supabase.

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTACIÓN (Flutter)                                      │
│  Pantallas, widgets, estado. Una sola acción principal por   │
│  pantalla. Navegación inteligente. Renderiza propuestas y    │
│  datos; nunca contiene reglas de negocio.                    │
├─────────────────────────────────────────────────────────────┤
│  DOMINIO (Dart puro)                                         │
│  Entidades, casos de uso, interfaces de repositorio y de     │
│  "puertos". Aquí viven las reglas: límite de 3 proyectos,    │
│  ciclos de 12 semanas, precedencia de Modos de Vida, etc.    │
├─────────────────────────────────────────────────────────────┤
│  DATOS (repositorios + fuentes)                              │
│  Implementa los repositorios. Decide entre caché local y     │
│  Supabase. Patrón outbox para escrituras offline.            │
├─────────────────────────────────────────────────────────────┤
│  INFRAESTRUCTURA / SERVICIOS EXTERNOS                        │
│  Cliente Supabase, almacenamiento local, y adaptadores de    │
│  los puertos (IA, Salud, Calendario, Biblia, clima…).        │
└─────────────────────────────────────────────────────────────┘
                              │
              ╔═══════════════▼════════════════╗
              ║  SERVIDOR (Supabase)           ║
              ║  PostgreSQL + RLS + Storage    ║
              ║  Edge Functions = MOTOR DE IA  ║
              ║  pg_cron = procesos nocturnos  ║
              ╚════════════════════════════════╝
```

El **Motor de IA vive en el servidor** (Edge Functions), no en el cliente. La app pide y recibe propuestas ya generadas. Justificación en la sección 10 (Decisión T3).

---

## 2. Módulos técnicos

Organización **feature-first**: cada módulo de producto es un paquete con sus tres capas (presentación / dominio / datos). Sobre ellos, un conjunto de **módulos de núcleo** compartidos.

**Módulos de producto** (cada uno aislado y testeable):
`mi_vida`, `dios`, `salud`, `nutricion`, `entrenamiento`, `ciclo`, `proyectos`, `empresa`, `suenos`, `familia`, `finanzas`, `armario`, `viajes`, `calendario`, `documentos`, `dashboard`.

**Módulos de núcleo** (la maquinaria transversal):

| Módulo de núcleo | Responsabilidad |
|---|---|
| `core_context` | Construye y versiona el Context Snapshot |
| `core_proposals` | Pipeline Único de Propuestas (ciclo de vida completo) |
| `core_life_modes` | Detección y precedencia de Modos de Vida |
| `core_ai` | Abstracción agnóstica del proveedor de IA |
| `core_history` | Registro append-only y vistas de estado actual |
| `core_sync` | Sincronización offline ↔ Supabase (outbox) |
| `core_notifications` | Los 4 niveles de notificación |
| `core_content` | Contenido intercambiable (Biblia y otros) |
| `core_privacy` | Niveles de privacidad y cifrado |
| `core_i18n` | Idioma, moneda, unidades, fechas, región |

Regla: los módulos de producto **nunca** llaman entre sí directamente. Se comunican a través del núcleo (sobre todo `core_context`). Esto garantiza "todo conectado" sin acoplar módulos.

---

## 3. Flujo de datos

Principio: **cada dato se escribe una vez; todo lo demás lo lee.** Lo logramos con registro append-only + vistas de estado actual + Context Snapshot.

Ejemplo extremo a extremo — *la usuaria registra su peso*:

```
1. UI Salud  →  caso de uso "RegistrarPeso"
2. Repositorio escribe UNA fila en health_events (append-only)
       └─ si está offline: va al outbox local y se sincroniza después
3. Vistas de estado actual se actualizan solas (último peso, tendencia)
4. NADIE vuelve a escribir el peso. Lo LEEN:
       • Salud (gráfico y tendencia)
       • Dashboard (tarjeta de estado)
       • Context Snapshot (lo incluye en el contexto)
       • Estadísticas / Mi Historia
5. En el próximo ciclo de IA, el snapshot ya trae ese peso
   y el Pipeline puede proponer (p. ej.) una progresión justificada.
```

No existen registros duplicados: hay una fuente (el evento) y muchas lecturas (vistas + snapshot).

---

## 4. Context Snapshot — el corazón

Es un **servicio del lado del servidor** que arma el "expediente vivo" de la usuaria en un instante dado. Es obligatorio: **ninguna IA decide sin él.**

- **Entrada:** `user_id`, momento, Modo de Vida activo.
- **Proceso:** lee las vistas de estado actual de todos los dominios (nunca tablas crudas dispersas) y compone un objeto estructurado.
- **Salida:** un snapshot JSON versionado y persistido (`context_snapshots`), con su `snapshot_id`.

Contenido del snapshot (conceptual):

```
contexto = {
  perfil: { edad, objetivo_actual, preferencias },
  salud: { ultimo_peso, tendencia, sueño, energía, ánimo },
  ciclo: { fase_actual, predicción },
  modo_vida: { primario, modificadores },
  agenda_hoy: [...],
  nutrición: { menú_vigente, restricciones },
  entrenamiento: { ciclo_12s, semana_actual, progreso },
  proyectos: { activos (≤3), proyecto_principal, siguiente_paso },
  finanzas: { metas, próximo_gasto_importante },
  familia: { eventos_próximos, cumpleaños },
  espiritual: { plan_lectura, momentos "Dios ha sido fiel" },
  historial_relevante: [ hitos que la IA debe recordar ]
}
```

**Barrera arquitectónica:** el Pipeline de Propuestas (sección 5) solo acepta un `snapshot_id` como entrada. Es técnicamente imposible generar una propuesta sin snapshot. El snapshot se reconstruye bajo demanda y también cada madrugada (pg_cron) para dejar el día preparado y disponible offline.

---

## 5. Pipeline Único de Propuestas

Toda sugerencia de la IA —tarjetas de Mi Vida, progresión de entrenamiento, menú, consejo financiero, decisión de empresa— es una **propuesta** y sigue el mismo ciclo:

```
ANALIZAR ─► PROPONER ─► EXPLICAR ─► [ ACEPTAR | MODIFICAR | RECHAZAR ] ─► RESULTADO ─► APRENDER
 (snapshot)  (crea       (rationale   (decisión de la usuaria)            (se aplica   (feedback
             propuesta)   siempre)                                         al dominio)  persistido)
```

Entidad `proposals` (conceptual): `id`, `user_id`, `snapshot_id`, `dominio`, `tipo`, `propuesta` (cambio sugerido), `rationale` (explicación obligatoria), `estado` (pendiente / aceptada / modificada / rechazada / expirada), `resolución`, `resultado`, `aprendizaje`, fechas.

- Una propuesta **aceptada** escribe el cambio en el log append-only del dominio correspondiente (no antes).
- El **aprendizaje** de cada decisión se guarda y alimenta los siguientes snapshots (personalización real, no estética).
- Nada importante se aplica solo: sin decisión de la usuaria, la propuesta caduca, no se ejecuta.

Este pipeline único es lo que hace que VITA se sienta como un solo organismo y no como módulos sueltos.

---

## 6. Modos de Vida

Máquina de estados con **detección automática** cuando es posible y **precedencia** definida.

Modos: `Normal, FinDeSemana, Descanso, AltaCargaLaboral, Vacaciones, Viaje, Enfermedad, Recuperación, Embarazo, Lactancia` + sensibilidad al ciclo.

**Detección:**
- Automática por reglas: FinDeSemana (día), AltaCargaLaboral (densidad de agenda), Viaje/Vacaciones (calendario), sensibilidad al ciclo (fechas).
- Por confirmación: Enfermedad, Embarazo, Lactancia, Recuperación (la IA puede sugerir activarlos; la usuaria confirma).

**Precedencia** (un solo modo *primario* + *modificadores* secundarios apilables):

```
Embarazo  >  Lactancia  >  Enfermedad  >  Recuperación  >
Viaje/Vacaciones  >  AltaCargaLaboral  >  Descanso  >
FinDeSemana  >  Normal
```

Ejemplo: embarazada y de viaje → primario **Embarazo** (manda en salud/nutrición/entrenamiento), modificador **Viaje** (ajusta agenda y recordatorios). Los modos médicos siempre dominan, con guardarraíles (sección 7) que impiden indicaciones que correspondan a un profesional.

Cada modo es un conjunto de reglas que ajustan el snapshot y, a través del pipeline, las propuestas (objetivos, intensidad, tono, agenda). Un cambio de modo importante se confirma; las adaptaciones derivadas se proponen.

---

## 7. Seguridad y privacidad

**Autenticación:** Supabase Auth (correo/OTP en MVP; social después).

**RLS obligatorio en todas las tablas:** cada fila lleva `user_id`; las políticas garantizan que la usuaria solo accede a lo suyo (`auth.uid()`). Sin excepción.

**Tres niveles de privacidad** (`core_privacy`):
- **Estándar:** la mayoría de los datos.
- **Sensible:** salud, ciclo, embarazo, finanzas, reflexiones espirituales. Cifrado de columnas sensibles (pgcrypto) y acceso estricto.
- **Reforzado:** datos de **Juan Miguel** (salud, vacunas, colegio, fotos, documentos, recuerdos). Cifrado de sobre a nivel de aplicación para medios, bucket de Storage separado con políticas más restrictivas, y **registro de auditoría** de accesos.

**Almacenamiento (Storage):** buckets privados, URLs firmadas y temporales. Fotos corporales y del menor cifradas en reposo.

**Frontera hacia la IA externa (decisión de diseño):** el snapshot que se envía a un proveedor de IA externo se **seudonimiza** y se **minimiza**. Los datos de nivel reforzado (Juan Miguel) **no salen** hacia proveedores externos salvo lo mínimo imprescindible y, cuando sea posible, agregados/anonimizados. Las llaves de los proveedores viven solo en Edge Functions, nunca en el dispositivo.

**"Nunca eliminar" vs. derecho al borrado (matiz a validar):** internamente VITA nunca borra para poder construir tu historia. Pero para competir mundialmente debemos honrar el borrado de cuenta a solicitud (estilo GDPR). Propongo: append-only para el uso diario + una ruta explícita de "eliminar mi cuenta y datos" que sí purga. *Esto requiere tu visto bueno.*

**Exportar:** export a PDF/JSON de resúmenes, salud, finanzas, Mi Historia.

---

## 8. Offline-first

**Fuente de verdad: VITA (Supabase).** El dispositivo mantiene una caché local que refleja, no compite.

- **Almacén local:** base SQLite local que espeja el modelo relacional.
- **Escrituras offline:** patrón **outbox** — la escritura se guarda local y se encola; al recuperar conexión se sincroniza. Como los datos clave son append-only, casi no hay conflictos (se agregan, no se sobreescriben). Para campos simples, última-escritura-gana.
- **Disponible offline (vivir el día):** ver el plan del día ya generado, leer el versículo guardado, registrar peso/medidas/ánimo/comidas/entrenamiento, consultar agenda e información básica.
- **Requiere conexión (generar):** menús nuevos, programas, recomendaciones, informes, cualquier llamada a la IA. Lo generado de madrugada queda cacheado para todo el día.

Decisión de herramienta en la sección 10 (T2).

---

## 9. Integraciones futuras (puertos preparados, no implementados)

Arquitectura hexagonal: definimos los **puertos** (interfaces) ahora; los **adaptadores** se implementan después sin tocar el dominio.

| Puerto | Para | Estado en MVP |
|---|---|---|
| `AIProviderPort` | OpenAI / Anthropic / Gemini / otros | **Implementado** (un proveedor) |
| `ScriptureContentPort` | Traducciones bíblicas intercambiables | **Implementado** (versículos cargables) |
| `CalendarSyncPort` | Google / Apple Calendar (con id externo + dedup) | Preparado, no implementado |
| `HealthDataPort` | Apple Health / Health Connect / relojes | Preparado, no implementado |
| `MailDrivePort`, `ERPPort`, `WeatherPort`, `MapsPort` | Gmail, Drive, ERP, clima, mapas | Preparado, no implementado |

El Calendario del MVP es 100% interno (VITA como fuente de verdad); la sincronización externa se activa cuando no retrase el MVP.

---

## 10. Decisiones técnicas recomendadas (con alternativas)

**T1 — Gestión de estado en Flutter.**
- *Recomendado:* **Riverpod** — seguro en compilación, excelente inyección de dependencias (repositorios), gran manejo de streams (ideal para datos reactivos/offline), poco boilerplate.
- *Alternativa:* **Bloc** (más estructurado y explícito, mejor si prefieres rigor de eventos/estados a costa de más código). *GetX* se descarta por mantenibilidad a largo plazo.

**T2 — Persistencia local / offline.**
- *Recomendado:* **PowerSync** — diseñado para offline-first sobre Supabase; resuelve sincronización y conflictos con poco código propio. Acelera llegar a un offline robusto. (Tiene costo/servicio asociado.)
- *Alternativa:* **Drift (SQLite) + outbox propio** — cero dependencias externas y control total, a cambio de más trabajo de sincronización. *Esta elección impacta el cronograma; conviene decidirla aquí.*

**T3 — Dónde corre la IA.**
- *Recomendado:* **Servidor (Edge Functions)** — llaves seguras, proveedor intercambiable sin actualizar la app, procesos nocturnos en lote, caché y control de costo centralizados, propuestas pre-generadas para offline.
- *Alternativa:* IA en el cliente (descartada: expone llaves, encarece, rompe offline y el cambio de proveedor).

**T4 — Abstracción de proveedor de IA.**
- *Recomendado:* **adaptador propio y delgado** detrás de `AIProviderPort`, con dos niveles (modelo económico para resúmenes/rutinas nocturnas; modelo potente para decisiones complejas) + caché.
- *Alternativa:* framework tipo orquestador (más potente, más dependencia y caja negra). Recomiendo control propio por costo y portabilidad.

**T5 — Procesos automáticos.** **pg_cron + Edge Functions** para los ciclos diario/semanal/mensual/trimestral.

**T6 — Historial.** Tablas **append-only** por dominio (`*_events`) + **vistas de estado actual** (materializadas donde el rendimiento lo pida).

**T7 — Snapshots.** Tabla `context_snapshots` en **JSONB**, versionada (se guardan, no se recalculan cada vez), con `snapshot_id` referenciado por cada propuesta.

**T8 — i18n.** `flutter_localizations` + mensajes ICU; moneda/unidades/fechas por locale; guardamos idioma y sistema de medida del usuario como preferencia.

---

## 11. Qué entra en el MVP y qué queda preparado

**MVP (tus 9 prioridades) + el núcleo mínimo que las sostiene:**

Módulos de producto: `mi_vida`, `dios` (diario, en Mi Vida), `salud` (básica), `nutricion` (menú semanal), `entrenamiento` (ciclo de 12 semanas), `proyectos`, `calendario` (interno), `dashboard` (básico).

Núcleo imprescindible para el MVP: `core_context` (Snapshot), `core_proposals` (propuestas simples), `core_life_modes` (versión mínima: Normal/FinDeSemana/AltaCarga + Enfermedad manual), `core_history` (append-only), `core_sync` (offline), `core_ai` (un proveedor, dos niveles), `core_notifications` (4 niveles), `core_content` (versículos cargables), `core_privacy` (RLS + niveles, reforzado para el menor aunque su módulo Familia llegue después), `core_i18n` (base).

**Preparado en arquitectura, construido en fases posteriores:**
Módulos `empresa`, `suenos`, `familia` (perfil completo de Juan Miguel), `finanzas` (detalle), `armario`, `viajes`, `documentos`. Modos de Vida avanzados (Embarazo, Lactancia, Recuperación, Viaje, Vacaciones, Descanso). Integraciones externas (Calendario, Health, Mail/Drive, ERP, clima, mapas). Multi-traducción más allá de la semilla. Multiusuario en producción.

Nota: aunque el módulo Familia llega después, los **datos de Juan Miguel nacen con privacidad reforzada desde el diseño** de la base de datos (Etapa 3), no como un añadido posterior.

---

## Resumen de decisiones que requieren tu visto bueno en esta etapa

1. **T1** — ¿Riverpod (recomendado) o Bloc?
2. **T2** — ¿PowerSync (recomendado, más rápido y robusto, con costo) o Drift + outbox propio (sin dependencia, más trabajo)? *Impacta el cronograma.*
3. **Sección 7** — ¿Apruebas el matiz "append-only interno + ruta real de borrado de cuenta a solicitud"?
4. El resto de decisiones técnicas (T3–T8) las propongo como definitivas salvo que quieras discutir alguna.

---

*Fin de la Arquitectura Técnica Definitiva. Espero tu validación antes de avanzar a la Etapa 3: Modelo de Base de Datos.*
