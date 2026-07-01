import 'package:flutter/widgets.dart';

/// Movimiento de VITA. Elegante y discreto. SIEMPRE bajo 300 ms, con salida
/// suave. Nunca animación de adorno.
abstract class VitaMotion {
  const VitaMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 280);

  /// Curva estándar de entrada/salida.
  static const Curve curve = Curves.easeOutCubic;
  static const Curve curveIn = Curves.easeInCubic;
}
