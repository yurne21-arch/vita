import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Etiqueta guía ("eyebrow") de VITA: orientación secundaria, en mayúsculas.
///
/// Único componente para todo el producto (antes existían 3 copias con colores
/// distintos). Usa el token `accent` para no regresar ningún contraste; el
/// color AA definitivo se fija con la migración de tema (Documento 6), aún
/// pendiente. No inflar tamaño ni poner cajas detrás: presencia secundaria.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1,
        fontWeight: FontWeight.w700,
        color: AppColors.accent,
      ),
    );
  }
}
