import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Color sutil por área (mismo vocabulario que Calendario). Apagado, sobrio.
Color areaColor(String? a) {
  switch (a) {
    case 'Trabajo / Empresa':
      return const Color(0xFF5E7A93);
    case 'Personal':
      return const Color(0xFF7C8A5E);
    case 'Familia':
      return const Color(0xFFB08968);
    case 'Salud':
      return const Color(0xFF5E9E83);
    case 'Colegio / Juan Miguel':
      return const Color(0xFF8E7CA6);
    case 'Finanzas':
      return const Color(0xFFC2A45A);
    case 'Viaje':
      return const Color(0xFF5FA0A0);
    default:
      return const Color(0xFF8A857A);
  }
}

const List<String> kAreas = [
  'Trabajo / Empresa',
  'Personal',
  'Familia',
  'Salud',
  'Colegio / Juan Miguel',
  'Finanzas',
  'Viaje',
  'Otro',
];

/// Anillo de progreso — elemento firma del módulo. Oliva sobre pista tenue.
class AnilloProgreso extends StatelessWidget {
  const AnilloProgreso({
    required this.progreso,
    this.tamano = 64,
    this.grosor = 6,
    this.mostrarTexto = true,
    super.key,
  });

  final int progreso; // 0..100
  final double tamano;
  final double grosor;
  final bool mostrarTexto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = (progreso.clamp(0, 100)) / 100.0;
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(tamano, tamano),
            painter: _AnilloPainter(
              fraccion: p,
              grosor: grosor,
              pista: cs.outlineVariant.withValues(alpha: 0.30),
              acento: AppColors.olive,
            ),
          ),
          if (mostrarTexto)
            Text(
              '$progreso%',
              style: TextStyle(
                fontSize: tamano * 0.26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: cs.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  _AnilloPainter({
    required this.fraccion,
    required this.grosor,
    required this.pista,
    required this.acento,
  });

  final double fraccion;
  final double grosor;
  final Color pista;
  final Color acento;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = (size.width - grosor) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..color = pista;
    canvas.drawCircle(centro, radio, track);

    if (fraccion > 0) {
      final arco = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round
        ..color = acento;
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: radio),
        -math.pi / 2,
        2 * math.pi * fraccion,
        false,
        arco,
      );
    }
  }

  @override
  bool shouldRepaint(_AnilloPainter old) =>
      old.fraccion != fraccion ||
      old.grosor != grosor ||
      old.pista != pista ||
      old.acento != acento;
}

/// Chip de estado del proyecto, sobrio.
class ChipEstado extends StatelessWidget {
  const ChipEstado({required this.estado, super.key});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      'activo' => ('Activo', AppColors.olive),
      'pausado' => ('Pausado', AppColors.warning),
      'completado' => ('Completado', AppColors.success),
      'archivado' => ('Archivado', const Color(0xFF8A857A)),
      _ => (estado, const Color(0xFF8A857A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Etiqueta de área sutil: punto + nombre.
class EtiquetaArea extends StatelessWidget {
  const EtiquetaArea({required this.area, super.key});
  final String? area;

  @override
  Widget build(BuildContext context) {
    if (area == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final c = areaColor(area);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(area!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}

/// Pequeño "eyebrow" en mayúsculas (mismo lenguaje que Calendario/Mi Vida).
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.texto, {super.key});
  final String texto;
  @override
  Widget build(BuildContext context) {
    return Text(texto.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.oliveSoft));
  }
}

// ╭──────────────────────────────────────────────────────────────╮
// │ Responsive — breakpoints reales para todo el módulo            │
// │ Desktop ≥ 1000 · Tablet 700–999 · Mobile < 700                 │
// ╰──────────────────────────────────────────────────────────────╯

enum VitaBp { mobile, tablet, desktop }

VitaBp bpDe(double ancho) => ancho >= 1000
    ? VitaBp.desktop
    : (ancho >= 700 ? VitaBp.tablet : VitaBp.mobile);

/// Columnas de la cartera de proyectos según ancho.
int colsCartera(double ancho) =>
    ancho >= 1000 ? 3 : (ancho >= 700 ? 2 : 1);

/// Padding horizontal del contenido según breakpoint.
double padLateral(VitaBp bp) => switch (bp) {
      VitaBp.desktop => 32,
      VitaBp.tablet => 24,
      VitaBp.mobile => 16,
    };

/// Ancho máximo del lienzo (evita líneas larguísimas en monitores enormes,
/// pero mantiene un lienzo amplio, no una columna estrecha).
const double kMaxLienzo = 1400;

/// Rejilla fluida sin dependencias: reparte [hijos] en [columnas] usando Wrap,
/// calculando el ancho de cada celda a partir del ancho disponible.
class RejillaFluida extends StatelessWidget {
  const RejillaFluida({
    required this.columnas,
    required this.hijos,
    this.espacio = 16,
    super.key,
  });

  final int columnas;
  final List<Widget> hijos;
  final double espacio;

  @override
  Widget build(BuildContext context) {
    if (hijos.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        final cols = columnas < 1 ? 1 : columnas;
        final ancho = c.maxWidth;
        final celda =
            cols == 1 ? ancho : (ancho - espacio * (cols - 1)) / cols;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final h in hijos) SizedBox(width: celda, child: h),
          ],
        );
      },
    );
  }
}
