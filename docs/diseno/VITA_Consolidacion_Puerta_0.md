# VITA — Documento de Consolidación y Validación (Puerta 0)

*Análisis de los 15 manuales. Paso previo y obligatorio antes de la arquitectura técnica definitiva y el plan de sprints. No contiene código. No contiene decisiones tomadas unilateralmente: contiene síntesis, contradicciones, vacíos, mejoras y un conjunto de decisiones que requieren tu aprobación.*

*Me detengo en esta puerta por la Regla 3 del Manual 15: ante contradicciones entre manuales, detenerse y validar antes de continuar.*

---

## 1. Síntesis de la visión (lo que voy a respetar)

VITA es un **Sistema Operativo Personal impulsado por IA**. No es agenda, ni gestor de hábitos, ni app fitness, ni ERP. Su misión es **reducir al máximo la carga mental**.

Principios que gobiernan todo:

- La IA **analiza → propone → explica**. La usuaria **aprueba, modifica o rechaza**. Nunca al revés.
- Nunca generar culpa. Nunca reiniciar el progreso.
- Todo tiene historial. Todo puede modificarse. Todo está conectado.
- Ningún dato se registra dos veces.
- Mínima escritura del usuario; máximo trabajo de la IA. Una app que piensa, no una app de formularios.
- Mobile-first (Flutter), backend Supabase, IA modular como motor de decisiones (no chatbot).
- Estética premium, calmada, tipo Apple. Devolver tiempo, no capturar atención.
- Éxito = adherencia a largo plazo, calidad de recomendaciones y mejora real de vida. No cantidad de funciones.
- Diseñar para una usuaria (Yurnelly), preparar para miles. La personalización vive en **datos y configuración**, nunca en código específico.

Esta visión es coherente entre los 15 manuales. Las observaciones siguientes no la contradicen: la afinan para que sea construible sin ambigüedad.

---

## 2. Contradicciones y tensiones que requieren tu decisión

Para cada una: qué dicen los manuales, por qué importa, opciones y mi recomendación.

### D1 — 18 módulos vs. 5 pestañas de navegación
- **Manual 3:** define 18 módulos. **Manual 13:** navegación = 5 pestañas (Mi Vida, Salud, Proyectos, Calendario, Más).
- **Por qué importa:** 13+ módulos tendrían que vivir bajo "Más". Si Dios y Finanzas quedan ahí enterrados, se contradice la importancia que les das en tu perfil (Manual 2).
- **Opciones:**
  - (a) Mapeo estricto a 5 pestañas, con Dios y Finanzas dentro de "Más".
  - (b) 5 pestañas, pero Dios accesible también desde un acceso fijo en "Mi Vida" (ya aparece el versículo ahí), y Finanzas con tarjeta propia en "Mi Vida".
  - (c) Revisar las 5 pestañas (p. ej. sustituir "Proyectos" por algo más amplio).
- **Mi recomendación:** (b). Mapeo propuesto a validar:
  - **Mi Vida** = pantalla principal (incluye el bloque diario de Dios, Finanzas resumen, etc.).
  - **Salud** = Salud + Nutrición + Entrenamiento + Ciclo Femenino + modos Embarazo/Postparto/Enfermedad.
  - **Proyectos** = Proyectos + Empresa + Sueños.
  - **Calendario** = Calendario + Documentos (vencimientos) + Recordatorios.
  - **Más** = Dios (experiencia completa), Familia, Finanzas (detalle), Armario, Viajes, Dashboard, Ajustes.

### D2 — Qué cuenta como "proyecto" (límite de 3 activos)
- **Manual 3 (Módulo 13):** máx. 3 proyectos activos por mes. **Manual 8:** máx. 3 proyectos principales activos al mismo tiempo. **Manual 8** además permite proyectos en área Salud, Familia, etc.
- **Por qué importa:** Si un ciclo de entrenamiento de 12 semanas o "comer mejor" cuentan como proyecto, saturan el límite y desplazan iniciativas reales.
- **Mi recomendación:** distinguir dos cosas:
  - **Módulos siempre activos** (Salud, Nutrición, Entrenamiento, Dios, Finanzas, Familia, Calendario): funcionan permanentemente y **no** consumen el cupo de 3.
  - **Proyectos**: iniciativas con inicio y fin (aprender a manejar, comprar un auto, lanzar algo). Solo estos cuentan para el límite de 3.
- **A validar:** ¿confirmas esta distinción?

### D3 — Perfil inicial extenso vs. "nunca formularios largos"
- **Manual 6:** lista un perfil inicial amplio (datos, fotos, medidas, equipo, preferencias, horarios…). **Manuales 1 y 13:** nunca formularios largos; la app piensa.
- **Por qué importa:** Pedirte todo eso de golpe en un formulario contradice la esencia del producto y es justo el tipo de fricción que te hace abandonar sistemas.
- **Mi recomendación:** **onboarding conversacional progresivo**. Capturar el mínimo para arrancar (fecha de nacimiento, estatura, peso, objetivo principal, días disponibles), y dejar que la IA complete el resto con el tiempo, pidiendo un dato solo cuando lo necesita para una recomendación concreta. El perfil maestro se llena solo, no de una vez.
- **A validar:** ¿apruebas este enfoque?

### D4 — Notificaciones mínimas / sin culpa vs. recordatorios críticos
- **Manual 5:** nunca notificar por cumplir hábitos; nunca culpa. **Manual 11:** recordatorios críticos (medicamentos, controles, vencimientos, pagos) "nunca deben olvidarse".
- **Por qué importa:** Son compatibles, pero necesito una regla explícita para no equivocar el tono.
- **Mi recomendación (regla a fijar):** tres niveles —
  - **Críticos** (salud, dinero, legal): siempre se notifican, con tono neutro y útil.
  - **Importantes** (reuniones, cumpleaños, eventos): se notifican.
  - **Inteligentes/hábitos**: nunca se "exigen"; aparecen como sugerencia dentro de la app, jamás como notificación de culpa.
- **A validar:** ¿confirmas estos tres niveles?

### D5 — "Ningún dato dos veces" vs. sincronización bidireccional de calendario
- **Manual 14:** ningún dato se registra dos veces. **Manual 11:** sincronización bidireccional con Google/Apple Calendar.
- **Por qué importa:** La sincronización bidireccional duplica por naturaleza (un evento creado en VITA se sincroniza y puede releerse como nuevo).
- **Mi recomendación:** definir **VITA como fuente de verdad**, con identificadores externos espejados (cada evento guarda su id de Google/Apple) y deduplicación por ese id. La sincronización refleja, no duplica.
- **A validar:** ¿de acuerdo con VITA como fuente de verdad?

### D6 — "Offline-first" vs. IA que analiza en servidor
- **Manual 14:** offline-first para funciones esenciales. **Manuales 4 y 11:** la IA hace análisis pesado (probablemente en servidor / Edge Functions).
- **Por qué importa:** Hay que definir qué funciona sin conexión.
- **Mi recomendación:** offline para **consumir y registrar** (ver el plan del día ya generado, leer el versículo guardado, registrar peso, marcar comida/entrenamiento). Online para **generar** (menús nuevos, recomendaciones, informes). Lo generado de madrugada queda disponible offline durante el día.
- **A validar:** ¿te sirve esta frontera?

### D7 — "La IA no será una tabla" vs. módulo de BD "IA"
- **Manual 14** dice ambas cosas.
- **Aclaración (no requiere decisión, solo confirmación):** la **lógica** de IA es un servicio independiente; sus **resultados** (recomendaciones, aprobaciones, patrones detectados) sí se guardan en tablas para tener historial. No es contradicción; lo dejo explícito para que nadie lo malinterprete al construir.

---

## 3. Vacíos a cubrir (con mi propuesta por defecto)

Si no me indicas lo contrario, avanzaría con la recomendación marcada. Dos de estos (G1 y G3) los marco como **requieren tu visto bueno** por ser legales/sensibles.

- **G1 — Contenido bíblico RV1960 (requiere tu visto bueno).** La Reina-Valera 1960 tiene derechos vigentes (Sociedades Bíblicas). Para distribuir mundialmente el texto completo de versículos puede requerirse licencia. Opciones: (a) licenciar RV1960, (b) usar una Reina-Valera de dominio público (p. ej. 1909) como respaldo, (c) diseñar la capa de contenido como intercambiable y resolver la licencia antes del lanzamiento público. La **enseñanza y reflexión** sí las genera la IA (permitido por Manual 7); el problema es solo el texto bíblico literal. *Recomiendo (c) ahora + (a) antes de publicar.*

- **G2 — Proveedor de IA y costos a escala.** Manuales 4/11 implican uso intensivo de IA. Recomiendo IA **por niveles**: modelo económico para resúmenes y rutinas (ejecución nocturna en lote vía Edge Functions), modelo potente solo para decisiones complejas; con caché. Esto controla costo unitario al escalar.

- **G3 — Privacidad de datos sensibles y de un menor (requiere tu visto bueno).** Salud, ciclo, embarazo, finanzas, reflexiones y **datos/fotos de Juan Miguel** son altamente sensibles. Recomiendo: cifrado en reposo para esas categorías, control de acceso estricto (RLS), exportar y borrar datos (alineado con GDPR para "competir mundialmente"), y tratamiento explícito de datos de menor. *Confírmame el alcance: ¿guardamos fotos/salud del niño desde el inicio o lo posponemos?*

- **G4 — Motor de contexto ("todo conectado").** Hace falta definir cómo se ensambla el "contexto completo" para la IA. Recomiendo un **servicio Context Snapshot** que arma el estado transversal actual (peso, sueño, energía, ciclo, agenda, ánimo, objetivos…) en una sola lectura, en vez de que la IA consulte 11 tablas sueltas.

- **G5 — Entrada de sueño/energía antes de wearables.** Los wearables son "futuro" (Manual 14), pero sueño y energía son insumos centrales hoy. Recomiendo entrada mínima (un toque / deslizador) hasta integrar wearables.

- **G6 — Localización (i18n).** "Adaptable a cualquier persona" y competir mundialmente implica i18n desde el diseño, aunque la versión inicial sea solo en español.

- **G7 — Métricas de éxito sin volverse app de tracking.** El éxito (adherencia, carga mental) debe medirse de forma liviana y respetuosa, sin convertir VITA en lo que filosóficamente evita. Recomiendo señales mínimas y privadas.

- **G8 — Guardarraíles médicos.** Embarazo, resistencia a la insulina, postparto y enfermedad exigen una capa transversal: nutrición y entrenamiento siempre como **estructura organizativa**, con deferencia explícita al profesional de salud, y opción de que la guía de tu médico/nutricionista sobreescriba los valores por defecto de la IA. (Coherente con cómo definiste los roles de nutricionista/entrenador "solo para estructura".)

---

## 4. Mejoras que recomiendo como CTO

- **M1 — Pipeline único de Propuestas.** Todo lo que la IA sugiere (tarjetas de Mi Vida, progresión de entrenamiento, menús, consejo financiero, decisiones de empresa) fluye por **una sola entidad**: propuesta → (aceptar | modificar | rechazar) → resultado → aprendizaje. Implementa directamente la filosofía de los Manuales 4 y 8 y unifica el comportamiento en todo el sistema.

- **M2 — Historial append-only.** Datos clave (peso, medidas, decisiones, momentos espirituales) se guardan como registro inmutable + vistas de estado actual. Cumple "todo tiene historial / nunca eliminar definitivamente".

- **M3 — Context Snapshot** (ver G4).

- **M4 — "Modo de Vida" como máquina de estados central.** Normal / Viaje / Embarazo / Postparto-Lactancia / Enfermedad / consciente-del-ciclo. Los modos están dispersos en los manuales; centralizarlos evita conflictos (p. ej., definir precedencia si coinciden Viaje + Enfermedad) y hace que todas las adaptaciones sean consistentes.

- **M5 — Onboarding conversacional progresivo** (ver D3).

- **M6 — Capa de contenido intercambiable + IA por niveles** (ver G1 y G2).

---

## 5. Decisiones que necesito de ti para avanzar

Responde aprobando, modificando o rechazando. Las marcadas con ★ son bloqueantes para la arquitectura.

1. ★ **D1** — ¿Apruebas el mapeo de módulos a las 5 pestañas (con Dios y Finanzas con presencia en "Mi Vida")?
2. ★ **D2** — ¿Confirmas la distinción módulos-siempre-activos vs. proyectos (solo los proyectos cuentan para el límite de 3)?
3. ★ **D3** — ¿Apruebas el onboarding conversacional progresivo en lugar del formulario inicial extenso?
4. **D4** — ¿Confirmas los tres niveles de notificación?
5. **D5** — ¿VITA como fuente de verdad del calendario?
6. **D6** — ¿Te sirve la frontera offline (consumir/registrar) vs. online (generar)?
7. ★ **G1** — Texto RV1960: ¿(a) licenciar, (b) respaldo de dominio público, o (c) capa intercambiable ahora y licencia antes de publicar?
8. ★ **G3** — Datos de Juan Miguel: ¿guardamos salud/fotos del niño desde el inicio o lo posponemos?

Para el resto de vacíos (G2, G4–G8) y todas las mejoras (M1–M6), avanzo con mi recomendación salvo que me digas lo contrario.

---

## 6. Próximo paso (solo tras tu validación)

Una vez resueltas estas decisiones, entrego —cada uno como su propia puerta de validación, sin saltarme ninguna:

1. **PRD consolidado v1** (con tus decisiones integradas).
2. **Arquitectura técnica definitiva** (capas, modelo de datos, motor de IA, seguridad, escalabilidad).
3. **Plan de implementación por sprints** (sobre las 12 fases del Manual 15).

Recién con esa documentación aprobada, comenzaría el desarrollo del código.
