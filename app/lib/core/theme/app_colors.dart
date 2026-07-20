import 'package:flutter/material.dart';

/// Tokens de color de VITA. Estética premium, minimalista, calmada.
/// Paleta "Lavanda serena": página lila muy clara, acento malva.
abstract class AppColors {
  const AppColors._();

  // Acento de marca — verde salvia, sereno y unisex.
  static const Color accent = Color(0xFF4E7A63);
  static const Color accentDeep = Color(0xFF3C614E);
  static const Color accentSoft = Color(0xFF7FA790); // decorativo / iconos

  // Modo claro — crema mantequilla cálido + verde salvia (acogedor, personal).
  static const Color lightBg = Color(0xFFFBF4E4); // crema cálido con toque amarillo
  static const Color lightPanel = Color(0xFFFFFDF7); // tarjetas: crema muy claro
  static const Color lightSurface = Color(0xFFFFFFFF); // inputs / chips
  static const Color lightInk = Color(0xFF2B2620); // texto principal (cálido)
  static const Color lightMuted = Color(0xFF756D5C); // texto secundario
  static const Color lightHairline = Color(0xFFEDE2CC); // líneas suaves (arena)

  // Modo oscuro (lavanda nocturna; coherente por si se usa)
  static const Color darkBg = Color(0xFF17151C);
  static const Color darkSurface = Color(0xFF211E29);
  static const Color darkInk = Color(0xFFEBE8F0);
  static const Color darkMuted = Color(0xFF9E99AC);
  static const Color darkHairline = Color(0xFF2E2A38);

  // Estados (apagados, legibles sobre fondo claro)
  static const Color success = Color(0xFF3E8E5A); // verde confirmación (distinto del acento)
  static const Color warning = Color(0xFFB7860B);
  static const Color danger = Color(0xFFB5563F);
  static const Color info = Color(0xFF4A6B8A);
}
