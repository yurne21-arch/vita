import 'package:flutter/material.dart';

/// Tokens de color de VITA. Estética premium, minimalista, calmada.
/// Paleta "Lavanda serena": página lila muy clara, acento malva.
abstract class AppColors {
  const AppColors._();

  // Acento de marca — malva sereno. (Histórico: se llamaba "olive"/verde;
  // el nombre cambió a `accent` al adoptar la paleta lavanda.)
  static const Color accent = Color(0xFF6E5E96);
  static const Color accentDeep = Color(0xFF564A78);
  static const Color accentSoft = Color(0xFF857AAB); // decorativo / iconos

  // Modo claro (lavanda serena)
  static const Color lightBg = Color(0xFFF5F3FA); // página lila muy claro
  static const Color lightSurface = Color(0xFFFFFFFF); // tarjetas blancas
  static const Color lightInk = Color(0xFF26232B); // texto principal
  static const Color lightMuted = Color(0xFF6E6A78); // texto secundario
  static const Color lightHairline = Color(0xFFE4DEF0); // líneas suaves

  // Modo oscuro (lavanda nocturna; coherente por si se usa)
  static const Color darkBg = Color(0xFF17151C);
  static const Color darkSurface = Color(0xFF211E29);
  static const Color darkInk = Color(0xFFEBE8F0);
  static const Color darkMuted = Color(0xFF9E99AC);
  static const Color darkHairline = Color(0xFF2E2A38);

  // Estados (apagados, legibles sobre fondo claro)
  static const Color success = Color(0xFF4E7A63);
  static const Color warning = Color(0xFFB7860B);
  static const Color danger = Color(0xFFB5563F);
  static const Color info = Color(0xFF4A6B8A);
}
