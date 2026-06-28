# ADR 0001 — Clean Architecture + feature-first

**Contexto.** VITA debe crecer 10 años sin reescribirse y construirse con ayuda de IA.

**Decisión.** Clean Architecture estricta (presentación → dominio ← datos; dominio en Dart puro) con organización feature-first. Los `features/` no se importan entre sí; se comunican por el núcleo (`core/`).

**Consecuencias.** Módulos aislados y testeables; el dominio no depende de Flutter ni Supabase; mayor claridad para desarrollo asistido por IA.
