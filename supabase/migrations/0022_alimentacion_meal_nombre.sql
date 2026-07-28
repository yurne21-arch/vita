-- 0022 · Alimentación — nombre legible en el estado de comida.
-- Denormaliza el nombre del plato (o "comí otra cosa") para que el resumen del
-- mes (Mi Mes) lo lea directo de la tabla, sin depender del recetario (que vive
-- en código). Mismo patrón que Finanzas guarda la categoría como texto.

alter table public.nutrition_meal_state
  add column if not exists nombre text;
