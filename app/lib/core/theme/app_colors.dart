import 'package:flutter/material.dart';

/// Tokens de color de VITA. Estética premium, minimalista, calmada.
/// Acento verde oliva; nunca colores saturados.
abstract class AppColors {
  const AppColors._();

  // Acento — verde oliva elegante
  static const Color olive = Color(0xFF6B7A4F);
  static const Color oliveDark = Color(0xFF4F5B3A);
  static const Color oliveSoft = Color(0xFF8A9869);

  // Modo claro
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F2);
  static const Color lightInk = Color(0xFF1F1E1A);
  static const Color lightMuted = Color(0xFF6E6B61);
  static const Color lightHairline = Color(0xFFE6E4DD);

  // Modo oscuro
  static const Color darkBg = Color(0xFF14130F);
  static const Color darkSurface = Color(0xFF1E1D19);
  static const Color darkInk = Color(0xFFECEAE3);
  static const Color darkMuted = Color(0xFF9C988C);
  static const Color darkHairline = Color(0xFF2C2A24);

  // Estados (apagados, no saturados)
  static const Color success = Color(0xFF4E7A51);
  static const Color warning = Color(0xFFC9A227);
  static const Color danger = Color(0xFFB5563F);
  static const Color info = Color(0xFF4A6B8A);
}
