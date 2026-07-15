// VITA — Feed de calendario (iCalendar/.ics)
//
// Publica los eventos de una usuaria como un calendario suscribible, para
// agregar en Google Calendar / Apple Calendar y recibir avisos con sonido en el
// teléfono. La única credencial es el `token` (uuid secreto de su perfil); con
// él se resuelve el user_id y se leen sus eventos con la service-role key
// (saltando RLS, pero acotado a esa usuaria).
//
// Se despliega sin verificación de JWT: Google lo consulta sin sesión.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function pad(n: number): string {
  return n.toString().padStart(2, "0");
}

// DateTime UTC -> 'YYYYMMDDTHHMMSSZ'
function icsUtc(iso: string): string {
  const d = new Date(iso);
  return (
    `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}` +
    `T${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}Z`
  );
}

// Fecha (all-day) -> 'YYYYMMDD'
function icsDate(iso: string): string {
  const d = new Date(iso);
  return `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}`;
}

// Escapa texto según RFC 5545.
function esc(s: string | null): string {
  if (!s) return "";
  return s
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\n/g, "\\n");
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const token = url.searchParams.get("token");
  if (!token) {
    return new Response("Falta el token.", { status: 400 });
  }

  const sb = createClient(SUPABASE_URL, SERVICE_KEY);

  // token -> user_id
  const { data: perfil } = await sb
    .from("profiles")
    .select("id, display_name")
    .eq("calendar_token", token)
    .maybeSingle();

  if (!perfil) {
    return new Response("Calendario no encontrado.", { status: 404 });
  }

  // Eventos activos (no cancelados) + sus recordatorios.
  const { data: eventos } = await sb
    .from("events")
    .select(
      "id, titulo, descripcion, inicio, fin, todo_el_dia, estado, updated_at",
    )
    .eq("user_id", perfil.id)
    .neq("estado", "cancelado")
    .order("inicio");

  const ids = (eventos ?? []).map((e) => e.id);
  const recordatorios: Record<string, number[]> = {};
  if (ids.length > 0) {
    const { data: recs } = await sb
      .from("event_reminders")
      .select("event_id, offset_min")
      .in("event_id", ids);
    for (const r of recs ?? []) {
      (recordatorios[r.event_id] ??= []).push(r.offset_min as number);
    }
  }

  const dtstamp = icsUtc(new Date().toISOString());
  const lines: string[] = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//VITA//Calendario//ES",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "X-WR-CALNAME:VITA",
    "X-WR-TIMEZONE:UTC",
  ];

  for (const e of eventos ?? []) {
    lines.push("BEGIN:VEVENT");
    lines.push(`UID:${e.id}@vita`);
    lines.push(`DTSTAMP:${dtstamp}`);
    if (e.todo_el_dia) {
      lines.push(`DTSTART;VALUE=DATE:${icsDate(e.inicio)}`);
    } else {
      lines.push(`DTSTART:${icsUtc(e.inicio)}`);
      if (e.fin) lines.push(`DTEND:${icsUtc(e.fin)}`);
    }
    lines.push(`SUMMARY:${esc(e.titulo)}`);
    if (e.descripcion) lines.push(`DESCRIPTION:${esc(e.descripcion)}`);
    // Un recordatorio por cada offset guardado (aviso con sonido del sistema).
    for (const off of recordatorios[e.id] ?? []) {
      lines.push("BEGIN:VALARM");
      lines.push("ACTION:DISPLAY");
      lines.push(`DESCRIPTION:${esc(e.titulo)}`);
      lines.push(`TRIGGER:-PT${off}M`);
      lines.push("END:VALARM");
    }
    lines.push("END:VEVENT");
  }

  lines.push("END:VCALENDAR");

  // CRLF por especificación iCalendar.
  const body = lines.join("\r\n");
  return new Response(body, {
    status: 200,
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Cache-Control": "public, max-age=300",
    },
  });
});
