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

final tarjetasProvider = FutureProvider<List<Tarjeta>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(finanzasRepositoryProvider).tarjetas();
});

final creditosProvider = FutureProvider<List<Credito>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(finanzasRepositoryProvider).creditos();
});

final metasProvider = FutureProvider<List<Meta>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(finanzasRepositoryProvider).metas();
});

/// Balance del reparto compartido (Tricount), acumulado sobre todo el historial.
final balanceCompartidoProvider = FutureProvider<BalanceCompartido>((ref) {
  ref.watch(usuarioActualProvider);
  ref.watch(movimientosProvider); // se recalcula al cambiar movimientos
  return ref.watch(finanzasRepositoryProvider).balanceCompartido();
});

final cuentasProvider = FutureProvider<List<Cuenta>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(finanzasRepositoryProvider).cuentas();
});

/// Resumen de pagos por crédito (cuántas cuotas y total), para todos.
final resumenPagosProvider =
    FutureProvider<Map<String, ResumenCredito>>((ref) {
  ref.watch(usuarioActualProvider);
  ref.watch(creditosProvider);
  return ref.watch(finanzasRepositoryProvider).resumenPagosPorCredito();
});

/// Pagos de un crédito puntual (para ver el detalle).
final pagosDeCreditoProvider =
    FutureProvider.family<List<PagoCredito>, String>((ref, loanId) {
  ref.watch(usuarioActualProvider);
  ref.watch(resumenPagosProvider);
  return ref.watch(finanzasRepositoryProvider).pagosDeCredito(loanId);
});

/// Nota pendiente heredada del mes anterior al visible.
final pendienteMesAnteriorProvider = FutureProvider<String?>((ref) {
  ref.watch(usuarioActualProvider);
  final mes = ref.watch(mesFinanzasProvider);
  return ref.watch(finanzasRepositoryProvider).pendienteMesAnterior(mes);
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
    String? quien,
    bool compartido = false,
  }) async {
    await _repo.crearMovimiento(
      tipo: tipo,
      monto: monto,
      categoria: categoria,
      ambito: ambito,
      fecha: fecha,
      nota: nota,
      quien: quien,
      compartido: compartido,
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
    String? quien,
    bool compartido = false,
  }) async {
    await _repo.editarMovimiento(
      id,
      monto: monto,
      categoria: categoria,
      ambito: ambito,
      fecha: fecha,
      nota: nota,
      quien: quien,
      compartido: compartido,
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

  Future<void> editarDeuda(
    String id, {
    required String direccion,
    required String persona,
    required double monto,
    String? descripcion,
  }) async {
    await _repo.editarDeuda(
      id,
      direccion: direccion,
      persona: persona,
      monto: monto,
      descripcion: descripcion,
    );
    _ref.invalidate(deudasProvider);
  }

  // ── Tarjetas ──
  Future<void> guardarTarjeta({
    String? id,
    required String nombre,
    String? titular,
    required double cupo,
    required double saldoDeuda,
    required double cuotaMes,
    int? diaCierre,
    int? diaPago,
  }) async {
    await _repo.guardarTarjeta(
      id: id,
      nombre: nombre,
      titular: titular,
      cupo: cupo,
      saldoDeuda: saldoDeuda,
      cuotaMes: cuotaMes,
      diaCierre: diaCierre,
      diaPago: diaPago,
    );
    _ref.invalidate(tarjetasProvider);
  }

  Future<void> eliminarTarjeta(String id) async {
    await _repo.eliminarTarjeta(id);
    _ref.invalidate(tarjetasProvider);
  }

  // ── Créditos ──
  Future<void> guardarCredito({
    String? id,
    required String nombre,
    required double cuotaMensual,
    required double montoTotal,
    String? fin,
    int? progreso,
    bool saldada = false,
  }) async {
    await _repo.guardarCredito(
      id: id,
      nombre: nombre,
      cuotaMensual: cuotaMensual,
      montoTotal: montoTotal,
      fin: fin,
      progreso: progreso,
      saldada: saldada,
    );
    _ref.invalidate(creditosProvider);
  }

  Future<void> eliminarCredito(String id) async {
    await _repo.eliminarCredito(id);
    _ref.invalidate(creditosProvider);
  }

  // ── Metas ──
  Future<void> guardarMeta({
    String? id,
    required String label,
    String? emoji,
    required double metaMonto,
    double ahorrado = 0,
  }) async {
    await _repo.guardarMeta(
      id: id,
      label: label,
      emoji: emoji,
      metaMonto: metaMonto,
      ahorrado: ahorrado,
    );
    _ref.invalidate(metasProvider);
  }

  Future<void> eliminarMeta(String id) async {
    await _repo.eliminarMeta(id);
    _ref.invalidate(metasProvider);
  }

  Future<void> marcarDeuda(String id, {required bool saldada}) async {
    await _repo.marcarDeuda(id, saldada: saldada);
    _ref.invalidate(deudasProvider);
  }

  Future<void> eliminarDeuda(String id) async {
    await _repo.eliminarDeuda(id);
    _ref.invalidate(deudasProvider);
  }

  Future<void> abonarMeta(String goalId,
      {required double monto, required DateTime fecha}) async {
    await _repo.abonarMeta(goalId, monto: monto, fecha: fecha);
    _ref.invalidate(metasProvider);
  }

  // ── Cuentas ──
  Future<void> guardarCuenta({
    String? id,
    required String nombre,
    String? titular,
    required double saldo,
  }) async {
    await _repo.guardarCuenta(
        id: id, nombre: nombre, titular: titular, saldo: saldo);
    _ref.invalidate(cuentasProvider);
  }

  Future<void> eliminarCuenta(String id) async {
    await _repo.eliminarCuenta(id);
    _ref.invalidate(cuentasProvider);
  }

  // ── Pagos de créditos ──
  Future<void> registrarPagoCredito(String loanId,
      {required double monto, required DateTime fecha, String? nota}) async {
    await _repo.registrarPagoCredito(loanId,
        monto: monto, fecha: fecha, nota: nota);
    _ref.invalidate(resumenPagosProvider);
    _ref.invalidate(pagosDeCreditoProvider(loanId));
  }

  Future<void> eliminarPagoCredito(String id, String loanId) async {
    await _repo.eliminarPagoCredito(id);
    _ref.invalidate(resumenPagosProvider);
    _ref.invalidate(pagosDeCreditoProvider(loanId));
  }

  // ── Cierre de mes ──
  Future<void> cerrarMes(DateTime mes,
      {required Map<String, dynamic> resumen, String? pendiente}) async {
    await _repo.cerrarMes(mes, resumen: resumen, pendiente: pendiente);
    _ref.invalidate(pendienteMesAnteriorProvider);
  }

  // ── Saldar reparto compartido ──
  Future<void> saldarCompartido() async {
    await _repo.saldarCompartido();
    _ref.invalidate(balanceCompartidoProvider);
  }
}

final finanzasAccionesProvider =
    Provider<FinanzasAcciones>((ref) => FinanzasAcciones(ref));
