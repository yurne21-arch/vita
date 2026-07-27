import 'package:flutter/material.dart';

/// Tokens de color de VITA (Design System v2). Base cálida y luminosa (marfil,
/// no crema amarillo, no gris, no negro), marca **jade mineral** y una familia
/// de acentos por área. Ver docs/diseno/VITA_Design_System_v2.md.
///
/// Contraste AA verificado en textos. Los nombres públicos se conservan para que
/// toda la app herede la nueva identidad vía los tokens.
abstract class AppColors {
  const AppColors._();

  // Marca — jade mineral.
  static const Color accent = Color(0xFF17A088);
  static const Color accentDeep = Color(0xFF0E7C68); // activo/hover · texto AA
  static const Color accentSoft = Color(0xFF7ECBBB); // decorativo / iconos
  static const Color brandWash = Color(0xFFE7F4F0); // fondo apenas tintado

  // Modo claro — marfil cálido luminoso + tintas cálidas.
  static const Color lightBg =
      Color(0xFFFBFAF7); // fondo principal (marfil cálido)
  static const Color lightPanel = Color(0xFFFFFFFF); // tarjetas / paneles
  static const Color lightSurface = Color(0xFFFFFFFF); // superficie elevada
  static const Color lightSunken = Color(0xFFF4F1EA); // rellenos (inputs/chips)
  static const Color lightInk = Color(0xFF2A251F); // texto principal (cálido)
  static const Color lightMuted = Color(0xFF7A7164); // texto secundario (AA)
  static const Color lightHairline =
      Color(0xFFECE7DE); // líneas suaves (cálidas)

  // Modo oscuro (opcional, se afina en fase posterior; no obligatorio).
  static const Color darkBg = Color(0xFF17151C);
  static const Color darkSurface = Color(0xFF211E29);
  static const Color darkInk = Color(0xFFEBE8F0);
  static const Color darkMuted = Color(0xFF9E99AC);
  static const Color darkHairline = Color(0xFF2E2A38);

  // Estados semánticos (separados del acento; legibles sobre claro).
  static const Color success = Color(0xFF1E9E76);
  static const Color warning = Color(0xFF8A6A12);
  static const Color danger = Color(0xFFC0502F);
  static const Color info = Color(0xFF2C6EA6);

  // ── Acentos por área (base · wash · deep) ──────────────────────────
  // Cada uno: `base` (acento/línea/icono), `wash` (fondo apenas tintado),
  // `deep` (texto/estado sobre claro, AA). Ver mapa de módulos en el doc.

  static const Color coral = Color(0xFFF4785C); // Comida
  static const Color coralWash = Color(0xFFFBEAE2);
  static const Color coralDeep = Color(0xFFC0502F);

  static const Color sky = Color(0xFF3E86C4); // Calendario / trabajo
  static const Color skyWash = Color(0xFFE8F0F8);
  static const Color skyDeep = Color(0xFF2C6EA6);

  static const Color lavender = Color(0xFF9B84D9); // Mi Mes / reflexión
  static const Color lavenderWash = Color(0xFFF0EBFA);
  static const Color lavenderDeep = Color(0xFF6E55B0);

  static const Color gold = Color(0xFFC8992F); // Finanzas / logros
  static const Color goldWash = Color(0xFFF6EFDC);
  static const Color goldDeep = Color(0xFF8A6A12);

  static const Color petrol = Color(0xFF2A7B8C); // Proyectos
  static const Color petrolWash = Color(0xFFE7F1F3);
  static const Color petrolDeep = Color(0xFF1F5E6C);

  static const Color terracotta = Color(0xFFC56A4E); // Hogar / alertas suaves
  static const Color terracottaWash = Color(0xFFF8E9E2);
  static const Color terracottaDeep = Color(0xFFA9503A);
}
