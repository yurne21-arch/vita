// Webhook de Telegram: recibe los toques del botón "✅ Ya lo hice" y las notas
// que la usuaria escribe. Marca el hábito en habitos_log y guarda la nota.
// Secretos: TELEGRAM_BOT_TOKEN, TELEGRAM_WEBHOOK_SECRET. SUPABASE_* se inyectan.

import { createClient } from "jsr:@supabase/supabase-js@2";

const TZ = "America/Santiago";

function hhmm(d: Date): string {
  return d.toLocaleTimeString("es-CL", {
    timeZone: TZ,
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
}

async function tg(metodo: string, body: unknown) {
  const token = Deno.env.get("TELEGRAM_BOT_TOKEN");
  return await fetch(`https://api.telegram.org/bot${token}/${metodo}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

Deno.serve(async (req) => {
  // Solo Telegram (con el secreto acordado) puede llamar aquí.
  const secret = Deno.env.get("TELEGRAM_WEBHOOK_SECRET");
  if (
    secret &&
    req.headers.get("x-telegram-bot-api-secret-token") !== secret
  ) {
    return new Response("no", { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let update: Record<string, any>;
  try {
    update = await req.json();
  } catch (_) {
    return new Response("ok", { status: 200 });
  }

  const usuarioDe = async (chatId: string) => {
    const { data } = await supabase
      .from("notif_telegram")
      .select("user_id")
      .eq("chat_id", chatId)
      .maybeSingle();
    return data?.user_id as string | undefined;
  };

  // ── 1) Toque de botón (marcar hecho / deshacer) ─────────────────────────
  if (update.callback_query) {
    const cq = update.callback_query;
    const chatId = String(cq.message?.chat?.id ?? "");
    const msgId = cq.message?.message_id;
    const userId = await usuarioDe(chatId);
    const partes = String(cq.data ?? "").split("|"); // accion|habito|fecha
    const [accion, habitoId, fecha] = partes;

    if (userId && habitoId && fecha) {
      if (accion === "d") {
        await supabase.from("habitos_log").upsert({
          user_id: userId,
          habito_id: habitoId,
          fecha,
          hecho: true,
        }, { onConflict: "habito_id,fecha" });
        // Queda pendiente de nota (opcional).
        await supabase.from("telegram_pendiente").upsert({
          chat_id: chatId,
          user_id: userId,
          habito_id: habitoId,
          fecha,
          created_at: new Date().toISOString(),
        }, { onConflict: "chat_id" });

        await tg("answerCallbackQuery", {
          callback_query_id: cq.id,
          text: "¡Hecho! ✅  Si quieres, escríbeme una nota.",
        });
        await tg("editMessageReplyMarkup", {
          chat_id: chatId,
          message_id: msgId,
          reply_markup: {
            inline_keyboard: [[{
              text: "↩️ Deshacer",
              callback_data: `u|${habitoId}|${fecha}`,
            }]],
          },
        });
        const base = cq.message?.text ?? "Recordatorio VITA";
        await tg("editMessageText", {
          chat_id: chatId,
          message_id: msgId,
          text: `${base}\n\n✅ Hecho. ¿Anotar algo? (ej: 4×12, 2 litros, 20 min)`,
          reply_markup: {
            inline_keyboard: [[{
              text: "↩️ Deshacer",
              callback_data: `u|${habitoId}|${fecha}`,
            }]],
          },
        });
      } else if (accion === "u") {
        await supabase.from("habitos_log").upsert({
          user_id: userId,
          habito_id: habitoId,
          fecha,
          hecho: false,
        }, { onConflict: "habito_id,fecha" });
        await supabase.from("telegram_pendiente").delete().eq(
          "chat_id",
          chatId,
        );
        await tg("answerCallbackQuery", {
          callback_query_id: cq.id,
          text: "Listo, lo dejé sin marcar.",
        });
        await tg("editMessageReplyMarkup", {
          chat_id: chatId,
          message_id: msgId,
          reply_markup: {
            inline_keyboard: [[{
              text: "✅ Ya lo hice",
              callback_data: `d|${habitoId}|${fecha}`,
            }]],
          },
        });
      } else {
        await tg("answerCallbackQuery", { callback_query_id: cq.id });
      }
    } else {
      await tg("answerCallbackQuery", { callback_query_id: cq.id });
    }
    return new Response("ok", { status: 200 });
  }

  // ── 2) Mensaje de texto (posible nota) ──────────────────────────────────
  const msg = update.message ?? update.edited_message;
  const texto: string = (msg?.text ?? "").trim();
  if (msg && texto && !texto.startsWith("/")) {
    const chatId = String(msg.chat?.id ?? "");
    const { data: pend } = await supabase
      .from("telegram_pendiente")
      .select("user_id, habito_id, fecha, created_at")
      .eq("chat_id", chatId)
      .maybeSingle();

    const reciente = pend &&
      (Date.now() - new Date(pend.created_at as string).getTime()) <
        3 * 3600 * 1000;

    if (pend && reciente) {
      const { data: log } = await supabase
        .from("habitos_log")
        .select("nota")
        .eq("habito_id", pend.habito_id)
        .eq("fecha", pend.fecha)
        .maybeSingle();
      const previa = (log?.nota as string | null) ?? "";
      const linea = `${hhmm(new Date())} · ${texto}`;
      const nota = previa ? `${previa}\n${linea}` : linea;

      await supabase.from("habitos_log").upsert({
        user_id: pend.user_id,
        habito_id: pend.habito_id,
        fecha: pend.fecha,
        hecho: true,
        nota,
      }, { onConflict: "habito_id,fecha" });
      await supabase.from("telegram_pendiente").delete().eq("chat_id", chatId);

      await tg("sendMessage", {
        chat_id: chatId,
        text: `📝 Anotado: ${texto}`,
      });
    }
    // Si no hay pendiente, lo ignoramos en silencio.
  }

  return new Response("ok", { status: 200 });
});
