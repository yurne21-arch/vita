import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

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

  String get _hoy {
    final n = DateTime.now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  Future<List<Prioridad>> prioridadesDeHoy() async {
    final user = _c.auth.currentUser;
    if (user == null) return [];
    final rows = await _c
        .from('daily_priorities')
        .select('id, texto, orden, completada')
        .eq('user_id', user.id)
        .eq('fecha', _hoy)
        .order('orden');
    return (rows as List)
        .map((m) => Prioridad.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> agregar(String texto) async {
    final user = _c.auth.currentUser;
    if (user == null) return;
    final limpio = texto.trim();
    if (limpio.isEmpty) return; // nunca guardar vacío
    final actuales = await prioridadesDeHoy();
    if (actuales.length >= 3) return; // tope
    final usados = actuales.map((p) => p.orden).toSet();
    var orden = 1;
    while (usados.contains(orden) && orden < 3) {
      orden++;
    }
    await _c.from('daily_priorities').insert({
      'user_id': user.id,
      'fecha': _hoy,
      'texto': limpio,
      'orden': orden,
    });
  }

  Future<void> editarTexto(String id, String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return; // nunca guardar vacío
    await _c.from('daily_priorities').update({'texto': limpio}).eq('id', id);
  }

  Future<void> alternarCompletada(String id, bool actual) async {
    await _c
        .from('daily_priorities')
        .update({'completada': !actual})
        .eq('id', id);
  }

  Future<void> eliminar(String id) async {
    await _c.from('daily_priorities').delete().eq('id', id);
  }

  /// Reasigna orden 1..N según la lista recibida.
  Future<void> reordenar(List<Prioridad> ordenadas) async {
    for (var i = 0; i < ordenadas.length; i++) {
      await _c
          .from('daily_priorities')
          .update({'orden': i + 1})
          .eq('id', ordenadas[i].id);
    }
  }
}

final prioridadesRepositoryProvider = Provider<PrioridadesRepository>(
  (ref) => PrioridadesRepository(ref.read(supabaseServiceProvider)),
);
