import 'package:flutter_test/flutter_test.dart';
import 'package:vita/features/alimentacion/domain/biblioteca_seed.dart';
import 'package:vita/features/alimentacion/domain/motor.dart';

void main() {
  final biblioteca = bibliotecaAprobada();
  final perfiles = perfilesProvisionales();
  // Un lunes cualquiera.
  final inicio = DateTime(2026, 7, 20);
  final plan = const MotorNutricional().generar(
    perfiles: perfiles,
    biblioteca: biblioteca,
    inicioSemana: inicio,
  );

  test('genera 7 días con comidas', () {
    expect(plan.dias.length, 7);
    for (final d in plan.dias) {
      expect(d.comidas, isNotEmpty);
    }
  });

  test('cada día cierra: kcal en ±5% y proteína ≥ meta, por persona', () {
    for (final perfil in perfiles) {
      final meta = perfil.kcalObjetivo!;
      final tol = meta * perfil.kcalToleranciaPct / 100;
      for (final d in plan.dias) {
        final t = d.totales[perfil.nombre]!;
        expect((t.kcal - meta).abs() <= tol, isTrue,
            reason:
                '${perfil.nombre} ${d.nombre}: ${t.kcal.round()} kcal fuera de ±$tol de $meta');
        expect(t.prot >= perfil.protObjetivoG! * 0.97, isTrue,
            reason:
                '${perfil.nombre} ${d.nombre}: proteína ${t.prot.round()} < ${perfil.protObjetivoG}');
      }
    }
  });

  test('ningún ensamble se repite dos días seguidos', () {
    for (var i = 1; i < plan.dias.length; i++) {
      final ayer = plan.dias[i - 1].comidas.map((c) => c.ensamble.id).toSet();
      for (final c in plan.dias[i].comidas) {
        expect(ayer.contains(c.ensamble.id), isFalse,
            reason: '${c.ensamble.nombre} repetido en días seguidos');
      }
    }
  });

  test('produccciones base con terminaciones y compra estimada', () {
    expect(plan.produccionesBase, greaterThan(0));
    final pollo =
        plan.producciones.where((p) => p.base.nombre == 'Pollo cocido');
    expect(pollo, isNotEmpty);
    expect(pollo.first.crudoG, greaterThan(pollo.first.cocidoG)); // rinde <100%
    expect(pollo.first.terminaciones.length, greaterThanOrEqualTo(2));
  });

  test('lista de compras separa principal de reposición de frescos', () {
    expect(plan.compras.principal, isNotEmpty);
    expect(plan.compras.reposicion, isNotEmpty);
  });
}
