import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/finanzas_repository.dart';
import '../domain/finanzas.dart';

/// Mes visible en Finanzas (primer día del mes). Lo fija la pantalla.
final mesFinanzasProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, 1);
});

/// Movimientos del mes visible.
final movimientosProvider = FutureProvider<List<Movimiento>>((ref) {
  ref.watch(usuarioActualProvider);
  final mes = ref.watch(mesFinanzasProvider);
  return ref.watch(finanzasRepositoryProvider).movimientosDelMes(mes);
});

/// Resumen agregado del mes visible.
final resumenMesProvider = FutureProvider<ResumenMes>((ref) {
  ref.watch(usuarioActualProvider);
  final mes = ref.watch(mesFinanzasProvider);
  return ref.watch(finanzasRepositoryProvider).resumenDelMes(mes);
});

final presupuestosProvider = FutureProvider<List<Presupuesto>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(finanzasRepositoryProvider).presupuestos();
});

final deudasProvider = FutureProvider<List<Deuda>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(finanzasRepositoryProvider).deudas();
});

/// Acciones de Finanzas. Tras cada cambio, invalida lo que corresponda.
class FinanzasAcciones {
  FinanzasAcciones(this._ref);
  final Ref _ref;
  FinanzasRepository get _repo => _ref.read(finanzasRepositoryProvider);

  void _refrescarMovimientos() {
    _ref.invalidate(movimientosProvider);
    _ref.invalidate(resumenMesProvider);
  }

  Future<void> crearMovimiento({
    required String tipo,
    required double monto,
    required String categoria,
    required String ambito,
    required DateTime fecha,
    String? nota,
  }) async {
    await _repo.crearMovimiento(
      tipo: tipo,
      monto: monto,
      categoria: categoria,
      ambito: ambito,
      fecha: fecha,
      nota: nota,
    );
    _refrescarMovimientos();
  }

  Future<void> editarMovimiento(
    String id, {
    required double monto,
    required String categoria,
    required String ambito,
    required DateTime fecha,
    String? nota,
  }) async {
    await _repo.editarMovimiento(
      id,
      monto: monto,
      categoria: categoria,
      ambito: ambito,
      fecha: fecha,
      nota: nota,
    );
    _refrescarMovimientos();
  }

  Future<void> eliminarMovimiento(String id) async {
    await _repo.eliminarMovimiento(id);
    _refrescarMovimientos();
  }

  Future<void> fijarPresupuesto(String categoria, double montoMensual) async {
    await _repo.fijarPresupuesto(categoria, montoMensual);
    _ref.invalidate(presupuestosProvider);
  }

  Future<void> eliminarPresupuesto(String id) async {
    await _repo.eliminarPresupuesto(id);
    _ref.invalidate(presupuestosProvider);
  }

  Future<void> crearDeuda({
    required String direccion,
    required String persona,
    required double monto,
    required DateTime fecha,
    String? descripcion,
  }) async {
    await _repo.crearDeuda(
      direccion: direccion,
      persona: persona,
      monto: monto,
      fecha: fecha,
      descripcion: descripcion,
    );
    _ref.invalidate(deudasProvider);
  }

  Future<void> marcarDeuda(String id, {required bool saldada}) async {
    await _repo.marcarDeuda(id, saldada: saldada);
    _ref.invalidate(deudasProvider);
  }

  Future<void> eliminarDeuda(String id) async {
    await _repo.eliminarDeuda(id);
    _ref.invalidate(deudasProvider);
  }
}

final finanzasAccionesProvider =
    Provider<FinanzasAcciones>((ref) => FinanzasAcciones(ref));
