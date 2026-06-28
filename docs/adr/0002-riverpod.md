# ADR 0002 — Gestión de estado: Riverpod

**Contexto.** Necesitamos estado escalable, testeable y de bajo boilerplate, fácil de entender para IA.

**Decisión.** Riverpod (sin generación de código en el MVP: `Provider`, `Notifier`, `AsyncNotifier`).

**Consecuencias.** Inyección de dependencias simple, buen manejo de async/streams, mainstream (mejor soporte de herramientas de IA).
