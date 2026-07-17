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
            .select(
                'id, tipo, monto, categoria, ambito, nota, fecha, quien, compartido, cuenta_id, tarjeta_id, loan_id')
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
    String? cuentaId,
    String? tarjetaId,
    String? loanId,
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
          'cuenta_id': cuentaId,
          'tarjeta_id': tarjetaId,
          'loan_id': loanId,
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
    String? cuentaId,
    String? tarjetaId,
    String? loanId,
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
          'cuenta_id': cuentaId,
          'tarjeta_id': tarjetaId,
          'loan_id': loanId,
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

  Future<void> editarDeuda(
    String id, {
    required String direccion,
    required String persona,
    required double monto,
    String? descripcion,
  }) =>
      _guard(() async {
        if (monto <= 0) {
          throw const FinanzasException('El monto debe ser mayor que cero.');
        }
        if (persona.trim().isEmpty) {
          throw const FinanzasException('¿Con quién es la deuda?');
        }
        await _c.from('finance_debts').update({
          'direccion': direccion,
          'persona': persona.trim(),
          'monto': monto,
          'descripcion': (descripcion == null || descripcion.trim().isEmpty)
              ? null
              : descripcion.trim(),
        }).eq('id', id);
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

  Future<void> guardarTarjeta({
    String? id,
    required String nombre,
    String? titular,
    required double cupo,
    required double saldoDeuda,
    required double cuotaMes,
    int? diaCierre,
    int? diaPago,
  }) =>
      _guard(() async {
        final userId = _userId();
        if (nombre.trim().isEmpty) {
          throw const FinanzasException('La tarjeta necesita un nombre.');
        }
        final datos = {
          'user_id': userId,
          'nombre': nombre.trim(),
          'titular': titular,
          'cupo': cupo,
          'saldo_deuda': saldoDeuda,
          'cuota_mes': cuotaMes,
          'dia_cierre': diaCierre,
          'dia_pago': diaPago,
        };
        if (id == null) {
          await _c.from('finance_cards').insert(datos);
        } else {
          await _c.from('finance_cards').update(datos).eq('id', id);
        }
      });

  Future<void> eliminarTarjeta(String id) => _guard(() async {
        await _c.from('finance_cards').delete().eq('id', id);
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

  Future<void> guardarCredito({
    String? id,
    required String nombre,
    required double cuotaMensual,
    required double montoTotal,
    String? fin,
    int? progreso,
    bool saldada = false,
  }) =>
      _guard(() async {
        final userId = _userId();
        if (nombre.trim().isEmpty) {
          throw const FinanzasException('El crédito necesita un nombre.');
        }
        final datos = {
          'user_id': userId,
          'nombre': nombre.trim(),
          'cuota_mensual': cuotaMensual,
          'monto_total': montoTotal,
          'fin': (fin == null || fin.trim().isEmpty) ? null : fin.trim(),
          'progreso': progreso,
          'saldada': saldada,
        };
        if (id == null) {
          await _c.from('finance_loans').insert(datos);
        } else {
          await _c.from('finance_loans').update(datos).eq('id', id);
        }
      });

  Future<void> eliminarCredito(String id) => _guard(() async {
        await _c.from('finance_loans').delete().eq('id', id);
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

  Future<void> guardarMeta({
    String? id,
    required String label,
    String? emoji,
    required double metaMonto,
    double ahorrado = 0,
  }) =>
      _guard(() async {
        final userId = _userId();
        if (label.trim().isEmpty) {
          throw const FinanzasException('La meta necesita un nombre.');
        }
        final datos = {
          'user_id': userId,
          'label': label.trim(),
          'emoji': (emoji == null || emoji.trim().isEmpty) ? null : emoji.trim(),
          'meta_monto': metaMonto,
          'ahorrado': ahorrado,
          'cumplida': metaMonto > 0 && ahorrado >= metaMonto,
        };
        if (id == null) {
          await _c.from('finance_goals').insert(datos);
        } else {
          await _c.from('finance_goals').update(datos).eq('id', id);
        }
      });

  Future<void> eliminarMeta(String id) => _guard(() async {
        await _c.from('finance_goals').delete().eq('id', id);
      });

  // ── Tricount: balance del reparto compartido ─────────────────

  /// Suma los gastos compartidos por [quien], solo los POSTERIORES a la última
  /// vez que se saldaron ("quedar a mano"). Base del "quién le debe a quién".
  Future<BalanceCompartido> balanceCompartido() => _guard(() async {
        final userId = _userId();

        // ¿Hasta qué fecha ya se pagaron entre ellos?
        final perfil = await _c
            .from('profiles')
            .select('tricount_saldado_hasta')
            .eq('id', userId)
            .maybeSingle();
        final saldadoHasta = perfil?['tricount_saldado_hasta'] as String?;

        var query = _c
            .from('finance_transactions')
            .select('monto, quien')
            .eq('user_id', userId)
            .eq('tipo', 'gasto')
            .eq('compartido', true);
        if (saldadoHasta != null) {
          query = query.gt('fecha', saldadoHasta);
        }
        final rows = await query;

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
        return BalanceCompartido(
          puestoPorYurby: yurby,
          puestoPorJuan: juan,
          saldadoHasta:
              saldadoHasta != null ? DateTime.parse(saldadoHasta) : null,
        );
      });

  /// Marca el reparto compartido como saldado hasta hoy: el balance vuelve a
  /// cero y solo contará los gastos compartidos futuros.
  Future<void> saldarCompartido() => _guard(() async {
        final userId = _userId();
        await _c.from('profiles').update({
          'tricount_saldado_hasta': _fechaSolo(DateTime.now()),
        }).eq('id', userId);
      });

  // ── Cuentas (saldos) ─────────────────────────────────────────

  Future<List<Cuenta>> cuentas() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('finance_accounts')
            .select('id, nombre, titular, saldo')
            .eq('user_id', userId)
            .order('orden');
        return (rows as List)
            .map((m) => Cuenta.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<void> guardarCuenta({
    String? id,
    required String nombre,
    String? titular,
    required double saldo,
  }) =>
      _guard(() async {
        final userId = _userId();
        if (nombre.trim().isEmpty) {
          throw const FinanzasException('La cuenta necesita un nombre.');
        }
        final datos = {
          'user_id': userId,
          'nombre': nombre.trim(),
          'titular': titular,
          'saldo': saldo,
        };
        if (id == null) {
          await _c.from('finance_accounts').insert(datos);
        } else {
          await _c.from('finance_accounts').update(datos).eq('id', id);
        }
      });

  Future<void> eliminarCuenta(String id) => _guard(() async {
        await _c.from('finance_accounts').delete().eq('id', id);
      });

  // ── Pagos de créditos (son movimientos con loan_id) ──────────
  // Pagar un crédito ES un gasto que sale de una cuenta: así descuenta el saldo
  // y queda en el historial de movimientos, todo en un solo lugar.

  Future<List<PagoCredito>> pagosDeCredito(String loanId) => _guard(() async {
        final rows = await _c
            .from('finance_transactions')
            .select('id, monto, fecha, nota')
            .eq('loan_id', loanId)
            .order('fecha', ascending: false);
        return (rows as List)
            .map((m) => PagoCredito.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  /// Resumen por crédito: cuántas cuotas pagadas y total, para TODOS los
  /// créditos de la usuaria (una sola consulta, sin N+1).
  Future<Map<String, ResumenCredito>> resumenPagosPorCredito() =>
      _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('finance_transactions')
            .select('loan_id, monto')
            .eq('user_id', userId)
            .not('loan_id', 'is', null);
        final cuotas = <String, int>{};
        final total = <String, double>{};
        for (final r in (rows as List)) {
          final lid = r['loan_id'] as String;
          cuotas.update(lid, (v) => v + 1, ifAbsent: () => 1);
          total.update(lid, (v) => v + (r['monto'] as num).toDouble(),
              ifAbsent: () => (r['monto'] as num).toDouble());
        }
        return {
          for (final lid in cuotas.keys)
            lid: ResumenCredito(
                cuotas: cuotas[lid]!, totalPagado: total[lid] ?? 0),
        };
      });

  /// Registra el pago de una cuota como un movimiento (gasto categoría
  /// "Pago Deuda") ligado al crédito y descontado de una cuenta.
  Future<void> registrarPagoCredito(
    String loanId, {
    required double monto,
    required DateTime fecha,
    String? cuentaId,
    String? quien,
  }) =>
      crearMovimiento(
        tipo: 'gasto',
        monto: monto,
        categoria: 'Pago Deuda',
        ambito: 'casa',
        fecha: fecha,
        quien: quien,
        cuentaId: cuentaId,
        loanId: loanId,
      );

  Future<void> eliminarPagoCredito(String id) => eliminarMovimiento(id);

  // ── Abonos a metas ───────────────────────────────────────────

  /// Registra un abono a una meta y actualiza su total ahorrado.
  Future<void> abonarMeta(
    String goalId, {
    required double monto,
    required DateTime fecha,
  }) =>
      _guard(() async {
        final userId = _userId();
        if (monto == 0) {
          throw const FinanzasException('El monto no puede ser cero.');
        }
        await _c.from('finance_goal_contributions').insert({
          'user_id': userId,
          'goal_id': goalId,
          'monto': monto,
          'fecha': _fechaSolo(fecha),
        });
        // Recalcula el ahorrado de la meta desde sus abonos (fuente de verdad).
        final abonos = await _c
            .from('finance_goal_contributions')
            .select('monto')
            .eq('goal_id', goalId);
        final ahorrado = (abonos as List)
            .fold<double>(0, (a, r) => a + (r['monto'] as num).toDouble());
        final meta = await _c
            .from('finance_goals')
            .select('meta_monto')
            .eq('id', goalId)
            .single();
        final metaMonto = (meta['meta_monto'] as num).toDouble();
        await _c.from('finance_goals').update({
          'ahorrado': ahorrado,
          'cumplida': metaMonto > 0 && ahorrado >= metaMonto,
        }).eq('id', goalId);
      });

  // ── Cierres de mes ───────────────────────────────────────────

  Future<void> cerrarMes(
    DateTime mes, {
    required Map<String, dynamic> resumen,
    String? pendiente,
  }) =>
      _guard(() async {
        final userId = _userId();
        await _c.from('finance_month_closes').upsert({
          'user_id': userId,
          'anno': mes.year,
          'mes': mes.month,
          'resumen': resumen,
          'pendiente':
              (pendiente == null || pendiente.trim().isEmpty)
                  ? null
                  : pendiente.trim(),
        }, onConflict: 'user_id,anno,mes');
      });

  /// Nota de pendientes del mes anterior a [mes] (para arrastrar contexto).
  Future<String?> pendienteMesAnterior(DateTime mes) => _guard(() async {
        final userId = _userId();
        final anterior = DateTime(mes.year, mes.month - 1, 1);
        final rows = await _c
            .from('finance_month_closes')
            .select('pendiente')
            .eq('user_id', userId)
            .eq('anno', anterior.year)
            .eq('mes', anterior.month)
            .maybeSingle();
        return rows?['pendiente'] as String?;
      });
}

final finanzasRepositoryProvider = Provider<FinanzasRepository>(
  (ref) => FinanzasRepository(ref.read(supabaseServiceProvider)),
);
