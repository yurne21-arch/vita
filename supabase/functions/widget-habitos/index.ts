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
      .select("habito_id, dias, nota")
      .eq("user_id", userId)
      .eq("activo", true),
    supabase
      .from("habitos_log")
      .select("habito_id, fecha, hecho")
      .eq("user_id", userId)
      .gte("fecha", desde),
  ]);

  // Reglas (días + nota) por hábito.
  type Regla = { dias: number[]; nota: string | null };
  const reglas = new Map<string, Regla[]>();
  for (const r of recRes.data ?? []) {
    const arr = reglas.get(r.habito_id as string) ?? [];
    arr.push({
      dias: (r.dias as number[] | null) ?? [],
      nota: r.nota as string | null,
    });
    reglas.set(r.habito_id as string, arr);
  }

  // Qué mostrar hoy para un hábito. Si sus reglas de hoy traen una nota (p. ej.
  // "Ir a caminar" los sábados), se usa esa en vez del nombre genérico. Devuelve
  // null si el hábito no toca hoy.
  const etiquetaHoy = (
    h: { id: string; nombre: string; emoji: string | null },
  ): string | null => {
    const rs = reglas.get(h.id);
    const generico = `${h.emoji ?? "•"} ${h.nombre}`;
    if (!rs || rs.length === 0) return generico; // diario, sin reglas
    const hoyRs = rs.filter((r) => r.dias.length === 0 || r.dias.includes(dia));
    if (hoyRs.length === 0) return null; // no toca hoy
    const notas = [
      ...new Set(
        hoyRs.map((r) => (r.nota ?? "").trim()).filter((n) => n.length > 0),
      ),
    ];
    return notas.length > 0 ? notas.join("  /  ") : generico;
  };

  // Fechas cumplidas por hábito (para la racha) y respuesta explícita de HOY.
  const cumplidas = new Map<string, Set<string>>();
  const estadoHoy = new Map<string, boolean>(); // true=hecho, false=no lo hice
  for (const l of logRes.data ?? []) {
    if (l.hecho) {
      let s = cumplidas.get(l.habito_id as string);
      if (!s) {
        s = new Set<string>();
        cumplidas.set(l.habito_id as string, s);
      }
      s.add(l.fecha as string);
    }
    if (l.fecha === hoy) {
      estadoHoy.set(l.habito_id as string, l.hecho as boolean);
    }
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
    .map((h) => {
      const texto = etiquetaHoy({
        id: h.id as string,
        nombre: h.nombre as string,
        emoji: h.emoji as string | null,
      });
      if (texto === null) return null; // no toca hoy
      const r = estadoHoy.get(h.id as string);
      const estado = r === undefined ? "pend" : (r ? "hecho" : "no");
      return {
        texto,
        estado, // "hecho" | "no" | "pend"
        racha: racha(h.id as string),
      };
    })
    .filter((x) => x !== null);

  return json({ fecha: hoy, items });
});
