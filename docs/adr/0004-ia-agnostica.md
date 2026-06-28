# ADR 0004 — IA agnóstica del proveedor

**Contexto.** No queremos amarrar el proyecto a OpenAI, Anthropic, Gemini ni ningún proveedor.

**Decisión.** Toda la IA vive detrás de `AIProviderPort`. El proveedor se elige por configuración y se decide definitivamente solo cuando el MVP funcione y se pueda comparar con pruebas reales. En el Sprint 0 el puerto está vacío (sin IA).

**Consecuencias.** Cambiar de proveedor sin reescribir la app; las llaves viven solo en el servidor.
