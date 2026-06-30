import 'package:flutter/widgets.dart';

/// Color de VITA en capas. Fondo oscuro + acento oliva, sobrio y premium.
/// Basado en la identidad actual, formalizado en niveles de profundidad para
/// poder dar relieve SIN bordes (los bordes hacen que se vea "hecho en Flutter").
///
/// Nota: aprobado como base; se puede afinar más adelante si visualmente se
/// siente demasiado oscuro o plano.
abstract class VitaColor {
  const VitaColor._();

  // ── Capas de fondo (profundidad por color, no por bordes) ──
  static const Color bg = Color(0xFF14130F);
  static const Color surface = Color(0xFF1E1D19);
  static const Color surfaceElevated = Color(0xFF26241F);

  // ── Tinta (texto) en 3 niveles ──
  static const Color ink = Color(0xFFECEAE3);
  static const Color inkMuted = Color(0xFF9C988C);
  static const Color inkFaint = Color(0xFF6E6B61);

  // ── Acento oliva ──
  static const Color accent = Color(0xFF6B7A4F);
  static const Color accentDark = Color(0xFF4F5B3A);
  static const Color accentSoft = Color(0xFF8A9869);

  // ── Línea sutil (solo cuando sea imprescindible) ──
  static const Color hairline = Color(0xFF2C2A24);

  // ── Estados (apagados, nunca saturados) ──
  static const Color success = Color(0xFF4E7A51);
  static const Color warning = Color(0xFFC9A227);
  static const Color danger = Color(0xFFB5563F);
  static const Color info = Color(0xFF4A6B8A);
}
