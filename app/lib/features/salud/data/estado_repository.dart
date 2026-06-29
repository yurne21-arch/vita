import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Estado mostrado en la tarjeta "Cómo estás hoy".
/// - peso: el ÚLTIMO registrado (no necesariamente de hoy) + tendencia.
/// - energía / ánimo / sueño: lo de HOY si existe.
class EstadoHoy {
  const EstadoHoy({
    this.pesoUltimo,
    this.pesoTendencia,
    this.pesoEstaSemana = false,
    this.energia,
    this.animo,
    this.suenoCalidad,
    this.suenoHoras,
  });

  final double? pesoUltimo; // kg, cualquier fecha
  final double? pesoTendencia; // kg vs el peso anterior (null si no hay 2)
  final bool pesoEstaSemana; // ya registró peso esta semana
  final int? energia; // hoy 1-5
  final int? animo; // hoy 1-5
  final int? suenoCalidad; // hoy 1=mal, 2=regular, 3=bien
  final double? suenoHoras; // hoy, opcional
}

/// Eventos de Estado General (append-only, eventos separados por métrica).
class EstadoRepository {
  EstadoRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  String _fecha(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String get _hoy => _fecha(DateTime.now());

  String get _inicioSemana {
    final n = DateTime.now();
    final lunes = n.subtract(Duration(days: n.weekday - 1));
    return _fecha(DateTime(lunes.year, lunes.month, lunes.day));
  }

  Future<num?> _ultimoHoy(String tabla, String userId, String col) async {
    final rows = await _c
        .from(tabla)
        .select(col)
        .eq('user_id', userId)
        .eq('fecha', _hoy)
        .order('created_at', ascending: false)
        .limit(1);
    final l = rows as List;
    if (l.isEmpty) return null;
    return l.first[col] as num?;
  }

  Future<EstadoHoy> estadoDeHoy() async {
    final user = _c.auth.currentUser;
    if (user == null) return const EstadoHoy();

    // Peso: los 2 últimos (cualquier fecha) para valor actual + tendencia.
    final pesos = await _c
        .from('weight_events')
        .select('valor')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(2);
    final pl = pesos as List;
    double? pesoUltimo;
    double? pesoTend;
    if (pl.isNotEmpty) {
      pesoUltimo = (pl[0]['valor'] as num).toDouble();
      if (pl.length >= 2) {
        pesoTend = pesoUltimo - (pl[1]['valor'] as num).toDouble();
      }
    }

    // ¿Ya registró peso esta semana? (lunes a hoy)
    final semana = await _c
        .from('weight_events')
        .select('id')
        .eq('user_id', user.id)
        .gte('fecha', _inicioSemana)
        .limit(1);
    final pesoEstaSemana = (semana as List).isNotEmpty;

    final energia = await _ultimoHoy('energy_events', user.id, 'valor');
    final animo = await _ultimoHoy('mood_events', user.id, 'valor');

    // Sueño de hoy: calidad + horas (ambas pueden venir o no).
    final sue = await _c
        .from('sleep_events')
        .select('calidad, valor')
        .eq('user_id', user.id)
        .eq('fecha', _hoy)
        .order('created_at', ascending: false)
        .limit(1);
    final sl = sue as List;
    int? suenoCalidad;
    double? suenoHoras;
    if (sl.isNotEmpty) {
      suenoCalidad = (sl[0]['calidad'] as num?)?.toInt();
      suenoHoras = (sl[0]['valor'] as num?)?.toDouble();
    }

    return EstadoHoy(
      pesoUltimo: pesoUltimo,
      pesoTendencia: pesoTend,
      pesoEstaSemana: pesoEstaSemana,
      energia: energia?.toInt(),
      animo: animo?.toInt(),
      suenoCalidad: suenoCalidad,
      suenoHoras: suenoHoras,
    );
  }

  /// Registro rápido diario: energía, ánimo y/o sueño (cualidad + horas).
  Future<void> registrarDiario({
    int? energia,
    int? animo,
    int? suenoCalidad,
    double? suenoHoras,
  }) async {
    final user = _c.auth.currentUser;
    if (user == null) return;

    if (energia != null) {
      await _c
          .from('energy_events')
          .insert({'user_id': user.id, 'fecha': _hoy, 'valor': energia});
    }
    if (animo != null) {
      await _c
          .from('mood_events')
          .insert({'user_id': user.id, 'fecha': _hoy, 'valor': animo});
    }
    if (suenoCalidad != null || suenoHoras != null) {
      final row = <String, dynamic>{'user_id': user.id, 'fecha': _hoy};
      if (suenoCalidad != null) row['calidad'] = suenoCalidad;
      if (suenoHoras != null) row['valor'] = suenoHoras;
      await _c.from('sleep_events').insert(row);
    }
  }

  /// Registro de peso (semanal o manual).
  Future<void> registrarPeso(double peso) async {
    final user = _c.auth.currentUser;
    if (user == null) return;
    await _c
        .from('weight_events')
        .insert({'user_id': user.id, 'fecha': _hoy, 'valor': peso});
  }
}

final estadoRepositoryProvider = Provider<EstadoRepository>(
  (ref) => EstadoRepository(ref.read(supabaseServiceProvider)),
);
