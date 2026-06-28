# ADR 0005 — iPhone vía Flutter Web PWA

**Contexto.** La usuaria usa iPhone y no quiere pagar Apple Developer Program ($99/año) en el MVP.

**Decisión.** Probar y usar VITA en iPhone como **PWA** (Flutter Web instalada en pantalla de inicio vía Safari). Sin Apple Developer, sin TestFlight, sin Mac.

**Consecuencias.** Costo $0. Limitaciones conocidas de PWA en iOS (push sin silencioso/segundo plano, caché evictable). Apple Developer solo si más adelante se justifica, con aprobación explícita.
