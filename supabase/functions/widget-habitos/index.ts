// Datos para el widget de hábitos (Scriptable en iPhone).
// El widget no inicia sesión: se identifica con un token de solo-lectura que
// viaja en la URL (?t=...). Devuelve los hábitos que tocan HOY, si están hechos
// y su racha. Service role; el token acota a una sola usuaria.

import { createClient } from "jsr:@supabase/supabase-js@2";

const TZ = "America/Santiago";
const DIAS: Record<string, number> = {
  Mon: 1,
  Tue: 2,
  Wed: 3,
  Thu: 4,
  Fri: 5,
  Sat: 6,
  Sun: 7,
};
const DIA_MS = 86400000;

function fecha(d: Date): string {
  return d.toLocaleDateString("en-CA", { timeZone: TZ }); // YYYY-MM-DD en Chile
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

Deno.serve(async (req) => {
  const token = new URL(req.url).searchParams.get("t");
  if (!token) return json({ error: "sin token" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: acc } = await supabase
    .from("widget_token")
    .select("user_id")
    .eq("token", token)
    .maybeSingle();
  if (!acc) return json({ error: "token inválido" }, 403);
  const userId = acc.user_id as string;

  const now = new Date();
  const hoy = fecha(now);
  const dia = DIAS[
    now.toLocaleDateString("en-US", { timeZone: TZ, weekday: "short" })
  ] ?? 0;
  const desde = fecha(new Date(now.getTime() - 60 * DIA_MS));

  const [habRes, recRes, logRes] = await Promise.all([
    supabase
      .from("habitos")
      .select("id, nombre, emoji")
      .eq("user_id", userId)
      .eq("activo", true)
      .order("orden"),
    supabase
      .from("habito_recordatorios")
      .select("habito_id, dias")
      .eq("user_id", userId)
      .eq("activo", true),
    supabase
      .from("habitos_log")
      .select("habito_id, fecha, hecho")
      .eq("user_id", userId)
      .gte("fecha", desde),
  ]);

  // Reglas de día por hábito.
  const reglas = new Map<string, number[][]>();
  for (const r of recRes.data ?? []) {
    const arr = reglas.get(r.habito_id as string) ?? [];
    arr.push((r.dias as number[] | null) ?? []);
    reglas.set(r.habito_id as string, arr);
  }
  // Un hábito "toca hoy" si no tiene reglas (diario) o alguna incluye hoy.
  const tocaHoy = (hid: string): boolean => {
    const rs = reglas.get(hid);
    if (!rs || rs.length === 0) return true;
    return rs.some((d) => d.length === 0 || d.includes(dia));
  };

  // Fechas cumplidas por hábito.
  const cumplidas = new Map<string, Set<string>>();
  const hechoHoy = new Set<string>();
  for (const l of logRes.data ?? []) {
    if (!l.hecho) continue;
    let s = cumplidas.get(l.habito_id as string);
    if (!s) {
      s = new Set<string>();
      cumplidas.set(l.habito_id as string, s);
    }
    s.add(l.fecha as string);
    if (l.fecha === hoy) hechoHoy.add(l.habito_id as string);
  }
  const racha = (hid: string): number => {
    const set = cumplidas.get(hid) ?? new Set<string>();
    let cur = now;
    if (!set.has(hoy)) cur = new Date(cur.getTime() - DIA_MS);
    let n = 0;
    while (set.has(fecha(cur))) {
      n++;
      cur = new Date(cur.getTime() - DIA_MS);
    }
    return n;
  };

  const items = (habRes.data ?? [])
    .filter((h) => tocaHoy(h.id as string))
    .map((h) => ({
      nombre: h.nombre as string,
      emoji: (h.emoji as string | null) ?? "•",
      hecho: hechoHoy.has(h.id as string),
      racha: racha(h.id as string),
    }));

  return json({ fecha: hoy, items });
});
