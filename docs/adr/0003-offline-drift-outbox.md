# ADR 0003 — Offline: Drift + Outbox (PowerSync diferido)

**Contexto.** Offline-first es requisito, pero regla "gratis primero": no adoptar pago si una alternativa gratuita logra ≥90%.

**Decisión.** Drift (SQLite) + patrón outbox propio, detrás de `SyncPort`. PowerSync queda como mejora futura, solo con evidencia real.

**Consecuencias.** $0 en servicios; control total y sin lock-in; el modelo append-only hace la cola de sync simple. En el Sprint 0 el caché es esqueleto y best-effort (Supabase es la fuente de verdad).
