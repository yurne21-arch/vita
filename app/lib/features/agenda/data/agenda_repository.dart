import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Error de dominio con un mensaje que se puede mostrar tal cual.
class AgendaException implements Exception {
  const AgendaException(this.message);
  final String message;
  @override
  String toString() => message;
}

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

  String _userId() {
    final user = _c.auth.currentUser;
    if (user == null) {
      throw const AgendaException('Tu sesión expiró. Vuelve a entrar.');
    }
    return user.id;
  }

  /// Traduce cualquier fallo de Supabase a un mensaje humano.
  Future<T> _guard<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AgendaException {
      rethrow;
    } on PostgrestException catch (e) {
      throw AgendaException(e.message);
    } catch (_) {
      throw const AgendaException(
        'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      );
    }
  }

  static const _cols =
      'id, titulo, descripcion, inicio, fin, todo_el_dia, estado, categoria, importancia';

  /// Eventos cuyo inicio cae entre desde y hasta, en hora local.
  Future<List<Evento>> eventosEntre(DateTime desde, DateTime hasta) =>
      _guard(() async {
        final userId = _userId();
        final rows = await _c
            .from('events')
            .select(_cols)
            .eq('user_id', userId)
            .gte('inicio', desde.toUtc().toIso8601String())
            .lt('inicio', hasta.toUtc().toIso8601String())
            .order('inicio');
        return (rows as List)
            .map((m) => Evento.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  /// Valida lo que la base exige, para poder explicarlo antes de ir al servidor.
  void _validar(String titulo, DateTime inicio, DateTime? fin) {
    if (titulo.trim().isEmpty) {
      throw const AgendaException('El evento necesita un título.');
    }
    if (fin != null && fin.isBefore(inicio)) {
      throw const AgendaException(
        'El evento no puede terminar antes de empezar.',
      );
    }
  }

  /// Crea un evento y devuelve su id (para guardar recordatorios).
  Future<String> crear({
    required String titulo,
    required DateTime inicio,
    String? descripcion,
    DateTime? fin,
    bool todoElDia = false,
    String? categoria,
    String importancia = 'normal',
  }) =>
      _guard(() async {
        final userId = _userId();
        _validar(titulo, inicio, fin);
        final row = await _c
            .from('events')
            .insert({
              'user_id': userId,
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
        return row['id'] as String;
      });

  Future<void> editar(
    String id, {
    required String titulo,
    required DateTime inicio,
    String? descripcion,
    DateTime? fin,
    bool todoElDia = false,
    String? categoria,
    String importancia = 'normal',
  }) =>
      _guard(() async {
        _validar(titulo, inicio, fin);
        await _c.from('events').update({
          'titulo': titulo.trim(),
          'descripcion': _limpio(descripcion),
          'inicio': inicio.toUtc().toIso8601String(),
          'fin': fin?.toUtc().toIso8601String(),
          'todo_el_dia': todoElDia,
          'categoria': _limpio(categoria),
          'importancia': importancia,
        }).eq('id', id);
      });

  Future<void> cambiarEstado(String id, String estado) => _guard(() async {
        await _c.from('events').update({'estado': estado}).eq('id', id);
      });

  Future<void> eliminar(String id) => _guard(() async {
        await _c.from('events').delete().eq('id', id);
      });

  // ---- Recordatorios (event_reminders) ----

  /// Offsets en minutos (10, 30, 60, 1440) de un evento.
  Future<List<int>> recordatoriosDe(String eventId) => _guard(() async {
        final rows = await _c
            .from('event_reminders')
            .select('offset_min')
            .eq('event_id', eventId)
            .order('offset_min');
        return (rows as List)
            .map((m) => (m['offset_min'] as num).toInt())
            .toList();
      });

  /// Reemplaza todos los recordatorios del evento por la lista dada.
  Future<void> reemplazarRecordatorios(
    String eventId,
    List<int> offsets,
  ) =>
      _guard(() async {
        final userId = _userId();
        await _c.from('event_reminders').delete().eq('event_id', eventId);
        if (offsets.isEmpty) return;
        await _c.from('event_reminders').insert([
          for (final o in offsets)
            {'event_id': eventId, 'user_id': userId, 'offset_min': o},
        ]);
      });
}

final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaRepository(ref.read(supabaseServiceProvider)),
);
