// Recordatorios de hábitos por Telegram.
// Lo invoca pg_cron cada 5 min. Revisa qué recordatorio toca en esta ventana
// (su hora y su día), que el hábito no esté hecho hoy, y le escribe por Telegram
// con un botón "✅ Ya lo hice" para marcarlo sin salir del aviso.
// Secretos: TELEGRAM_BOT_TOKEN, CRON_SECRET. SUPABASE_* se inyectan solos.

import { createClient } from "jsr:@supabase/supabase-js@2";

const TZ = "America/Santiago";
const VENTANA_MIN = 5; // debe coincidir con el intervalo del cron.

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

// Día de la semana en Chile: 1=Lun .. 7=Dom.
const DIAS: Record<string, number> = {
  Mon: 1,
  Tue: 2,
  Wed: 3,
  Thu: 4,
  Fri: 5,
  Sat: 6,
  Sun: 7,
};

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

  // Hora, fecha y día actuales en Chile.
  const now = new Date();
  const hhmm = now.toLocaleTimeString("en-GB", {
    timeZone: TZ,
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  const hoy = now.toLocaleDateString("en-CA", { timeZone: TZ }); // YYYY-MM-DD
  const dia = DIAS[
    now.toLocaleDateString("en-US", { timeZone: TZ, weekday: "short" })
  ] ?? 0;
  const nowMin = parseInt(hhmm.slice(0, 2), 10) * 60 +
    parseInt(hhmm.slice(3, 5), 10);

  const enVentana = (min: number | null) =>
    min !== null && min <= nowMin && min > nowMin - VENTANA_MIN;

  const { data: conns } = await supabase
    .from("notif_telegram")
    .select("user_id, chat_id")
    .eq("activo", true);
  if (!conns?.length) return new Response("sin conexiones", { status: 200 });

  async function enviar(
    chatId: string,
    habitoId: string,
    cuerpo: string,
  ) {
    await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: chatId,
        text: `⏰ Recordatorio VITA\n${cuerpo}`,
        reply_markup: {
          inline_keyboard: [[
            {
              text: "✅ Ya lo hice",
              callback_data: `d|${habitoId}|${hoy}`,
            },
            {
              text: "✖️ No lo hice",
              callback_data: `n|${habitoId}|${hoy}`,
            },
          ]],
        },
      }),
    });
  }

  let enviados = 0;
  for (const c of conns) {
    const { data: habitos } = await supabase
      .from("habitos")
      .select("id, nombre, emoji, hora")
      .eq("user_id", c.user_id)
      .eq("activo", true)
      .eq("recordar", true);
    if (!habitos?.length) continue;
    const porId = new Map(habitos.map((h) => [h.id as string, h]));

    const { data: recordatorios } = await supabase
      .from("habito_recordatorios")
      .select("habito_id, hora, dias, nota")
      .eq("user_id", c.user_id)
      .eq("activo", true);

    const { data: logs } = await supabase
      .from("habitos_log")
      .select("habito_id, hecho")
      .eq("user_id", c.user_id)
      .eq("fecha", hoy);
    // Ya "respondidos" hoy: marcó sí o no. En ambos casos dejamos de insistir.
    const respondidos = new Set((logs ?? []).map((l) => l.habito_id));

    // Recordatorios que aplican HOY, y cuántos tiene cada hábito hoy.
    const tieneReglas = new Set(
      (recordatorios ?? []).map((r) => r.habito_id as string),
    );
    const cuentaHoy = new Map<string, number>();
    const aplican: { habitoId: string; hora: string; nota: string | null }[] =
      [];
    for (const r of recordatorios ?? []) {
      const dias = (r.dias as number[] | null) ?? [];
      if (dias.length && !dias.includes(dia)) continue; // no toca hoy
      const hid = r.habito_id as string;
      cuentaHoy.set(hid, (cuentaHoy.get(hid) ?? 0) + 1);
      aplican.push({ habitoId: hid, hora: r.hora as string, nota: r.nota });
    }

    for (const a of aplican) {
      const h = porId.get(a.habitoId);
      if (!h) continue;
      // Si ya está hecho y es su único aviso del día, no insistir. Los hábitos
      // con dos horas (p. ej. comer) sí avisan ambas veces.
      const soloUna = (cuentaHoy.get(a.habitoId) ?? 0) <= 1;
      if (respondidos.has(a.habitoId) && soloUna) continue;
      if (!enVentana(parseHora(a.hora))) continue;
      const cuerpo = a.nota && a.nota.trim()
        ? a.nota
        : `${h.emoji ?? "•"} ${h.nombre}`;
      await enviar(c.chat_id as string, a.habitoId, cuerpo);
      enviados++;
    }

    // Compatibilidad: hábitos sin reglas pero con su hora simple de siempre.
    for (const h of habitos) {
      if (tieneReglas.has(h.id as string) || respondidos.has(h.id)) continue;
      if (!enVentana(parseHora(h.hora as string | null))) continue;
      await enviar(
        c.chat_id as string,
        h.id as string,
        `${h.emoji ?? "•"} ${h.nombre}`,
      );
      enviados++;
    }
  }
  return new Response(`ok (${enviados} enviados)`, { status: 200 });
});
