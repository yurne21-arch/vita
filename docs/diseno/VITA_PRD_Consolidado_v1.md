# VITA — PRD Consolidado v1

*Documento único de producto. Consolida los 15 manuales y todas las decisiones de la Puerta 0 en una sola fuente de verdad. Reemplaza las definiciones dispersas en los manuales cuando haya diferencia de redacción; la filosofía de los manuales se mantiene intacta.*

*Etapa 1 de 5 (PRD → Arquitectura → Modelo de datos → Motor de IA → Sprints). No contiene código. Me detengo al final para tu validación antes de la etapa 2.*

---

## 1. Concepto único (regla fundacional)

**VITA no administra tareas. VITA administra la vida completa del usuario.**

Toda decisión de producto, técnica o visual debe respetar este principio. Si una funcionalidad trata a VITA como un gestor de tareas, una agenda o una app fitness, no pertenece al proyecto.

---

## 2. Qué es y qué no es VITA

**Es:** un Sistema Operativo Personal impulsado por IA cuya misión es reducir al máximo la carga mental y ayudar a la usuaria a convertirse —y mantenerse— en la persona que quiere ser.

**No es:** agenda, gestor de hábitos, app fitness, app para bajar de peso, ni ERP.

La IA piensa, organiza, analiza, aprende y propone. La usuaria aprueba, modifica o rechaza. Nunca al revés.

---

## 3. Principios no negociables

1. La IA **analiza → propone → explica**; la usuaria **decide**.
2. Nunca generar culpa. Nunca reiniciar el progreso.
3. Todo tiene historial. Nada se elimina. Todo puede modificarse.
4. Ningún dato se registra dos veces. Todo está conectado.
5. Mínima escritura del usuario; máximo trabajo de la IA.
6. Toda recomendación se justifica. Nunca inventar, nunca improvisar; ante duda, proponer alternativas.
7. La IA nunca decide algo importante automáticamente: siempre pide aprobación.
8. La IA nunca aumenta la carga mental: cada recomendación simplifica.
9. Simplicidad obligatoria: si un elemento no ayuda a decidir mejor en ese momento, se elimina.
10. Diseñar para una usuaria; preparar para miles. La personalización vive en datos y configuración, nunca en código.

---

## 4. Usuaria y alcance

- **Usuaria inicial:** Yurnelly. Su perfil maestro es **dato**, no código.
- **Escala:** arquitectura multiusuario desde el diseño, sin reescritura futura.
- **Internacionalización desde el día uno:** no solo traducción de textos, también monedas, unidades, formatos de fecha/hora, regiones. Versión inicial en español.
- **Plataformas:** móvil primero (iOS, Android), con web. Offline para vivir el día.

---

## 5. Arquitectura de información — Navegación inteligente

Cinco pestañas en la versión inicial, pero **navegación dinámica, no rígida**:

- **Mi Vida** siempre es la pantalla principal.
- Las demás se reorganizan y destacan según el contexto y el Modo de Vida activo. Ejemplos: en embarazo, acceso rápido a Embarazo; en viaje, Viajes destacado; con un proyecto intenso, Proyectos con prioridad.

**Mapa de módulos → pestañas** (aprobado en D1):

| Pestaña | Contiene |
|---|---|
| **Mi Vida** | Pantalla principal: bloque diario de Dios, estado general, 3 prioridades, agenda, menú, entrenamiento, proyecto principal, familia, resumen de finanzas, cierre nocturno |
| **Salud** | Salud + Nutrición + Entrenamiento + Ciclo Femenino + modos Embarazo / Postparto-Lactancia / Enfermedad / Recuperación |
| **Proyectos** | Proyectos + Empresa + Sueños |
| **Calendario** | Calendario unificado + Documentos (vencimientos) + Recordatorios |
| **Más** | Dios (experiencia completa), Familia, Finanzas (detalle), Armario, Viajes, Dashboard, Ajustes |

Dios y Finanzas, aunque viven en "Más", tienen presencia diaria en "Mi Vida" para no quedar enterrados.

---

## 6. Sistemas transversales (el núcleo de VITA)

Estos sistemas no son módulos: son la maquinaria que hace que todo funcione como un solo organismo.

### 6.1 Context Snapshot — el corazón
Antes de **cualquier** recomendación, la IA construye primero el contexto completo de la usuaria (peso, sueño, energía, ánimo, ciclo, agenda, objetivos, finanzas, proyectos, familia, modo de vida activo, historial relevante). **Ninguna IA puede decidir leyendo una sola tabla.** Es obligatorio y es el núcleo del Motor de IA.

### 6.2 Pipeline Único de Propuestas
Todo lo que la IA sugiere —tarjetas de Mi Vida, progresiones de entrenamiento, menús, consejo financiero, decisiones de empresa— fluye por un único flujo:

**Analizar → Proponer → Explicar → (Aceptar | Modificar | Rechazar) → Resultado → Aprender.**

Cada propuesta y su desenlace quedan registrados. La IA aprende de cada decisión.

### 6.3 Modos de Vida (máquina de estados automática)
La IA detecta y activa el modo según el contexto, automáticamente cuando es posible. Modos: **Normal, Viaje, Vacaciones, Embarazo, Lactancia, Enfermedad, Recuperación, Alta Carga Laboral, Descanso, Fin de Semana**, y sensibilidad al ciclo. Cada modo adapta alimentación, entrenamiento, recordatorios, agenda y tono. Se definirá una **precedencia** entre modos en la etapa de arquitectura (p. ej., Enfermedad sobre Viaje). El cambio de modo importante se confirma; las adaptaciones derivadas se proponen.

### 6.4 Conversación continua (no es un onboarding)
VITA no tiene formularios de configuración. La IA conoce a la usuaria poco a poco, de forma natural. Puede decir "hoy necesito conocerte un poco mejor" y hacer **una sola pregunta**. Nunca pantallas con muchas preguntas. El perfil maestro se completa solo, con el tiempo, cuando un dato es necesario para una recomendación concreta.

### 6.5 Notificaciones (cuatro niveles)
- **Críticas:** salud, dinero, legal. Siempre notifican, tono neutro y útil.
- **Importantes:** reuniones, cumpleaños, eventos, viajes. Notifican.
- **Inteligentes:** sugerencias de la IA dentro de la app; nunca como exigencia ni culpa.
- **Silenciosas:** nunca envían notificación; solo actualizan la información al abrir la app.

VITA no será una app que molesta.

### 6.6 Historial append-only
Nada se elimina jamás. Los datos clave se guardan como registro inmutable con vistas de estado actual, para construir la historia completa de la usuaria y responder preguntas a años de distancia.

### 6.7 Privacidad por niveles
Datos sensibles (salud, ciclo, embarazo, finanzas, reflexiones espirituales) con protección reforzada. **Los datos de Juan Miguel —fotos, salud, vacunas, colegio, documentos, recuerdos— se registran desde el primer día con un nivel superior de privacidad.** Exportar y borrar datos disponible (alineado con estándares globales tipo GDPR). El detalle técnico (cifrado, RLS, controles de acceso) se define en la etapa de arquitectura.

### 6.8 Internacionalización
Diseño i18n completo desde el inicio: textos, monedas, unidades, fechas, horarios, regiones.

### 6.9 IA agnóstica del proveedor
La arquitectura permitirá cambiar entre OpenAI, Anthropic, Gemini u otros sin reconstruir la aplicación. Ningún módulo depende de un proveedor concreto. Estrategia por niveles (modelo económico para rutinas en lote nocturno; modelo potente para decisiones complejas) para controlar costo a escala.

### 6.10 Frontera offline
**Offline (vivir el día):** ver el plan ya generado, leer el versículo guardado, registrar peso, marcar comidas y entrenamientos, consultar agenda. **Online (generar):** menús nuevos, recomendaciones, informes, análisis. Lo generado de madrugada queda disponible offline durante el día.

### 6.11 Guardarraíles médicos
La IA nunca sustituye a un profesional. Nutrición y entrenamiento son **estructura organizativa**. Toda recomendación indica claramente cuándo corresponde consultar a un especialista, especialmente en embarazo, resistencia a la insulina, postparto y enfermedad. La guía de un profesional puede sobreescribir los valores por defecto de la IA.

---

## 7. Ciclos de análisis de la IA

- **Diario (madrugada):** revisa contexto completo y construye el plan del día. No pregunta; revisa.
- **Semanal (domingo):** revisión breve (máx. 5 min) + planificación de la semana siguiente.
- **Mensual (día 1):** informe ejecutivo en lenguaje sencillo (lo mejor, lo difícil, lo aprendido, qué mantener, qué cambiar) + propuesta del mes.
- **Trimestral:** evolución completa de toda la vida + propuesta de nuevo ciclo (incluye nuevo programa de entrenamiento de 12 semanas).

---

## 8. Módulos — especificación consolidada

Cada módulo: propósito, contenido esencial, comportamiento de IA y conexiones. El detalle fino vive en los manuales 2–12; aquí quedan los requisitos consolidados.

### 8.1 Mi Vida (Manual 5)
Centro de operaciones, curado dinámicamente por la IA. Orden fijo de bloques: bienvenida (fecha, clima, saludo), versículo del día, estado general, **tres prioridades** (máximo, justificadas, de cualquier área), agenda inteligente, menú de hoy, entrenamiento de hoy, proyecto principal (solo el siguiente paso), tiempo con la familia (sugerencia), finanzas (resumen mínimo), cierre nocturno (cómo estuvo el día + lo mejor en una línea). Nunca igual dos días. Objetivo: claridad total en menos de dos minutos.

### 8.2 Dios (Manual 7)
Versículo diario (366 únicos al año, sin repetir), enseñanza ≤3 líneas y reflexión de una pregunta —ambas generadas por IA—, oración generada por IA, historial, favoritos, "Dios ha sido fiel" (momentos que la IA recuerda en etapas difíciles), planes de lectura opcionales, búsqueda por temas, resumen anual. **Contenido bíblico desacoplado del código y preparado para múltiples traducciones** (la traducción se puede cambiar sin tocar el código). Nunca red social, sin likes ni comparaciones. No sustituye la relación personal ni la lectura completa de la Biblia.

### 8.3 Salud (Manuales 6)
Peso (semanal, un indicador más), medidas (mensuales), fotos (mensuales, comparación visual), exámenes, medicamentos, suplementos, sueño, energía, ánimo. Historial completo. Sueño/energía manual al inicio, **preparado para Apple Health, Health Connect y relojes**. La salud nunca se evalúa por un solo dato.

### 8.4 Nutrición (Manual 6)
Menú semanal automático y editable, bloquear favoritas, recetas propias, lista de compras por categorías. Modo Visual y Modo Precisión (gramos), sin conteo obsesivo de calorías, sin dietas extremas. Porciones según objetivo.

### 8.5 Entrenamiento (Manual 6)
Programas de ~12 semanas (fuerza, cardio, movilidad, descanso). Sin cambios semanales; progresiones (peso, repeticiones, series, tiempo de caminata) solo con motivo claro, justificadas y aprobadas. Caminadora con progresión gradual. Historial y comparaciones.

### 8.6 Ciclo Femenino (Manual 6)
Registro mínimo (inicio, fin, síntomas opcionales), predicción, adaptación de alimentación y entrenamiento según patrones personales. Nunca asume un patrón universal.

### 8.7 Modos Embarazo / Postparto-Lactancia / Enfermedad / Recuperación
Adaptan automáticamente objetivos, alimentación, entrenamiento, seguimiento, controles, vitaminas y recordatorios, conservando todo el historial. Prioridad de recuperación sobre pérdida de peso. Gestionados por la máquina de Modos de Vida (6.3).

### 8.8 Empresa (Manual 8)
Dirección estratégica del CEO; no sustituye el ERP. Objetivos trimestrales (3–5 clave), indicadores personales, ideas, reuniones, registro de decisiones (motivo, ventajas, riesgos, alternativas, resultado esperado, aprendizaje posterior), notas. Integra con ERP sin duplicar: solo indicadores y recordatorios estratégicos.

### 8.9 Proyectos (Manual 8)
Máximo **3 proyectos activos** (solo iniciativas con inicio y fin; los sistemas permanentes no cuentan). Descomposición automática en fases → tareas → calendario. Un proyecto principal del mes, visible en Mi Vida solo con el siguiente paso. Gestión inteligente del tiempo según contexto real (sin programar en horarios de cansancio).

### 8.10 Sueños (Manual 3)
Sueños de vida (no tareas): objetivo, plan, primer paso, estado, fecha estimada, progreso. Pueden tener un fondo de ahorro asociado (ver Finanzas).

### 8.11 Familia (Manual 10)
Personas prioritarias. Perfil por hijo (Juan Miguel) con datos, salud infantil, colegio, intereses, logros, fotos. Línea de tiempo de vida. Tiempo de calidad (sugerencias, no obligatorias). Pareja (aniversarios, citas, recuerdos, metas) sin actuar como terapeuta. Gratitud nocturna opcional (una línea → diario familiar). Recuerdos tipo álbum de vida. Soporta un segundo hijo sin otra app. Privacidad reforzada para el menor.

### 8.12 Finanzas (Manual 9)
Libertad financiera; no es contable, banco ni ERP. Dashboard mínimo (patrimonio, ahorro, meta anual, próximo gasto). Patrimonio con nivel de detalle a elección. Metas, presupuesto que aprende y no juzga, análisis previo de compras importantes, Fondo de Sueños. El dinero como medio, no como fin.

### 8.13 Armario (Manual 3)
Inventario, outfits, lista de compras, favoritas, prendas a vender/donar, renovación por temporada.

### 8.14 Viajes (Manual 9)
Ficha por viaje (destino, fechas, presupuesto, reservas, checklist, documentos, equipaje, lugares, notas, fotos). Modo Viaje adapta entrenamiento, alimentación, recordatorios y agenda para disfrutar sin perder del todo los hábitos.

### 8.15 Calendario (Manual 11)
Calendario unificado (todo conectado). **VITA es la fuente de verdad**; Google/Apple Calendar solo sincronizan, nunca al revés. Planificación automática cada madrugada y replanificación ante imprevistos sin perder el objetivo semanal. Sin duplicar (deduplicación por id externo espejado).

### 8.16 Documentos (Manual 3)
Carnet, pasaporte, licencia, seguros, garantías, contratos, facturas, documentos del niño. Avisos antes del vencimiento (recordatorios críticos).

### 8.17 Dashboard (Manual 12)
Panel ejecutivo, máx. 8 tarjetas, colores de estado (verde/amarillo/rojo), entendible en segundos. Línea de Vida "Mi Historia" automática. Resúmenes mensual y anual (tipo "libro del año"). Comparaciones respaldadas por datos. Exportación a PDF. Cada indicador responde una pregunta concreta o no existe.

---

## 9. Métricas de éxito

Evolución, no competencia. **Sin gamificación: sin puntos, medallas ni rachas que generen culpa.** El éxito se mide por reducción de carga mental, facilidad de uso, adherencia a largo plazo, calidad de las recomendaciones y mejora real de vida. Las señales se capturan de forma liviana y privada, sin convertir VITA en una app de tracking.

---

## 10. Fuera de alcance inicial (preparado, no construido)

Integraciones reales con wearables/Apple Health/Health Connect, Google/Apple Calendar, Gmail, Drive, ERP, clima y mapas: **interfaces preparadas en la arquitectura, implementación posterior.** Multiusuario en producción: diseñado, no comercializado aún.

---

## 11. Asuntos que se resuelven en las siguientes etapas

- **Arquitectura (etapa 2):** capas, frontera offline concreta, precedencia entre Modos de Vida, estrategia de sincronización y deduplicación, abstracción agnóstica de IA, seguridad y cifrado, i18n técnica.
- **Modelo de datos (etapa 3):** tablas, relaciones por identificadores únicos, patrón append-only, Context Snapshot como vista/servicio, niveles de privacidad.
- **Motor de IA (etapa 4):** Context Snapshot, Pipeline de Propuestas, ciclos de análisis, capa de proveedores, control de costos.
- **Sprints (etapa 5):** plan sobre las 12 fases del Manual 15.

---

*Fin del PRD Consolidado v1. Espero tu validación (aprobar, modificar o rechazar) antes de avanzar a la Arquitectura definitiva.*
