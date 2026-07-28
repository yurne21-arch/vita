-- 0021 · Alimentación — "comí otra cosa".
-- Permite registrar lo que la usuaria SÍ comió cuando no comió lo planeado,
-- como texto libre. Queda en el historial (nutrition_meal_state). Forward-only.

alter table public.nutrition_meal_state
  add column if not exists comida_libre text;
