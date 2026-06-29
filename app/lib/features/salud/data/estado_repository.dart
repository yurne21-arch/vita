import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Estado de HOY: el último valor registrado de cada métrica (o null si no hay).
class EstadoHoy {
  const EstadoHoy({this.peso, this.energia, this.sueno, this.animo});

  final double? peso; // kg
  final int? energia; // 1-5
  final double? sueno; // horas
  final int? animo; // 1-5
}

/// Lee y escribe los eventos de Estado General. Append-only:
/// cada registro es un INSERT nuevo; nunca se actualiza ni se borra.
class EstadoRepository {
  EstadoRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  String get _hoy {
    final n = DateTime.now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  Future<num?> _ultimo(String tabla, String userId) async {
    final rows = await _c
        .from(tabla)
        .select('valor')
        .eq('user_id', userId)
        .eq('fecha', _hoy)
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return list.first['valor'] as num?;
  }

  /// Último valor de hoy de cada métrica.
  Future<EstadoHoy> estadoDeHoy() async {
    final user = _c.auth.currentUser;
    if (user == null) return const EstadoHoy();

    final peso = await _ultimo('weight_events', user.id);
    final energia = await _ultimo('energy_events', user.id);
    final sueno = await _ultimo('sleep_events', user.id);
    final animo = await _ultimo('mood_events', user.id);

    return EstadoHoy(
      peso: peso?.toDouble(),
      energia: energia?.toInt(),
      sueno: sueno?.toDouble(),
      animo: animo?.toInt(),
    );
  }

  /// Inserta un evento nuevo por cada métrica que venga con valor.
  Future<void> registrar({
    double? peso,
    int? energia,
    double? sueno,
    int? animo,
  }) async {
    final user = _c.auth.currentUser;
    if (user == null) return;

    if (peso != null) {
      await _c
          .from('weight_events')
          .insert({'user_id': user.id, 'fecha': _hoy, 'valor': peso});
    }
    if (energia != null) {
      await _c
          .from('energy_events')
          .insert({'user_id': user.id, 'fecha': _hoy, 'valor': energia});
    }
    if (sueno != null) {
      await _c
          .from('sleep_events')
          .insert({'user_id': user.id, 'fecha': _hoy, 'valor': sueno});
    }
    if (animo != null) {
      await _c
          .from('mood_events')
          .insert({'user_id': user.id, 'fecha': _hoy, 'valor': animo});
    }
  }
}

final estadoRepositoryProvider = Provider<EstadoRepository>(
  (ref) => EstadoRepository(ref.read(supabaseServiceProvider)),
);
