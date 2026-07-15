import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';
import '../domain/finanzas.dart';

/// Error de dominio con un mensaje que se puede mostrar tal cual.
class FinanzasException implements Exception {
  const FinanzasException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FinanzasRepository {
  FinanzasRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  String _userId() {
    final user = _c.auth.currentUser;
    if (user == null) {
      throw const FinanzasException('Tu sesión expiró. Vuelve a entrar.');
    }
    return user.id;
  }

  String _fechaSolo(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<T> _guard<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on FinanzasException {
      rethrow;
    } on PostgrestException catch (e) {
      throw FinanzasException(e.message);
    } catch (_) {
      throw const FinanzasException(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }

  // ── Movimientos ──────────────────────────────────────────────

  /// Movimientos del mes que contiene [mes] (por defecto, el mes actual).
  Future<List<Movimiento>> movimientosDelMes(DateTime mes) => _guard(() async {
        final userId = _userId();
        final desde = DateTime(mes.year, mes.month, 1);
        final hasta = DateTime(mes.year, mes.month + 1, 1);
        final rows = await _c
            .from('finance_transactions')
            .select('id, tipo, monto, categoria, ambito, nota, fecha')
            .eq('user_id', userId)
            .gte('fecha', _fechaSolo(desde))
            .lt('fecha', _fechaSolo(hasta))
            .order('fecha', ascending: false)
            .order('created_at', ascending: false);
        return (rows as List)
            .map((m) => Movimiento.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<void> crearMovimiento({
    required String tipo,
    required double monto,
    required String categoria,
    required String ambito,
    required DateTime fecha,
    String? nota,
    String? quien,
    bool compartido = false,
  }) =>
      _guard(() async {
        final userId = _userId();
        if (monto <= 0) {
          throw const FinanzasException('El monto debe ser mayor que cero.');
        }
        if (categoria.trim().isEmpty) {
          throw const FinanzasException('Elige una categoría.');
        }
        await _c.from('finance_transactions').insert({
          'user_id': userId,
          'tipo': tipo,
          'monto': monto,
          'categoria': categoria.trim(),
          'ambito': ambito,
          'nota': (nota == null || nota.trim().isEmpty) ? null : nota.trim(),
          'quien': quien,
          'compartido': compartido,
          'fecha': _fechaSolo(fecha),
        });
      });

  Future<void> editarMovimiento(
    String id, {
    required double monto,
    required String categoria,
    required String ambito,
    required DateTime fecha,
    String? nota,
    String? quien,
    bool compartido = false,
  }) =>
      _guard(() async {
        if (monto <= 0) {
          throw const FinanzasException('El monto debe ser mayor que cero.');
        }
        await _c.from('finance_transactions').update({
          'monto': monto,
          'categoria': categoria.trim(),
          'ambito': ambito,
          'nota': (nota == null || nota.trim().isEmpty) ? null : nota.trim(),
          'quien': quien,
          'compartido': compartido,
          'fecha': _fechaSolo(fecha),
        }).eq('id', id);
      });

  Future<void> eliminarMovimiento(String id) => _guard(() async {
        await _c.from('finance_transactions').delete().eq('id', id);
      });

  /// Primer día del mes más reciente con movimientos (o null si no hay).
  /// Sirve para abrir Finanzas donde están los datos, no en un mes vacío.
  Future<DateTime?> ultimoMesConDatos() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('finance_transactions')
            .select('fecha')
            .eq('user_id', userId)
            .order('fecha', ascending: false)
            .limit(1);
        final l = rows as List;
        if (l.isEmpty) return null;
        final f = DateTime.parse(l.first['fecha'] as String);
        return DateTime(f.year, f.month, 1);
      });

  /// Resumen agregado del mes (gastos, ingresos, gasto por categoría).
  Future<ResumenMes> resumenDelMes(DateTime mes) async {
    final movimientos = await movimientosDelMes(mes);
    var gastos = 0.0;
    var ingresos = 0.0;
    final porCategoria = <String, double>{};
    for (final m in movimientos) {
      if (m.esGasto) {
        gastos += m.monto;
        porCategoria.update(m.categoria, (v) => v + m.monto,
            ifAbsent: () => m.monto);
      } else {
        ingresos += m.monto;
      }
    }
    return ResumenMes(
        gastos: gastos, ingresos: ingresos, porCategoria: porCategoria);
  }

  // ── Presupuestos ─────────────────────────────────────────────

  Future<List<Presupuesto>> presupuestos() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('finance_budgets')
            .select('id, categoria, monto_mensual')
            .eq('user_id', userId)
            .order('categoria');
        return (rows as List)
            .map((m) => Presupuesto.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  /// Fija (o actualiza) el presupuesto mensual de una categoría.
  Future<void> fijarPresupuesto(String categoria, double montoMensual) =>
      _guard(() async {
        final userId = _userId();
        if (montoMensual < 0) {
          throw const FinanzasException('El presupuesto no puede ser negativo.');
        }
        await _c.from('finance_budgets').upsert({
          'user_id': userId,
          'categoria': categoria.trim(),
          'monto_mensual': montoMensual,
        }, onConflict: 'user_id,categoria');
      });

  Future<void> eliminarPresupuesto(String id) => _guard(() async {
        await _c.from('finance_budgets').delete().eq('id', id);
      });

  // ── Deudas ───────────────────────────────────────────────────

  Future<List<Deuda>> deudas() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('finance_debts')
            .select('id, direccion, persona, monto, descripcion, saldada, fecha')
            .eq('user_id', userId)
            .order('saldada')
            .order('fecha', ascending: false);
        return (rows as List)
            .map((m) => Deuda.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<void> crearDeuda({
    required String direccion,
    required String persona,
    required double monto,
    required DateTime fecha,
    String? descripcion,
  }) =>
      _guard(() async {
        final userId = _userId();
        if (monto <= 0) {
          throw const FinanzasException('El monto debe ser mayor que cero.');
        }
        if (persona.trim().isEmpty) {
          throw const FinanzasException('¿Con quién es la deuda?');
        }
        await _c.from('finance_debts').insert({
          'user_id': userId,
          'direccion': direccion,
          'persona': persona.trim(),
          'monto': monto,
          'descripcion': (descripcion == null || descripcion.trim().isEmpty)
              ? null
              : descripcion.trim(),
          'fecha': _fechaSolo(fecha),
        });
      });

  Future<void> marcarDeuda(String id, {required bool saldada}) =>
      _guard(() async {
        await _c
            .from('finance_debts')
            .update({'saldada': saldada}).eq('id', id);
      });

  Future<void> eliminarDeuda(String id) => _guard(() async {
        await _c.from('finance_debts').delete().eq('id', id);
      });

  // ── Tarjetas ─────────────────────────────────────────────────

  Future<List<Tarjeta>> tarjetas() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('finance_cards')
            .select(
                'id, nombre, titular, cupo, saldo_deuda, cuota_mes, dia_cierre, dia_pago')
            .eq('user_id', userId)
            .order('orden');
        return (rows as List)
            .map((m) => Tarjeta.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  // ── Créditos / deudas estructuradas ──────────────────────────

  Future<List<Credito>> creditos() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('finance_loans')
            .select(
                'id, nombre, cuota_mensual, monto_total, saldada, fin, progreso')
            .eq('user_id', userId)
            .order('orden');
        return (rows as List)
            .map((m) => Credito.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  // ── Metas de ahorro ──────────────────────────────────────────

  Future<List<Meta>> metas() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('finance_goals')
            .select('id, label, emoji, meta_monto, ahorrado, cumplida')
            .eq('user_id', userId)
            .order('orden');
        return (rows as List)
            .map((m) => Meta.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  // ── Tricount: balance del reparto compartido ─────────────────

  /// Suma los gastos compartidos por [quien]. Base del "quién le debe a quién".
  /// Se calcula sobre todo el historial (no por mes): es un saldo acumulado.
  Future<BalanceCompartido> balanceCompartido() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('finance_transactions')
            .select('monto, quien')
            .eq('user_id', userId)
            .eq('tipo', 'gasto')
            .eq('compartido', true);
        var yurby = 0.0;
        var juan = 0.0;
        for (final r in (rows as List)) {
          final monto = (r['monto'] as num).toDouble();
          final quien = r['quien'] as String?;
          if (quien == 'Juan') {
            juan += monto;
          } else if (quien == 'Yurby') {
            yurby += monto;
          } else {
            // 'Ambos' o sin dato: se reparte por igual, no desequilibra.
            yurby += monto / 2;
            juan += monto / 2;
          }
        }
        return BalanceCompartido(puestoPorYurby: yurby, puestoPorJuan: juan);
      });
}

final finanzasRepositoryProvider = Provider<FinanzasRepository>(
  (ref) => FinanzasRepository(ref.read(supabaseServiceProvider)),
);
