import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Un hábito con su estado de HOY (hecho / no hecho).
class Habito {
  const Habito({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.hecho,
    this.emoji,
    this.hora,
  });

  final String id;
  final String nombre;
  final int orden;
  final bool hecho;
  final String? emoji;
  final String? hora;

  Habito copyWith({bool? hecho}) => Habito(
        id: id,
        nombre: nombre,
        orden: orden,
        hecho: hecho ?? this.hecho,
        emoji: emoji,
        hora: hora,
      );
}

class HabitosRepository {
  HabitosRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  static const _iniciales = [
    {'nombre': 'Leer mis metas', 'emoji': '🎯', 'hora': 'Mañana', 'orden': 1},
    {'nombre': 'Citrato de magnesio', 'emoji': '💊', 'hora': '6:00 PM', 'orden': 2},
    {'nombre': 'Leer 10–15 min', 'emoji': '📖', 'hora': '9:00 PM', 'orden': 3},
    {'nombre': 'Teléfono apagado', 'emoji': '📵', 'hora': '9:00 PM', 'orden': 4},
  ];

  String get _hoy {
    final n = DateTime.now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  /// Crea los 4 hábitos SOLO si el usuario aún no tiene ninguno activo.
  Future<void> sembrarSiVacio() async {
    final user = _c.auth.currentUser;
    if (user == null) return;

    final existentes = await _c
        .from('habitos')
        .select('id')
        .eq('user_id', user.id)
        .eq('activo', true)
        .limit(1);

    if ((existentes as List).isNotEmpty) return;

    final filas = _iniciales
        .map((h) => {
              'user_id': user.id,
              'nombre': h['nombre'],
              'emoji': h['emoji'],
              'hora': h['hora'],
              'orden': h['orden'],
            })
        .toList();

    await _c.from('habitos').insert(filas);
  }

  /// Lee los hábitos del usuario con su estado de HOY.
  Future<List<Habito>> habitosDeHoy() async {
    final user = _c.auth.currentUser;
    if (user == null) return [];

    final habitos = await _c
        .from('habitos')
        .select('id, nombre, emoji, hora, orden')
        .eq('user_id', user.id)
        .eq('activo', true)
        .order('orden');

    final logs = await _c
        .from('habitos_log')
        .select('habito_id, hecho')
        .eq('user_id', user.id)
        .eq('fecha', _hoy);

    final hechos = <String, bool>{};
    for (final l in (logs as List)) {
      hechos[l['habito_id'] as String] = l['hecho'] as bool;
    }

    return (habitos as List)
        .map((h) => Habito(
              id: h['id'] as String,
              nombre: h['nombre'] as String,
              orden: (h['orden'] as num).toInt(),
              emoji: h['emoji'] as String?,
              hora: h['hora'] as String?,
              hecho: hechos[h['id']] ?? false,
            ))
        .toList();
  }

  /// Alterna hecho/no-hecho para HOY sin duplicar (1 fila por hábito/fecha).
  Future<void> alternar(String habitoId, bool estadoActual) async {
    final user = _c.auth.currentUser;
    if (user == null) return;

    await _c.from('habitos_log').upsert(
      {
        'user_id': user.id,
        'habito_id': habitoId,
        'fecha': _hoy,
        'hecho': !estadoActual,
      },
      onConflict: 'habito_id,fecha',
    );
  }
}

final habitosRepositoryProvider = Provider<HabitosRepository>(
  (ref) => HabitosRepository(ref.read(supabaseServiceProvider)),
);
