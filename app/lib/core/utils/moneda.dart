/// Formateo de dinero, sereno y legible. Sin decimales para CLP (el uso real
/// de VITA); con separador de miles por puntos. Ej.: 1234567 → "$1.234.567".
///
/// Vive en core porque el dinero aparece en Finanzas y, a futuro, en Mi Vida.
String formatoMoneda(double monto, {String simbolo = '\$'}) {
  final entero = monto.round().abs();
  final s = entero.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  final signo = monto < 0 ? '-' : '';
  return '$signo$simbolo${buf.toString()}';
}
