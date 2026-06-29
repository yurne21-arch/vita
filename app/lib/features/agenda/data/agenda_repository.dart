import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Un evento del calendario propio de VITA. Editable.
class Evento {
  const Evento({
    required this.id,
    required this.titulo,
    required this.inicio,
    this.descripcion,
    this.fin,
    this.todoElDia = false,
    this.estado = 'pendiente',
    this.categoria,
    this.importancia = 'normal',
  });

  final String id;
  final String titulo;
  final DateTime inicio; // local
  final String? descripcion;
  final DateTime? fin; // local
  final bool todoElDia;
  final String estado; // pendiente | realizado | cancelado
  final String? categoria;
  final String importancia; // normal | importante | critico

  bool get realizado => estado == 'realizado';
  bool get cancelado => estado == 'cancelado';

  Evento copyWith({String? estado}) => Evento(
        id: id,
        titulo: titulo,
        inicio: inicio,
        descripcion: descripcion,
        fin: fin,
        todoElDia: todoElDia,
        estado: estado ?? this.estado,
        categoria: categoria,
        importancia: importancia,
      );

  factory Evento.fromMap(Map<String, dynamic> m) => Evento(
        id: m['id'] as String,
        titulo: m['titulo'] as String,
        inicio: DateTime.parse(m['inicio'] as String).toLocal(),
        descripcion: m['descripcion'] as String?,
        fin: m['fin'] != null
            ? DateTime.parse(m['fin'] as String).toLocal()
            : null,
        todoElDia: (m['todo_el_dia'] as bool?) ?? false,
        estado: (m['estado'] as String?) ?? 'pendiente',
        categoria: m['categoria'] as String?,
        importancia: (m['importancia'] as String?) ?? 'normal',
      );
}

class AgendaRepository {
  AgendaRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  String? _limpio(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();

  static const _cols =
      'id, titulo, descripcion, inicio, fin, todo_el_dia, estado, categoria, importancia';

  /// Eventos cuyo inicio cae entre desde y hasta, en hora local.
  Future<List<Evento>> eventosEntre(DateTime desde, DateTime hasta) async {
    final user = _c.auth.currentUser;
    if (user == null) return [];
    final rows = await _c
        .from('events')
        .select(_cols)
        .eq('user_id', user.id)
        .gte('inicio', desde.toUtc().toIso8601String())
        .lt('inicio', hasta.toUtc().toIso8601String())
        .order('inicio');
    return (rows as List)
        .map((m) => Evento.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Crea un evento y devuelve su id (para guardar recordatorios).
  Future<String?> crear({
    required String titulo,
    required DateTime inicio,
    String? descripcion,
    DateTime? fin,
    bool todoElDia = false,
    String? categoria,
    String importancia = 'normal',
  }) async {
    final user = _c.auth.currentUser;
    if (user == null) return null;
    final row = await _c
        .from('events')
        .insert({
          'user_id': user.id,
          'titulo': titulo.trim(),
          'descripcion': _limpio(descripcion),
          'inicio': inicio.toUtc().toIso8601String(),
          'fin': fin?.toUtc().toIso8601String(),
          'todo_el_dia': todoElDia,
          'categoria': _limpio(categoria),
          'importancia': importancia,
        })
        .select('id')
        .single();
    return row['id'] as String?;
  }

  Future<void> editar(
    String id, {
    required String titulo,
    required DateTime inicio,
    String? descripcion,
    DateTime? fin,
    bool todoElDia = false,
    String? categoria,
    String importancia = 'normal',
  }) async {
    await _c.from('events').update({
      'titulo': titulo.trim(),
      'descripcion': _limpio(descripcion),
      'inicio': inicio.toUtc().toIso8601String(),
      'fin': fin?.toUtc().toIso8601String(),
      'todo_el_dia': todoElDia,
      'categoria': _limpio(categoria),
      'importancia': importancia,
    }).eq('id', id);
  }

  Future<void> cambiarEstado(String id, String estado) async {
    await _c.from('events').update({'estado': estado}).eq('id', id);
  }

  Future<void> eliminar(String id) async {
    await _c.from('events').delete().eq('id', id);
  }

  // ---- Recordatorios (event_reminders) ----

  /// Offsets en minutos (10, 30, 60, 1440) de un evento.
  Future<List<int>> recordatoriosDe(String eventId) async {
    final rows = await _c
        .from('event_reminders')
        .select('offset_min')
        .eq('event_id', eventId)
        .order('offset_min');
    return (rows as List).map((m) => (m['offset_min'] as num).toInt()).toList();
  }

  /// Reemplaza todos los recordatorios del evento por la lista dada.
  Future<void> reemplazarRecordatorios(
      String eventId, List<int> offsets) async {
    final user = _c.auth.currentUser;
    if (user == null) return;
    await _c.from('event_reminders').delete().eq('event_id', eventId);
    if (offsets.isEmpty) return;
    await _c.from('event_reminders').insert([
      for (final o in offsets)
        {'event_id': eventId, 'user_id': user.id, 'offset_min': o},
    ]);
  }
}

final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaRepository(ref.read(supabaseServiceProvider)),
);
