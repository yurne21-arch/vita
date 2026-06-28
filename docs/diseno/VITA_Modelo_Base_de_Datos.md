# VITA — Modelo de Base de Datos

*Etapa 3 de 5 (PRD ✅ → Arquitectura ✅ → **Modelo de datos** → Motor de IA → Sprints). Diseño para validar, no migraciones finales. Los pocos fragmentos SQL son patrones de decisión, no implementación. Me detengo al final para tu validación antes de la Etapa 4.*

---

## 1. Convenciones y principios del modelo

1. **`user_id` en todas las tablas** (incluidas las de menores), apuntando a `auth.users(id)`. Así la RLS es una comprobación directa (`user_id = auth.uid()`), sin joins frágiles.
2. **Append-only para datos de evolución:** las tablas que terminan en `_events` solo permiten INSERT y SELECT (nunca UPDATE/DELETE). El estado actual se obtiene de **vistas**.
3. **Registro único:** cada hecho se escribe una sola vez (un evento); todo lo demás lo lee (vistas + snapshot). Nunca se duplica.
4. **Niveles de privacidad** por tabla: `estándar`, `sensible`, `reforzado` (menores). Determinan cifrado, auditoría y qué sale hacia la IA externa.
5. **Nomenclatura:** snake_case, singular para entidades de configuración (`project`), plural-evento para logs (`weight_events`).
6. **IDs:** `uuid` por defecto (`gen_random_uuid()`). Tiempos en `timestamptz` (UTC); fechas "de calendario" en `date`.
7. **i18n:** el perfil guarda idioma, moneda y sistema de medida; nada de unidades hardcodeadas.

---

## 2. Vista general (el centro del modelo)

Todo gira alrededor de dos tablas de núcleo: **`context_snapshots`** (el contexto) y **`proposals`** (lo que la IA sugiere). Ninguna propuesta existe sin un snapshot.

```
                       ┌────────────────────┐
   dominios (eventos)  │  context_snapshots │  ◄── se arma leyendo
   weight_events ──┐   │  (JSONB, versionado)│      las VISTAS de
   sleep_events ───┤   └─────────┬──────────┘      estado actual de
   cycle_events ───┼──► VISTAS ──┘                 todos los dominios
   training_events ┤   de estado            │
   project_events ─┘   actual               ▼
                                   ┌────────────────────┐
                                   │     proposals      │
                                   │ snapshot_id NOT NULL│ ◄── BARRERA:
                                   │ dominio, rationale, │     sin snapshot
                                   │ estado, resultado,  │     no hay propuesta
                                   │ aprendizaje         │
                                   └─────────┬──────────┘
                                             │ al ACEPTAR
                                             ▼
                              escribe en el _events del dominio
                              (p. ej. acepta progresión → training)
```

---

## 3. Tablas de fundación

**`profiles`** *(estándar)* — una fila por usuaria (id = auth uid).
| Campo | Tipo | Nota |
|---|---|---|
| id | uuid (PK, = auth.uid) | |
| display_name | text | |
| birth_date | date | la edad se **calcula**, no se guarda |
| locale | text | ej. `es-CL` |
| currency | text | ej. `CLP` |
| measurement_system | text | `metric` / `imperial` |
| created_at | timestamptz | |

**`user_preferences`** *(estándar)* — notificaciones, tema, recordatorios; clave por `user_id`.

---

## 4. Tablas de núcleo transversal

**`context_snapshots`** *(sensible)*
| Campo | Tipo | Nota |
|---|---|---|
| id | uuid PK | el `snapshot_id` |
| user_id | uuid FK | |
| created_at | timestamptz | |
| life_mode_primary | text | modo de vida vigente |
| life_mode_modifiers | jsonb | modificadores apilados |
| payload | jsonb | el "expediente vivo" completo |
| version | int | esquema del payload |
| source | text | `nightly` / `on_demand` |

**`proposals`** *(estándar; el payload puede referir datos sensibles)*
| Campo | Tipo | Nota |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | |
| snapshot_id | uuid FK **NOT NULL** | la barrera |
| domain | text | salud, nutrición, entrenamiento, finanzas… |
| type | text | progresión, menú, tarjeta_mi_vida… |
| proposal | jsonb | el cambio sugerido |
| rationale | text **NOT NULL** | explicación obligatoria |
| status | text | pending/accepted/modified/rejected/expired |
| resolution | jsonb | qué decidió la usuaria |
| outcome | jsonb | resultado tras aplicarse |
| learning | jsonb | aprendizaje para futuros snapshots |
| created_at / resolved_at / expires_at | timestamptz | |

**`life_mode_events`** *(estándar, append-only)* — historial de cambios de modo (ver sección 9).

**`notifications`** *(estándar)* — `level` (critical/important/smart/silent), `title`, `body`, `payload`, `scheduled_for`, `delivered_at`, `read_at`, `source_domain`. Las `silent` nunca se entregan como push (`delivered_at` queda nulo; se ven al abrir la app).

**`audit_log`** *(reforzado)* — accesos a datos de nivel reforzado (menores): `actor`, `table_name`, `record_id`, `action`, `accessed_at`.

**`deletion_requests`** *(estándar)* — ruta real de borrado: `requested_at`, `status`, `completed_at`. Append-only para uso normal, pero esta tabla habilita la purga a solicitud.

---

## 5. Contenido bíblico intercambiable

Desacoplado: cambiar de traducción no toca el código ni los datos de la usuaria.

**`scripture_translations`** *(estándar)* — `code` (RVR1960, RVR1909…), `name`, `language`, `license_status`, `is_active`.
**`scripture_verses`** *(estándar)* — `translation_id` FK, `book`, `chapter`, `verse`, `text`.
**`daily_verse_plan`** *(estándar)* — `day_of_year` (1–366, único), referencia (`book`, `chapter`, `verse_start`, `verse_end`), `theme`. El texto se resuelve desde `scripture_verses` según la traducción activa. **La enseñanza, reflexión y oración no se guardan aquí: las genera la IA por día/usuaria.**

---

## 6. Dominios

### 6.1 Espiritual *(sensible)*
**`spiritual_events`** *(append-only)* — `type` (verse_read/reflection_saved/prayer_generated/favorite), `day_of_year`, `verse_ref`, `content` (jsonb: reflexión/oración), `created_at`.
**`faithfulness_moments`** ("Dios ha sido fiel") — `title`, `description`, `date`, `photo_path` (Storage), `created_at`. — **MVP** (versión simple).
*(Futuro: `reading_plans`, `reading_plan_progress`.)*

### 6.2 Salud *(sensible)* — **MVP (básica)**
Eventos append-only + vistas de estado actual:
- **`weight_events`** — `weight_kg`, `measured_on`, `source` (manual/health_kit).
- **`body_measurements`** — cintura, cadera, pecho, muslo, brazo, pantorrilla, cuello (cm), `measured_on`.
- **`progress_photos`** *(sensible, cifrada)* — `pose` (front/side/back), `storage_path`, `taken_on`.
- **`sleep_events`** — `hours`, `quality` (1–5), `slept_on`.
- **`energy_events`** — `level` (1–5), `recorded_at`.
- **`mood_events`** — `mood`, `note` (corta), `recorded_at`.
- **`medical_exams`** — `type`, `storage_path`, `exam_date`, `notes`.
- **`medications`**, **`supplements`** — `name`, `dose`, `schedule`, `active`, fechas.

Vistas: `current_weight`, `weight_trend`, `latest_sleep`, `latest_energy`, `latest_mood`, `health_current` (consolidada para el snapshot).

### 6.3 Ciclo femenino *(sensible)* — *Futuro* (preparado)
**`cycle_events`** *(append-only)* — `type` (period_start/period_end/symptom), `date`, `symptom`. Vista `current_cycle` (fase y predicción). *Predicción la calcula la IA; la vista expone datos.*

### 6.4 Nutrición — **MVP (menú semanal)**
- **`recipes`** *(estándar)* — `user_id` (nulo = receta de sistema), `name`, `ingredients` (jsonb), `steps` (jsonb), `portions`, `tags`, `is_favorite`, `source` (system/user/ai).
- **`weekly_menus`** — `week_start`, `status` (proposed/approved/active), `created_via_proposal_id` FK.
- **`menu_meals`** — `menu_id` FK, `day_of_week`, `meal_type`, `recipe_id` FK, `portion`, `suggested_time`, `status` (planned/consumed/changed), `consumed_at`.
- **`shopping_lists`** + **`shopping_items`** (`category`, `name`, `quantity`, `checked`).
- **`food_preferences`** *(sensible)* — `likes`, `dislikes`, `restrictions` (jsonb).
- **`nutrition_events`** *(append-only)* — `meal_consumed` para Mi Historia.

### 6.5 Entrenamiento — **MVP (ciclo de 12 semanas)**
- **`training_programs`** — `objective`, `start_date`, `weeks` (default 12), `status`, `created_via_proposal_id`.
- **`workouts`** — `program_id` FK, `week_number`, `day_label`, `focus` (strength/cardio/mobility/rest).
- **`workout_exercises`** — `workout_id` FK, `exercise_name`, `sets`, `reps`, `weight_kg`, `rest`, `order`. (Las progresiones aceptadas actualizan los valores *planeados* de los próximos workouts.)
- **`training_events`** *(append-only)* — lo realmente hecho: `workout_id`, `exercise_name`, `sets_done`, `reps_done`, `weight_used`, `duration` (cardio/caminadora), `performed_at`. La progresión de la caminadora se lee de aquí.

### 6.6 Proyectos — **MVP**
- **`projects`** — `name`, `objective`, `motive`, `area`, `start_date`, `target_date`, `status` (active/paused/completed), `priority`, `estimated_time`, `is_principal` (proyecto del mes). **Regla "≤3 activos"** se aplica en la capa de dominio + trigger de respaldo en BD.
- **`project_phases`** — `project_id` FK, `name`, `order`, `status`.
- **`project_tasks`** — `phase_id` FK, `name`, `status`, `scheduled_date` (enlaza al calendario), `estimated_time`.
- **`project_events`** *(append-only)* — cambios de estado y cierres, para Mi Historia.

### 6.7 Calendario — **MVP (interno)**
- **`calendar_events`** — `title`, `type`, `starts_at`, `ends_at`, `all_day`, `location`, `source` (`vita`/`google`/`apple`), `external_id` (nulo; **para dedup futuro**), `recurrence` (jsonb). VITA es la fuente de verdad; `external_id` queda preparado para sincronización sin duplicar.
- **`reminders`** — `level`, `title`, `due_at`, `related_table`, `related_id`, `status` (alimenta `notifications`).

### 6.8 Dashboard / Mi Historia — **MVP (básico)**
- Sin tablas base nuevas: el Dashboard lee de **vistas**.
- **`timeline_entries`** ("Mi Historia") — `title`, `type`, `occurred_on`, `source_table`, `source_id`. Poblada por el sistema desde eventos significativos.

### 6.9 Familia — *módulo Futuro, pero andamiaje de menor desde ahora* *(reforzado)*
Por tu decisión 11, esto se diseña ya aunque el módulo llegue después:
- **`family_members`** — `name`, `relation`, `birth_date`, `is_minor` (bool), `privacy_tier`.
- **`child_profiles`** — `family_member_id` FK, `school`, `grade`, `clothing_size`, `shoe_size`, `allergies` (jsonb), `notes`.
- **`child_health_events`** *(append-only, reforzado, cifrado)* — vacunas, controles, peso, estatura.
- **`child_timeline`**, **`child_documents`** *(reforzado)*.
- *(Resto de Familia —`family_events`, `family_gratitude`, `memories`— Futuro.)*

### 6.10 Otros dominios — *Futuro (preparados, especificación ligera)*
- **Empresa:** `business_objectives`, `business_indicators`, `business_meetings`, `business_ideas`, `business_decisions` (motivo, ventajas, riesgos, alternativas, resultado_esperado, aprendizaje).
- **Sueños:** `dreams` (objetivo, plan, primer_paso, estado, fecha_estimada, progreso, `fund_id`).
- **Finanzas** *(sensible)*: `financial_goals`, `assets`, `budgets`, `important_purchases`, `dream_funds`.
- **Armario:** `wardrobe_items`, `outfits`, `wardrobe_shopping`.
- **Viajes:** `trips`, `trip_reservations`, `trip_checklist`, `trip_items`.
- **Documentos** *(sensible)*: `documents` (`type`, `storage_path`, `expires_on`) → alimenta recordatorios críticos de vencimiento.

---

## 7. Eventos append-only y vistas de estado actual

Patrón (decisión de diseño a validar): los `_events` no se actualizan ni se borran; el estado actual es una vista.

```sql
-- Patrón append-only: solo INSERT y SELECT para el rol de usuario
REVOKE UPDATE, DELETE ON weight_events FROM authenticated;

-- Estado actual = vista (no una columna que se sobreescribe)
CREATE VIEW current_weight AS
SELECT DISTINCT ON (user_id) user_id, weight_kg, measured_on
FROM weight_events
ORDER BY user_id, measured_on DESC;
```

Tablas append-only: `*_events` de salud, ciclo, nutrición, entrenamiento, proyectos, espiritual, vida (modos), familia-menor. Esto garantiza "todo tiene historial" y "ningún dato dos veces".

---

## 8. Context Snapshot + barrera de Propuestas

La obligatoriedad del snapshot se hace cumplir en el propio esquema:

```sql
-- Sin snapshot no hay propuesta: la FK es NOT NULL
ALTER TABLE proposals
  ADD CONSTRAINT proposals_need_snapshot
  FOREIGN KEY (snapshot_id) REFERENCES context_snapshots(id);
-- snapshot_id es NOT NULL → ninguna IA puede proponer sin contexto
```

El snapshot se arma leyendo solo **vistas** de estado actual (nunca tablas crudas dispersas), se guarda en JSONB versionado y se referencia desde cada propuesta para trazabilidad ("¿con qué contexto se decidió esto?").

---

## 9. Modos de Vida

- **`life_mode_events`** *(append-only)* — `primary_mode`, `modifiers` (jsonb), `auto_detected` (bool), `confidence` (numeric), `trigger_context` (jsonb), `created_at`.
- Vista **`current_life_mode`** — el modo vigente (último evento).
- La **precedencia** (Embarazo > Lactancia > Enfermedad > Recuperación > Viaje/Vacaciones > AltaCarga > Descanso > FinDeSemana > Normal) vive en la capa de dominio; la BD solo guarda el estado y su historial.

---

## 10. Seguridad / RLS

RLS activada en **todas** las tablas, con comprobación directa:

```sql
ALTER TABLE weight_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_owns_row ON weight_events
  FOR ALL USING (user_id = auth.uid());
```

Como todas las tablas (incluidas las de menores) llevan `user_id`, no hay políticas por join. Storage: buckets privados con políticas equivalentes y URLs firmadas temporales.

---

## 11. Privacidad reforzada

**Mapa de niveles:**
- **Reforzado:** `family_members` (menores), `child_profiles`, `child_health_events`, `child_timeline`, `child_documents`, `audit_log`.
- **Sensible:** salud (`weight_events`, `body_measurements`, `progress_photos`, `sleep/energy/mood_events`, `medical_exams`, `medications`, `supplements`), `cycle_events`, `food_preferences`, espiritual (`spiritual_events`, `faithfulness_moments`), finanzas (futuro), embarazo (vía modos), `context_snapshots`.
- **Estándar:** el resto.

**Controles por nivel reforzado (menores), desde el diseño inicial:**
1. Cifrado de sobre a nivel de aplicación para medios (fotos/documentos del menor) + `pgcrypto` en columnas sensibles.
2. Bucket de Storage separado con políticas más restrictivas.
3. **`audit_log`** de cada acceso.
4. **No sale hacia IA externa** salvo lo mínimo imprescindible, y preferentemente anonimizado/agregado.

**Sensible:** cifrado de columnas críticas, minimización y seudonimización en lo que se envía a la IA externa.

**Borrado real:** `deletion_requests` dispara una purga que sí elimina (excepción explícita al append-only), para cumplir el derecho al borrado.

---

## 12. Inventario MVP vs. Futuro

**Tablas del MVP:**
`profiles`, `user_preferences`, `context_snapshots`, `proposals`, `life_mode_events`, `notifications`, `audit_log`, `deletion_requests`, `scripture_translations`, `scripture_verses`, `daily_verse_plan`, `spiritual_events`, `faithfulness_moments`, `weight_events`, `body_measurements`, `progress_photos`, `sleep_events`, `energy_events`, `mood_events`, `medical_exams`, `medications`, `supplements`, `recipes`, `weekly_menus`, `menu_meals`, `shopping_lists`, `shopping_items`, `food_preferences`, `nutrition_events`, `training_programs`, `workouts`, `workout_exercises`, `training_events`, `projects`, `project_phases`, `project_tasks`, `project_events`, `calendar_events`, `reminders`, `timeline_entries` + sus vistas de estado actual.

**Andamiaje reforzado preparado en el MVP (módulo Familia llega después, pero las tablas de menor nacen ahora):** `family_members`, `child_profiles`, `child_health_events`, `child_timeline`, `child_documents`.

**Tablas Futuras (preparadas, no construidas en el MVP):** `cycle_events`; Empresa (`business_*`); `dreams`; Finanzas (`financial_goals`, `assets`, `budgets`, `important_purchases`, `dream_funds`); Armario (`wardrobe_*`, `outfits`); Viajes (`trips`, `trip_*`); `documents`; resto de Familia (`family_events`, `family_gratitude`, `memories`); `reading_plans`.

---

## Decisiones que requieren tu visto bueno en esta etapa

1. **Tarjeta de Finanzas en Mi Vida (MVP):** se **oculta** hasta construir el módulo Finanzas, en vez de construir Finanzas solo para esa tarjeta. ¿De acuerdo?
2. **Ciclo femenino en el MVP:** lo dejé como *Futuro preparado* (no está en tus 9 prioridades), pero afecta directamente salud, nutrición y entrenamiento. ¿Lo mantenemos fuera del MVP o lo subimos a MVP por su impacto transversal?
3. **Salud por eventos tipados** (tablas separadas: peso, sueño, energía…) vs. una sola tabla flexible. Recomiendo tipadas (más claras y fáciles de graficar). ¿Lo confirmas?
4. **Andamiaje de menores desde ahora** (tablas `child_*` aunque el módulo Familia sea posterior): confirmado por tu decisión 11; lo dejo explícito.

El resto del modelo lo propongo como definitivo salvo que quieras ajustar algo.

---

*Fin del Modelo de Base de Datos. Espero tu validación antes de avanzar a la Etapa 4: Arquitectura del Motor de IA.*
