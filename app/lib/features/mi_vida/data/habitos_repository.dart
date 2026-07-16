import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Error de dominio con un mensaje que se puede mostrar tal cual.
class HabitosException implements Exception {
  const HabitosException(this.message);
  final String message;
  @override
  String toString() => message;
}

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

  String _userId() {
    final user = _c.auth.currentUser;
    if (user == null) {
      throw const HabitosException('Tu sesión expiró. Vuelve a entrar.');
    }
    return user.id;
  }

  String get _hoy {
    final n = DateTime.now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  /// Traduce cualquier fallo de Supabase a un mensaje humano.
  Future<T> _guard<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on HabitosException {
      rethrow;
    } on PostgrestException catch (e) {
      throw HabitosException(e.message);
    } catch (_) {
      throw const HabitosException(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }

  /// Crea los 4 hábitos SOLO si el usuario aún no tiene ninguno activo.
  ///
  /// Usa `upsert`: si un hábito con el mismo nombre existe pero desactivado, el
  /// insert violaría `UNIQUE(user_id, nombre)` y dejaría la tarjeta en error.
  Future<void> sembrarSiVacio() => _guard(() async {
        final userId = _userId();

        final existentes = await _c
            .from('habitos')
            .select('id')
            .eq('user_id', userId)
            .eq('activo', true)
            .limit(1);

        if ((existentes as List).isNotEmpty) return;

        final filas = _iniciales
            .map((h) => {
                  'user_id': userId,
                  'nombre': h['nombre'],
                  'emoji': h['emoji'],
                  'hora': h['hora'],
                  'orden': h['orden'],
                  'activo': true,
                })
            .toList();

        await _c.from('habitos').upsert(filas, onConflict: 'user_id,nombre');
      });

  /// Lee los hábitos del usuario con su estado de HOY.
  Future<List<Habito>> habitosDeHoy() => _guard(() async {
        final userId = _userId();

        final resultados = await Future.wait([
          _c
              .from('habitos')
              .select('id, nombre, emoji, hora, orden')
              .eq('user_id', userId)
              .eq('activo', true)
              .order('orden'),
          _c
              .from('habitos_log')
              .select('habito_id, hecho')
              .eq('user_id', userId)
              .eq('fecha', _hoy),
        ]);

        final hechos = <String, bool>{};
        for (final l in (resultados[1] as List)) {
          hechos[l['habito_id'] as String] = l['hecho'] as bool;
        }

        return (resultados[0] as List)
            .map((h) => Habito(
                  id: h['id'] as String,
                  nombre: h['nombre'] as String,
                  orden: (h['orden'] as num).toInt(),
                  emoji: h['emoji'] as String?,
                  hora: h['hora'] as String?,
                  hecho: hechos[h['id']] ?? false,
                ))
            .toList();
      });

  /// Alterna hecho/no-hecho para HOY sin duplicar (1 fila por hábito/fecha).
  Future<void> alternar(String habitoId, bool estadoActual) =>
      _guard(() async {
        final userId = _userId();
        await _c.from('habitos_log').upsert(
          {
            'user_id': userId,
            'habito_id': habitoId,
            'fecha': _hoy,
            'hecho': !estadoActual,
          },
          onConflict: 'habito_id,fecha',
        );
      });

  /// Crea un hábito. `upsert` por si existe uno desactivado con el mismo nombre
  /// (evita chocar con UNIQUE(user_id, nombre)); lo reactiva.
  Future<void> crear({required String nombre, String? emoji, String? hora}) =>
      _guard(() async {
        final userId = _userId();
        final limpio = nombre.trim();
        if (limpio.isEmpty) {
          throw const HabitosException('Ponle un nombre al hábito.');
        }
        await _c.from('habitos').upsert({
          'user_id': userId,
          'nombre': limpio,
          'emoji': (emoji == null || emoji.trim().isEmpty) ? null : emoji.trim(),
          'hora': (hora == null || hora.trim().isEmpty) ? null : hora.trim(),
          'activo': true,
        }, onConflict: 'user_id,nombre');
      });

  Future<void> editar(String id,
          {required String nombre, String? emoji, String? hora}) =>
      _guard(() async {
        final limpio = nombre.trim();
        if (limpio.isEmpty) {
          throw const HabitosException('Ponle un nombre al hábito.');
        }
        await _c.from('habitos').update({
          'nombre': limpio,
          'emoji': (emoji == null || emoji.trim().isEmpty) ? null : emoji.trim(),
          'hora': (hora == null || hora.trim().isEmpty) ? null : hora.trim(),
        }).eq('id', id);
      });

  /// Quita un hábito sin borrar su historial: lo desactiva.
  Future<void> eliminar(String id) => _guard(() async {
        await _c.from('habitos').update({'activo': false}).eq('id', id);
      });
}

final habitosRepositoryProvider = Provider<HabitosRepository>(
  (ref) => HabitosRepository(ref.read(supabaseServiceProvider)),
);
