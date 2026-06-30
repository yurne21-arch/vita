import 'package:flutter/widgets.dart';

/// Sistema responsive ÚNICO de VITA. Fuente de verdad de los puntos de quiebre.
/// Reemplaza (a futuro) las definiciones sueltas y contradictorias que hoy
/// viven dentro de cada módulo.
///
/// Móvil  : ancho < 600
/// Tablet : 600 .. 1023
/// Escritorio : >= 1024
enum VitaBreakpoint { mobile, tablet, desktop }

abstract class VitaBreakpoints {
  const VitaBreakpoints._();

  /// Umbrales en píxeles lógicos.
  static const double tablet = 600;
  static const double desktop = 1024;

  /// Resuelve el breakpoint a partir de un ancho.
  static VitaBreakpoint of(double width) {
    if (width >= desktop) return VitaBreakpoint.desktop;
    if (width >= tablet) return VitaBreakpoint.tablet;
    return VitaBreakpoint.mobile;
  }

  /// Atajo directo desde el contexto.
  static VitaBreakpoint ofContext(BuildContext context) =>
      of(MediaQuery.sizeOf(context).width);
}

/// Condiciones legibles: `bp.isDesktop`, `bp.isMobileOrTablet`, etc.
extension VitaBreakpointX on VitaBreakpoint {
  bool get isMobile => this == VitaBreakpoint.mobile;
  bool get isTablet => this == VitaBreakpoint.tablet;
  bool get isDesktop => this == VitaBreakpoint.desktop;
  bool get isMobileOrTablet => this != VitaBreakpoint.desktop;
}
