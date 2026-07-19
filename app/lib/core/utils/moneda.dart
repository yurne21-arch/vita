import 'package:flutter/services.dart';

/// Formateo de dinero, sereno y legible. Sin decimales para CLP (el uso real
/// de VITA); con separador de miles por puntos. Ej.: 1234567 → "$1.234.567".
///
/// Vive en core porque el dinero aparece en Finanzas y, a futuro, en Mi Vida.
String formatoMoneda(double monto, {String simbolo = '\$'}) {
  final signo = monto < 0 ? '-' : '';
  return '$signo$simbolo${milesConPuntos(monto.round().abs())}';
}

/// Un entero con separador de miles por puntos. 1234567 → "1.234.567".
String milesConPuntos(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Convierte lo escrito en un campo de monto (con puntos) a número.
double? parseMonto(String texto) =>
    double.tryParse(texto.replaceAll('.', '').trim());

/// Formatea el campo de monto mientras se escribe: solo dígitos, con puntos de
/// miles. Así la usuaria ve "1.234.567" y no se equivoca con los ceros.
class MilesInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formateado = milesConPuntos(int.parse(digitos));
    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}
