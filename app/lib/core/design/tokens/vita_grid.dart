import 'vita_breakpoints.dart';

/// Rejilla fluida de VITA. La misma cuadrícula pasa de 3 → 2 → 1 columnas
/// automáticamente según el ancho, sin pantallas separadas por dispositivo.
abstract class VitaGrid {
  const VitaGrid._();

  /// Separación entre columnas / tarjetas.
  static const double gutter = 24;

  /// Ancho máximo de lectura en pantallas grandes (evita estirones feos).
  static const double maxContentWidth = 1200;

  /// Columnas recomendadas según el ancho disponible.
  static int columnsFor(double width) => switch (VitaBreakpoints.of(width)) {
        VitaBreakpoint.desktop => 3,
        VitaBreakpoint.tablet => 2,
        VitaBreakpoint.mobile => 1,
      };
}
