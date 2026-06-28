/// Puerto agnóstico del proveedor de IA.
///
/// **Vacío a propósito en el Sprint 0**: no hay integración de IA todavía.
/// Toda la inteligencia (Context Snapshot, Pipeline de Propuestas, ciclos)
/// llegará en sprints posteriores detrás de esta interfaz, de modo que se
/// pueda cambiar entre OpenAI, Anthropic, Gemini u otro sin tocar la app.
///
/// El proveedor definitivo se decide solo cuando el MVP funcione y se pueda
/// comparar privacidad, calidad y costo con pruebas reales.
abstract interface class AIProviderPort {
  // Sin métodos aún. Se definirán al construir el Motor de IA (Nivel 1).
}
