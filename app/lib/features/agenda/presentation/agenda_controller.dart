import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/agenda_repository.dart';

/// Rango de fechas desde-hasta que una vista quiere cargar.
@immutable
class RangoFechas {
  const RangoFechas(this.desde, this.hasta);
  final DateTime desde;
  final DateTime hasta;

  @override
  bool operator ==(Object other) =>
      other is RangoFechas && other.desde == desde && other.hasta == hasta;

  @override
  int get hashCode => Object.hash(desde, hasta);
}

/// Eventos en un rango. Cada vista (Hoy/Semana/Mes y "Tu Día") pide el suyo.
/// Una sola fuente de lógica; las acciones invalidan toda la familia.
final eventosEnRangoProvider =
    FutureProvider.family<List<Evento>, RangoFechas>((ref, r) {
  ref.watch(usuarioActualProvider); // recarga si cambia la sesión
  return ref.watch(agendaRepositoryProvider).eventosEntre(r.desde, r.hasta);
});

/// Rango de "hoy" (para la tarjeta Tu Día de Mi Vida).
RangoFechas rangoHoy() {
  final n = DateTime.now();
  final ini = DateTime(n.year, n.month, n.day);
  return RangoFechas(ini, ini.add(const Duration(days: 1)));
}

/// Rango de "semana" (próximos 7 días desde hoy).
RangoFechas rangoSemana() {
  final n = DateTime.now();
  final ini = DateTime(n.year, n.month, n.day);
  return RangoFechas(ini, ini.add(const Duration(days: 7)));
}

/// Acciones de Agenda. Tras cada cambio, invalida toda la familia de rangos
/// para que Mi Vida y Calendario se actualicen.
class AgendaAcciones {
  AgendaAcciones(this._ref);
  final Ref _ref;
  AgendaRepository get _repo => _ref.read(agendaRepositoryProvider);

  void _refrescar() => _ref.invalidate(eventosEnRangoProvider);

  Future<void> crear({
    required String titulo,
    required DateTime inicio,
    String? descripcion,
    DateTime? fin,
    bool todoElDia = false,
    String? categoria,
    String importancia = 'normal',
    List<int> recordatorios = const [],
  }) async {
    final id = await _repo.crear(
      titulo: titulo,
      inicio: inicio,
      descripcion: descripcion,
      fin: fin,
      todoElDia: todoElDia,
      categoria: categoria,
      importancia: importancia,
    );
    if (recordatorios.isNotEmpty) {
      await _repo.reemplazarRecordatorios(id, recordatorios);
    }
    _refrescar();
  }

  /// [recordatorios] en null significa "no los toques": se usa cuando aún no se
  /// habían terminado de leer. Una lista vacía sí los borra.
  Future<void> editar(
    String id, {
    required String titulo,
    required DateTime inicio,
    String? descripcion,
    DateTime? fin,
    bool todoElDia = false,
    String? categoria,
    String importancia = 'normal',
    List<int>? recordatorios,
  }) async {
    await _repo.editar(
      id,
      titulo: titulo,
      inicio: inicio,
      descripcion: descripcion,
      fin: fin,
      todoElDia: todoElDia,
      categoria: categoria,
      importancia: importancia,
    );
    if (recordatorios != null) {
      await _repo.reemplazarRecordatorios(id, recordatorios);
    }
    _refrescar();
  }

  Future<void> cambiarEstado(String id, String estado) async {
    await _repo.cambiarEstado(id, estado);
    _refrescar();
  }

  Future<void> eliminar(String id) async {
    await _repo.eliminar(id);
    _refrescar();
  }

  Future<List<int>> recordatoriosDe(String eventId) =>
      _repo.recordatoriosDe(eventId);
}

final agendaAccionesProvider =
    Provider<AgendaAcciones>((ref) => AgendaAcciones(ref));
