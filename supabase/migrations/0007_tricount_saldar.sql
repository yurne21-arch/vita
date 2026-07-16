-- VITA — Migración 0007
-- Saldar el reparto compartido ("quedar a mano"). Guarda hasta qué fecha ya se
-- pagaron entre ellos: el balance Tricount solo cuenta los gastos compartidos
-- POSTERIORES a esa fecha. Así, tras saldar, el saldo vuelve a cero y no arrastra
-- meses viejos para siempre.

alter table public.profiles
  add column if not exists tricount_saldado_hasta date;
