import 'package:flutter/widgets.dart';

import 'vita_color.dart';

/// Escala tipográfica nombrada de VITA.
///
/// IMPORTANTE: por ahora NO se usa tipografía externa (para no agregar
/// dependencias ni cargas). Se usa la fuente del sistema. La estructura ya está
/// lista: el día que queramos Inter o SF, se cambia [fontFamily] en un solo
/// lugar y toda la app la adopta.
abstract class VitaType {
  const VitaType._();

  /// null = fuente del sistema. Cambiar aquí (y registrar el asset) para
  /// activar Inter/SF en el futuro.
  static const String? fontFamily = null;

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: VitaColor.ink,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.33,
    fontWeight: FontWeight.w700,
    color: VitaColor.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: VitaColor.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: VitaColor.ink,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
    color: VitaColor.inkMuted,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: VitaColor.inkMuted,
  );
}
