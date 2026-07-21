import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';
import '../domain/mi_mes.dart';

/// Error de dominio con mensaje mostrable tal cual.
class MiMesException implements Exception {
  const MiMesException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Arma el balance del mes leyendo las tablas de cada área directamente.
///
/// Mi Mes no importa otros features (los features están aislados: MASTER §7);
/// lee las tablas que necesita a través de Supabase, igual que cualquier repo.
/// Lo único propio que persiste es la reflexión de la usuaria.
class MiMesRepository {
  MiMesRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  String _userId() {
    final user = _c.auth.currentUser;
    if (user == null) {
      throw const MiMesException('Tu sesión expiró. Vuelve a entrar.');
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
    } on MiMesException {
      rethrow;
    } on PostgrestException catch (e) {
      throw MiMesException(e.message);
    } catch (_) {
      throw const MiMesException(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }

  static double? _prom(List<num> valores) {
    if (valores.isEmpty) return null;
    final suma = valores.fold<double>(0, (a, b) => a + b);
    return suma / valores.length;
  }

  /// El balance completo de [mes] (se usa el primer día del mes como clave).
  Future<BalanceMes> balanceDelMes(DateTime mes) => _guard(() async {
        final userId = _userId();
        final desde = DateTime(mes.year, mes.month, 1);
        final hasta = DateTime(mes.year, mes.month + 1, 1);
        final desdeStr = _fechaSolo(desde);
        final hastaStr = _fechaSolo(hasta);

        final resultados = await Future.wait<dynamic>([
          _proyectos(userId, desdeStr, hastaStr),
          _salud(userId, desdeStr, hastaStr),
          _habitos(userId, desdeStr, hastaStr),
          _finanzas(userId, mes, desdeStr, hastaStr),
          _agenda(userId, desde, hasta),
        ]);

        return BalanceMes(
          mes: desde,
          proyectos: resultados[0] as ResumenProyectosMes,
          salud: resultados[1] as ResumenSaludMes,
          habitos: resultados[2] as List<HabitoMes>,
          finanzas: resultados[3] as ResumenFinanzasMes,
          agenda: resultados[4] as ResumenAgendaMes,
        );
      });

  // ───────────────── Proyectos / trabajo ─────────────────

  Future<ResumenProyectosMes> _proyectos(
      String userId, String desde, String hasta) async {
    // Bitácora del mes: avances (pasos) e hitos completados.
    final log = await _c
        .from('project_log')
        .select('tipo, texto, fecha')
        .eq('user_id', userId)
        .gte('fecha', desde)
        .lt('fecha', hasta)
        .order('fecha', ascending: false);

    var pasos = 0;
    var hitos = 0;
    final avances = <String>[];
    for (final row in log as List) {
      final tipo = row['tipo'] as String?;
      final texto = (row['texto'] as String?)?.trim();
      if (tipo == 'avance') {
        pasos++;
        if (texto != null && texto.isNotEmpty) avances.add(texto);
      } else if (tipo == 'hito_completado') {
        hitos++;
        if (texto != null && texto.isNotEmpty) avances.add('🏁 $texto');
      }
    }

    // Pendientes: pasos aún por hacer en proyectos activos (foto de hoy).
    var pendientes = 0;
    final activos = await _c
        .from('projects')
        .select('id')
        .eq('user_id', userId)
        .eq('estado', 'activo');
    final ids = (activos as List).map((r) => r['id'] as String).toList();
    if (ids.isNotEmpty) {
      final tareas = await _c
          .from('project_tasks')
          .select('id')
          .eq('user_id', userId)
          .eq('tipo', 'paso')
          .eq('completada', false)
          .inFilter('project_id', ids);
      pendientes = (tareas as List).length;
    }

    return ResumenProyectosMes(
      pasosCompletados: pasos,
      hitosLogrados: hitos,
      pendientes: pendientes,
      avances: avances,
    );
  }

  // ───────────────── Salud ─────────────────

  Future<ResumenSaludMes> _salud(
      String userId, String desde, String hasta) async {
    Future<List<Map<String, dynamic>>> traer(String tabla, String cols) async {
      final rows = await _c
          .from(tabla)
          .select(cols)
          .eq('user_id', userId)
          .gte('fecha', desde)
          .lt('fecha', hasta);
      return (rows as List).cast<Map<String, dynamic>>();
    }

    final res = await Future.wait([
      traer('energy_events', 'valor, fecha'),
      traer('mood_events', 'valor, fecha'),
      traer('sleep_events', 'valor, fecha'),
      traer('weight_events', 'valor, fecha'),
    ]);
    final energia = res[0];
    final animo = res[1];
    final sueno = res[2];
    final peso = res[3];

    final dias = <String>{};
    for (final r in [...energia, ...animo, ...sueno]) {
      final f = r['fecha'] as String?;
      if (f != null) dias.add(f);
    }

    double? pesoInicio;
    double? pesoFin;
    if (peso.isNotEmpty) {
      final ordenados = [...peso]
        ..sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));
      pesoInicio = (ordenados.first['valor'] as num).toDouble();
      pesoFin = (ordenados.last['valor'] as num).toDouble();
    }

    return ResumenSaludMes(
      diasRegistrados: dias.length,
      energiaProm: _prom(energia.map((r) => r['valor'] as num).toList()),
      animoProm: _prom(animo.map((r) => r['valor'] as num).toList()),
      suenoHorasProm: _prom(sueno
          .map((r) => r['valor'] as num?)
          .whereType<num>()
          .toList()),
      pesoInicio: pesoInicio,
      pesoFin: pesoFin,
    );
  }

  // ───────────────── Hábitos ─────────────────

  Future<List<HabitoMes>> _habitos(
      String userId, String desde, String hasta) async {
    final log = await _c
        .from('habitos_log')
        .select('habito_id, hecho, fecha')
        .eq('user_id', userId)
        .eq('hecho', true)
        .gte('fecha', desde)
        .lt('fecha', hasta);

    final conteo = <String, int>{};
    for (final r in log as List) {
      final id = r['habito_id'] as String?;
      if (id != null) conteo.update(id, (v) => v + 1, ifAbsent: () => 1);
    }
    if (conteo.isEmpty) return const [];

    final defs = await _c
        .from('habitos')
        .select('id, nombre, emoji')
        .eq('user_id', userId);
    final nombres = <String, Map<String, dynamic>>{
      for (final d in defs as List) d['id'] as String: d as Map<String, dynamic>
    };

    final lista = <HabitoMes>[];
    conteo.forEach((id, dias) {
      final def = nombres[id];
      lista.add(HabitoMes(
        nombre: (def?['nombre'] as String?) ?? 'Hábito',
        emoji: def?['emoji'] as String?,
        diasCumplidos: dias,
      ));
    });
    lista.sort((a, b) => b.diasCumplidos.compareTo(a.diasCumplidos));
    return lista;
  }

  // ───────────────── Finanzas ─────────────────

  Future<ResumenFinanzasMes> _finanzas(
      String userId, DateTime mes, String desde, String hasta) async {
    final rows = await _c
        .from('finance_transactions')
        .select('tipo, monto, categoria')
        .eq('user_id', userId)
        .gte('fecha', desde)
        .lt('fecha', hasta);

    var ingresos = 0.0;
    var gastos = 0.0;
    final porCategoria = <String, double>{};
    for (final r in rows as List) {
      final tipo = r['tipo'] as String?;
      final monto = (r['monto'] as num).toDouble();
      final categoria = (r['categoria'] as String?) ?? 'Otros';
      if (tipo == 'ingreso') {
        ingresos += monto;
      } else if (tipo == 'gasto' && categoria != 'Pago Deuda') {
        // Los pagos de deuda/tarjeta no son consumo (mismo criterio que Finanzas).
        gastos += monto;
        porCategoria.update(categoria, (v) => v + monto, ifAbsent: () => monto);
      }
    }

    final cierre = await _c
        .from('finance_month_closes')
        .select('id')
        .eq('user_id', userId)
        .eq('anno', mes.year)
        .eq('mes', mes.month)
        .limit(1);

    return ResumenFinanzasMes(
      ingresos: ingresos,
      gastos: gastos,
      cerrado: (cierre as List).isNotEmpty,
      porCategoria: porCategoria,
    );
  }

  // ───────────────── Agenda ─────────────────

  Future<ResumenAgendaMes> _agenda(
      String userId, DateTime desde, DateTime hasta) async {
    final rows = await _c
        .from('events')
        .select('estado')
        .eq('user_id', userId)
        .gte('inicio', desde.toUtc().toIso8601String())
        .lt('inicio', hasta.toUtc().toIso8601String());
    final lista = rows as List;
    final realizados =
        lista.where((r) => r['estado'] == 'realizado').length;
    return ResumenAgendaMes(realizados: realizados, total: lista.length);
  }

  // ───────────────── Reflexión (lo que ella escribe) ─────────────────

  Future<ReflexionMes?> reflexionDelMes(DateTime mes) => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('month_reflections')
            .select('anno, mes, salio_bien, a_mejorar, foco')
            .eq('user_id', userId)
            .eq('anno', mes.year)
            .eq('mes', mes.month)
            .limit(1);
        final l = rows as List;
        if (l.isEmpty) return null;
        return ReflexionMes.fromMap(l.first as Map<String, dynamic>);
      });

  Future<void> guardarReflexion(
    DateTime mes, {
    String? salioBien,
    String? aMejorar,
    String? foco,
  }) =>
      _guard(() async {
        final userId = _userId();
        String? limpio(String? s) =>
            (s == null || s.trim().isEmpty) ? null : s.trim();
        await _c.from('month_reflections').upsert({
          'user_id': userId,
          'anno': mes.year,
          'mes': mes.month,
          'salio_bien': limpio(salioBien),
          'a_mejorar': limpio(aMejorar),
          'foco': limpio(foco),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id,anno,mes');
      });

  /// Meses con algo registrado, del más reciente al más antiguo. Sirve para el
  /// selector de meses. Se apoya en movimientos y bitácora (lo más habitual).
  Future<List<DateTime>> mesesConDatos() => _guard(() async {
        final userId = _userId();
        final fechas = <String>{};
        final tx = await _c
            .from('finance_transactions')
            .select('fecha')
            .eq('user_id', userId)
            .order('fecha', ascending: false)
            .limit(400);
        for (final r in tx as List) {
          fechas.add(r['fecha'] as String);
        }
        final log = await _c
            .from('project_log')
            .select('fecha')
            .eq('user_id', userId)
            .order('fecha', ascending: false)
            .limit(400);
        for (final r in log as List) {
          final f = (r['fecha'] as String);
          fechas.add(f.length >= 10 ? f.substring(0, 10) : f);
        }
        final meses = <String>{};
        for (final f in fechas) {
          meses.add(f.substring(0, 7)); // YYYY-MM
        }
        final lista = meses.map((m) {
          final p = m.split('-');
          return DateTime(int.parse(p[0]), int.parse(p[1]), 1);
        }).toList()
          ..sort((a, b) => b.compareTo(a));
        return lista;
      });
}

final miMesRepositoryProvider = Provider<MiMesRepository>(
  (ref) => MiMesRepository(ref.read(supabaseServiceProvider)),
);
