import 'package:flutter/widgets.dart';

/// Radios de esquina consistentes en toda VITA.
abstract class VitaRadius {
  const VitaRadius._();

  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;

  /// Para píldoras / elementos totalmente redondeados.
  static const double full = 999;

  // Atajos listos para usar.
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));
}
