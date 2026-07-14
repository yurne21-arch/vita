import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prioridades_repository.dart';

/// Prioridades de hoy con actualización inmediata en pantalla (optimista).
///
/// Si la escritura falla, se revierte el estado **y se relanza el error**: la
/// pantalla debe poder decirle a la usuaria qué pasó. Un cambio que se deshace
/// solo, sin explicación, es peor que un error visible.
class PrioridadesController extends AsyncNotifier<List<Prioridad>> {
  @override
  Future<List<Prioridad>> build() {
    return ref.read(prioridadesRepositoryProvider).prioridadesDeHoy();
  }

  PrioridadesRepository get _repo => ref.read(prioridadesRepositoryProvider);

  /// Revierte el estado optimista y relanza para que la UI lo muestre.
  Future<Never> _revertir(Object error) async {
    ref.invalidateSelf();
    throw error;
  }

  Future<void> agregar(String texto) async {
    await _repo.agregar(texto);
    ref.invalidateSelf();
    await future;
  }

  /// Mueve una prioridad arriba (delta -1) o abajo (delta +1) y persiste.
  Future<void> mover(int index, int delta) async {
    final actuales = [...(state.value ?? const <Prioridad>[])];
    final destino = index + delta;
    if (index < 0 || index >= actuales.length) return;
    if (destino < 0 || destino >= actuales.length) return;
    final item = actuales.removeAt(index);
    actuales.insert(destino, item);
    await reordenar(actuales);
  }

  Future<void> editarTexto(String id, String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;
    final actuales = state.value ?? const <Prioridad>[];
    state = AsyncData([
      for (final p in actuales)
        if (p.id == id) p.copyWith(texto: limpio) else p,
    ]);
    try {
      await _repo.editarTexto(id, limpio);
    } catch (e) {
      await _revertir(e);
    }
  }

  Future<void> alternar(Prioridad p) async {
    final actuales = state.value ?? const <Prioridad>[];
    state = AsyncData([
      for (final x in actuales)
        if (x.id == p.id) x.copyWith(completada: !x.completada) else x,
    ]);
    try {
      await _repo.alternarCompletada(p.id, p.completada);
    } catch (e) {
      await _revertir(e);
    }
  }

  Future<void> eliminar(String id) async {
    final actuales = state.value ?? const <Prioridad>[];
    state = AsyncData(actuales.where((p) => p.id != id).toList());
    try {
      await _repo.eliminar(id);
    } catch (e) {
      await _revertir(e);
    }
  }

  Future<void> reordenar(List<Prioridad> nuevo) async {
    final reordenadas = [
      for (var i = 0; i < nuevo.length; i++) nuevo[i].copyWith(orden: i + 1),
    ];
    state = AsyncData(reordenadas);
    try {
      await _repo.reordenar(reordenadas);
    } catch (e) {
      await _revertir(e);
    }
  }
}

final prioridadesControllerProvider =
    AsyncNotifierProvider<PrioridadesController, List<Prioridad>>(
  PrioridadesController.new,
);
