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
  });

  final String id;
  final String titulo;
  final DateTime inicio; // local
  final String? descripcion;
  final DateTime? fin; // local
  final bool todoElDia;
  final String estado; // pendiente | realizado | cancelado
  final String? categoria;

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
      );
}

class AgendaRepository {
  AgendaRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  String? _limpio(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();

  /// Eventos cuyo inicio cae entre desde y hasta, en hora local.
  Future<List<Evento>> eventosEntre(DateTime desde, DateTime hasta) async {
    final user = _c.auth.currentUser;
    if (user == null) return [];
    final rows = await _c
        .from('events')
        .select(
            'id, titulo, descripcion, inicio, fin, todo_el_dia, estado, categoria')
        .eq('user_id', user.id)
        .gte('inicio', desde.toUtc().toIso8601String())
        .lt('inicio', hasta.toUtc().toIso8601String())
        .order('inicio');
    return (rows as List)
        .map((m) => Evento.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Próximos 7 días desde hoy (incluye hoy). Mi Vida deriva "hoy" de aquí.
  Future<List<Evento>> eventosSemana() {
    final n = DateTime.now();
    final ini = DateTime(n.year, n.month, n.day);
    return eventosEntre(ini, ini.add(const Duration(days: 7)));
  }

  Future<void> crear({
    required String titulo,
    required DateTime inicio,
    String? descripcion,
    DateTime? fin,
    bool todoElDia = false,
    String? categoria,
  }) async {
    final user = _c.auth.currentUser;
    if (user == null) return;
    await _c.from('events').insert({
      'user_id': user.id,
      'titulo': titulo.trim(),
      'descripcion': _limpio(descripcion),
      'inicio': inicio.toUtc().toIso8601String(),
      'fin': fin?.toUtc().toIso8601String(),
      'todo_el_dia': todoElDia,
      'categoria': _limpio(categoria),
    });
  }

  Future<void> editar(
    String id, {
    required String titulo,
    required DateTime inicio,
    String? descripcion,
    DateTime? fin,
    bool todoElDia = false,
    String? categoria,
  }) async {
    await _c.from('events').update({
      'titulo': titulo.trim(),
      'descripcion': _limpio(descripcion),
      'inicio': inicio.toUtc().toIso8601String(),
      'fin': fin?.toUtc().toIso8601String(),
      'todo_el_dia': todoElDia,
      'categoria': _limpio(categoria),
    }).eq('id', id);
  }

  Future<void> cambiarEstado(String id, String estado) async {
    await _c.from('events').update({'estado': estado}).eq('id', id);
  }

  Future<void> eliminar(String id) async {
    await _c.from('events').delete().eq('id', id);
  }
}

final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaRepository(ref.read(supabaseServiceProvider)),
);
