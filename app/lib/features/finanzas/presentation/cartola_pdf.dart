import 'dart:convert';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

import '../../../core/utils/moneda.dart';
import '../domain/finanzas.dart';

String _f(DateTime d) {
  const m = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic' //
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// Genera la cartola de un cuadre en PDF y abre el menú para compartirla
/// (WhatsApp, etc.). En pantallas sin compartir, se descarga.
Future<void> compartirCartolaPdf(Saldado s, List<Movimiento> gastos) async {
  final doc = pw.Document();
  const acento = PdfColor.fromInt(0xFF6E5E96);

  final rango = (s.desde != null && s.hasta != null)
      ? '${_f(s.desde!)}  a  ${_f(s.hasta!)}'
      : 'Cuadre del ${_f(s.fecha)}';

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text('Cartola — Gastos compartidos',
            style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: acento)),
        pw.SizedBox(height: 4),
        pw.Text(rango, style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 16),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: acento),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
          },
          headers: ['Fecha', 'Categoría', 'Puso', 'Monto'],
          data: [
            for (final m in gastos)
              [
                _f(m.fecha),
                '${m.categoria}${m.nota != null ? ' (${m.nota})' : ''}',
                m.quien ?? '—',
                formatoMoneda(m.monto),
              ],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(),
        _fila('Total repartido', formatoMoneda(s.totalRepartido), bold: true),
        _fila('Puso Yurby', formatoMoneda(s.puestoPorYurby)),
        _fila('Puso Juan', formatoMoneda(s.puestoPorJuan)),
        _fila('Cada uno', formatoMoneda(s.totalRepartido / 2)),
        pw.SizedBox(height: 8),
        if (s.quienCobra != null)
          pw.Text(
            s.quienCobra == 'Yurby'
                ? 'Juan le pagó a Yurby ${formatoMoneda(s.montoAjuste)}'
                : 'Yurby le pagó a Juan ${formatoMoneda(s.montoAjuste)}',
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: acento),
          )
        else
          pw.Text('Quedaron a mano.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.Text('Generado con VITA',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ),
  );

  final bytes = await doc.save();
  final nombre = 'cartola_${s.fecha.year}_${s.fecha.month}.pdf';
  // Descarga directa del navegador (sin plugins de compartir, que no funcionan
  // en web). En el computador guarda el PDF; en el iPhone lo abre en Safari,
  // desde donde se comparte a WhatsApp con el botón de compartir.
  final dataUrl = 'data:application/pdf;base64,${base64Encode(bytes)}';
  final a = web.HTMLAnchorElement()
    ..href = dataUrl
    ..download = nombre
    ..target = '_blank'
    ..style.display = 'none';
  web.document.body?.appendChild(a);
  a.click();
  a.remove();
}

pw.Widget _fila(String label, String valor, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(valor,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
