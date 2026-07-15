# Documentación de VITA

- **`VITA_MASTER.md`** — índice operativo del producto. Empieza aquí para
  orientarte rápido; remite al documento detallado según la tarea.
- `diseno/` — documentos de diseño (PRD, Arquitectura, Modelo de Datos, Motor de IA, Sprints, Constitución Técnica, Plan del Sprint 0). Son la fuente de verdad del producto y deben mantenerse actualizados si la realidad diverge.
- `adr/` — Architecture Decision Records: cada decisión técnica importante, en una página breve (contexto · decisión · consecuencias).

> Nota: versiones antiguas de este índice citaban `manuales/` (los 15 manuales
> originales). Ese directorio no está en el repo; su visión ya quedó consolidada
> en el PRD y en `diseno/VITA_Consolidacion_Puerta_0.md`.

## Principios permanentes (Constitución Técnica)

1. Primero **funciona**, luego **bonito**, luego **inteligente**, luego **potente**.
2. Construir solo lo que se usará en los primeros meses.
3. La experiencia de usuario manda (rápida, intuitiva, <5 s, reduce carga mental).
4. Gratis primero: nada de pago si una alternativa gratuita logra ≥90%.
5. La IA propone, la usuaria decide.
