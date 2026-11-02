// Recordatorios de hábitos por Telegram.
// Lo invoca pg_cron cada 15 min. Revisa qué hábito tiene su hora en esta
// ventana, que no esté hecho hoy, y le escribe a la usuaria por Telegram.
// Secretos: TELEGRAM_BOT_TOKEN, CRON_SECRET. SUPABASE_* se inyectan solos.

import { createClient } from "jsr:@supabase/supabase-js@2";

const TZ = "America/Santiago";

/** "6:00 PM" / "9:00 PM" / "08:30" -> minutos desde medianoche, o null. */
function parseHora(s: string | null): number | null {
  if (!s) return null;
  const m = s.trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?/);
  if (!m) return null;
  let h = parseInt(m[1], 10);
  const min = parseInt(m[2], 10);
  const ap = m[3]?.toUpperCase();
  if (ap === "PM" && h < 12) h += 12;
  if (ap === "AM" && h === 12) h = 0;
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

Deno.serve(async (req) => {
  // Solo el cron (con el secreto) puede dispararlo.
  const cronSecret = Deno.env.get("CRON_SECRET");
  if (cronSecret && req.headers.get("x-cron-secret") !== cronSecret) {
    return new Response("no autorizado", { status: 401 });
  }

  const botToken = Deno.env.get("TELEGRAM_BOT_TOKEN");
  if (!botToken) return new Response("sin bot token", { status: 200 });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Hora y fecha actuales en Chile.
  const now = new Date();
  const hhmm = now.toLocaleTimeString("en-GB", {
    timeZone: TZ,
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  const hoy = now.toLocaleDateString("en-CA", { timeZone: TZ }); // YYYY-MM-DD
  const nowMin = parseInt(hhmm.slice(0, 2), 10) * 60 +
    parseInt(hhmm.slice(3, 5), 10);

  const { data: conns } = await supabase
    .from("notif_telegram")
    .select("user_id, chat_id")
    .eq("activo", true);
  if (!conns?.length) return new Response("sin conexiones", { status: 200 });

  let enviados = 0;
  for (const c of conns) {
    const { data: habitos } = await supabase
      .from("habitos")
      .select("id, nombre, emoji, hora")
      .eq("user_id", c.user_id)
      .eq("activo", true)
      .eq("recordar", true);
    if (!habitos?.length) continue;

    const { data: logs } = await supabase
      .from("habitos_log")
      .select("habito_id, hecho")
      .eq("user_id", c.user_id)
      .eq("fecha", hoy);
    const hechos = new Set(
      (logs ?? []).filter((l) => l.hecho).map((l) => l.habito_id),
    );

    for (const h of habitos) {
      const min = parseHora(h.hora);
      if (min === null) continue;
      // Ventana de 15 min: toca si su hora cae desde la última corrida hasta ahora.
      if (min <= nowMin && min > nowMin - 15 && !hechos.has(h.id)) {
        const txt = `⏰ Recordatorio VITA\n${h.emoji ?? "•"} ${h.nombre}`;
        await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ chat_id: c.chat_id, text: txt }),
        });
        enviados++;
      }
    }
  }
  return new Response(`ok (${enviados} enviados)`, { status: 200 });
});
