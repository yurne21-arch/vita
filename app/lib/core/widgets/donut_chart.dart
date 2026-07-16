import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Un segmento del gráfico de dona.
class DonutSegmento {
  const DonutSegmento(this.label, this.valor, this.color);
  final String label;
  final double valor;
  final Color color;
}

/// Gráfico de dona (anillo) con leyenda. Dibujado a mano: sin dependencias.
/// Reutilizable (Finanzas hoy, Salud a futuro).
class DonutChart extends StatelessWidget {
  const DonutChart({
    required this.segmentos,
    this.tamano = 160,
    this.grosor = 26,
    this.centroTitulo,
    this.centroValor,
    super.key,
  });

  final List<DonutSegmento> segmentos;
  final double tamano;
  final double grosor;
  final String? centroTitulo;
  final String? centroValor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = segmentos.fold<double>(0, (a, s) => a + s.valor);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: tamano,
          height: tamano,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(tamano, tamano),
                painter: _DonutPainter(
                  segmentos: segmentos,
                  grosor: grosor,
                  pista: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (centroValor != null)
                    Text(centroValor!,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  if (centroTitulo != null)
                    Text(centroTitulo!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in segmentos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall),
                      ),
                      Text(
                        total <= 0
                            ? '—'
                            : '${(s.valor / total * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segmentos,
    required this.grosor,
    required this.pista,
  });

  final List<DonutSegmento> segmentos;
  final double grosor;
  final Color pista;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = (math.min(size.width, size.height) - grosor) / 2;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final total = segmentos.fold<double>(0, (a, s) => a + s.valor);

    // Pista de fondo.
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..color = pista,
    );
    if (total <= 0) return;

    var inicio = -math.pi / 2; // arranca arriba
    const separacion = 0.02; // pequeño hueco entre segmentos
    for (final s in segmentos) {
      final barrido = (s.valor / total) * (2 * math.pi) - separacion;
      if (barrido <= 0) continue;
      canvas.drawArc(
        rect,
        inicio + separacion / 2,
        barrido,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = grosor
          ..strokeCap = StrokeCap.round
          ..color = s.color,
      );
      inicio += (s.valor / total) * (2 * math.pi);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segmentos != segmentos || old.grosor != grosor;
}
