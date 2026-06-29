import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/agenda_repository.dart';

/// Fuente única: los eventos de los próximos 7 días (incluye hoy).
/// Mi Vida ("Tu Día") filtra los de hoy; Calendario muestra los 7 días.
class AgendaController extends AsyncNotifier<List<Evento>> {
  @override
  Future<List<Evento>> build() {
    return ref.read(agendaRepositoryProvider).eventosSemana();
  }

  AgendaRepository get _repo => ref.read(agendaRepositoryProvider);

  Future<void> crear({
    required String titulo,
    required DateTime inicio,
    String? descripcion,
    DateTime? fin,
    bool todoElDia = false,
    String? categoria,
  }) async {
    await _repo.crear(
      titulo: titulo,
      inicio: inicio,
      descripcion: descripcion,
      fin: fin,
      todoElDia: todoElDia,
      categoria: categoria,
    );
    ref.invalidateSelf();
    await future;
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
    await _repo.editar(
      id,
      titulo: titulo,
      inicio: inicio,
      descripcion: descripcion,
      fin: fin,
      todoElDia: todoElDia,
      categoria: categoria,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> cambiarEstado(String id, String estado) async {
    final actuales = state.value ?? const <Evento>[];
    state = AsyncData([
      for (final e in actuales)
        if (e.id == id) e.copyWith(estado: estado) else e,
    ]);
    try {
      await _repo.cambiarEstado(id, estado);
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> eliminar(String id) async {
    final actuales = state.value ?? const <Evento>[];
    state = AsyncData(actuales.where((e) => e.id != id).toList());
    try {
      await _repo.eliminar(id);
    } catch (_) {
      ref.invalidateSelf();
    }
  }
}

final agendaControllerProvider =
    AsyncNotifierProvider<AgendaController, List<Evento>>(AgendaController.new);
