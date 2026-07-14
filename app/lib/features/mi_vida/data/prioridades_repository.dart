import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Error de dominio con un mensaje que se puede mostrar tal cual.
class PrioridadesException implements Exception {
  const PrioridadesException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Una prioridad del día (Hoy Importa). Editable.
class Prioridad {
  const Prioridad({
    required this.id,
    required this.texto,
    required this.orden,
    required this.completada,
  });

  final String id;
  final String texto;
  final int orden;
  final bool completada;

  Prioridad copyWith({String? texto, int? orden, bool? completada}) => Prioridad(
        id: id,
        texto: texto ?? this.texto,
        orden: orden ?? this.orden,
        completada: completada ?? this.completada,
      );

  factory Prioridad.fromMap(Map<String, dynamic> m) => Prioridad(
        id: m['id'] as String,
        texto: m['texto'] as String,
        orden: (m['orden'] as num).toInt(),
        completada: m['completada'] as bool,
      );
}

class PrioridadesRepository {
  PrioridadesRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  /// Tope de prioridades por día. La base lo garantiza con un trigger; aquí se
  /// valida antes para poder dar un mensaje claro sin ir al servidor.
  static const int maximoPorDia = 3;

  String _userId() {
    final user = _c.auth.currentUser;
    if (user == null) {
      throw const PrioridadesException('Tu sesión expiró. Vuelve a entrar.');
    }
    return user.id;
  }

  String get _hoy {
    final n = DateTime.now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  /// Traduce cualquier fallo de Supabase a un mensaje humano. El trigger
  /// `dp_max_tres` lanza 'Máximo 3 prioridades por día': su texto se respeta.
  Future<T> _guard<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on PrioridadesException {
      rethrow;
    } on PostgrestException catch (e) {
      throw PrioridadesException(e.message);
    } catch (_) {
      throw const PrioridadesException(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }

  Future<List<Prioridad>> prioridadesDeHoy() => _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('daily_priorities')
            .select('id, texto, orden, completada')
            .eq('user_id', userId)
            .eq('fecha', _hoy)
            .order('orden');
        return (rows as List)
            .map((m) => Prioridad.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  Future<void> agregar(String texto) => _guard(() async {
        final userId = _userId();
        final limpio = texto.trim();
        if (limpio.isEmpty) {
          throw const PrioridadesException('Escribe algo primero.');
        }

        final actuales = await prioridadesDeHoy();
        if (actuales.length >= maximoPorDia) {
          throw const PrioridadesException(
            'Solo $maximoPorDia prioridades al día. Es a propósito: '
            'obliga a elegir lo que de verdad importa.',
          );
        }

        // Primer hueco libre en 1..3 (los órdenes pueden tener saltos si se
        // borró una prioridad del medio).
        final usados = actuales.map((p) => p.orden).toSet();
        final orden = [
          for (var i = 1; i <= maximoPorDia; i++) i,
        ].firstWhere((i) => !usados.contains(i));

        await _c.from('daily_priorities').insert({
          'user_id': userId,
          'fecha': _hoy,
          'texto': limpio,
          'orden': orden,
        });
      });

  Future<void> editarTexto(String id, String texto) => _guard(() async {
        final limpio = texto.trim();
        if (limpio.isEmpty) {
          throw const PrioridadesException('Escribe algo primero.');
        }
        await _c
            .from('daily_priorities')
            .update({'texto': limpio}).eq('id', id);
      });

  Future<void> alternarCompletada(String id, bool actual) => _guard(() async {
        await _c
            .from('daily_priorities')
            .update({'completada': !actual})
            .eq('id', id);
      });

  Future<void> eliminar(String id) => _guard(() async {
        await _c.from('daily_priorities').delete().eq('id', id);
      });

  /// Reasigna orden 1..N según la lista recibida, en una sola escritura.
  Future<void> reordenar(List<Prioridad> ordenadas) => _guard(() async {
        final userId = _userId();
        if (ordenadas.length > maximoPorDia) {
          throw const PrioridadesException(
            'Solo $maximoPorDia prioridades al día.',
          );
        }
        if (ordenadas.isEmpty) return;

        await _c.from('daily_priorities').upsert([
          for (var i = 0; i < ordenadas.length; i++)
            {
              'id': ordenadas[i].id,
              'user_id': userId,
              'fecha': _hoy,
              'texto': ordenadas[i].texto,
              'completada': ordenadas[i].completada,
              'orden': i + 1,
            },
        ]);
      });
}

final prioridadesRepositoryProvider = Provider<PrioridadesRepository>(
  (ref) => PrioridadesRepository(ref.read(supabaseServiceProvider)),
);
