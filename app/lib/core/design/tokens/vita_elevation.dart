import 'package:flutter/widgets.dart';

import 'vita_color.dart';

/// Profundidad de VITA. La jerarquía de planos se logra con CAPAS DE COLOR,
/// no con sombras duras ni bordes. Las sombras se usan solo en elementos que
/// flotan de verdad (hojas inferiores, diálogos).
abstract class VitaElevation {
  const VitaElevation._();

  /// Color de superficie según el plano.
  static const Color level0 = VitaColor.bg; // fondo de pantalla
  static const Color level1 = VitaColor.surface; // tarjetas
  static const Color level2 = VitaColor.surfaceElevated; // hojas / diálogos

  /// Sombra muy sutil para elementos que flotan.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
