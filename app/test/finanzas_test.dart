import 'package:flutter_test/flutter_test.dart';
import 'package:vita/core/utils/moneda.dart';
import 'package:vita/features/finanzas/domain/finanzas.dart';

void main() {
  group('Formato de moneda', () {
    test('separa miles con puntos y sin decimales (CLP)', () {
      expect(formatoMoneda(1234567), '\$1.234.567');
      expect(formatoMoneda(1000), '\$1.000');
      expect(formatoMoneda(999), '\$999');
      expect(formatoMoneda(0), '\$0');
    });

    test('redondea y respeta el signo negativo', () {
      expect(formatoMoneda(1500.6), '\$1.501');
      expect(formatoMoneda(-2500), '-\$2.500');
    });
  });

  group('Movimiento', () {
    Movimiento mov(String tipo, double monto) => Movimiento(
          id: 'x',
          tipo: tipo,
          monto: monto,
          categoria: 'Comida',
          ambito: 'personal',
          fecha: DateTime(2026, 7, 1),
        );

    test('un gasto resta y un ingreso suma al balance', () {
      expect(mov('gasto', 100).signo, -100);
      expect(mov('ingreso', 100).signo, 100);
      expect(mov('gasto', 100).esGasto, isTrue);
      expect(mov('ingreso', 100).esIngreso, isTrue);
    });
  });

  group('ResumenMes', () {
    test('el balance es ingresos menos gastos', () {
      const r = ResumenMes(gastos: 300, ingresos: 500, porCategoria: {});
      expect(r.balance, 200);
    });

    test('el balance vacío es cero', () {
      expect(ResumenMes.vacio.balance, 0);
    });
  });
}
