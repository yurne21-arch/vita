import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/habitos_repository.dart';

/// Carga los hábitos de hoy (sembrando los iniciales la primera vez)
/// y permite alternar su estado con respuesta inmediata en pantalla.
class HabitosController extends AsyncNotifier<List<Habito>> {
  @override
  Future<List<Habito>> build() async {
    ref.watch(usuarioActualProvider); // recarga si cambia la sesión
    final repo = ref.read(habitosRepositoryProvider);
    await repo.sembrarSiVacio();
    return repo.habitosDeHoy();
  }

  Future<void> alternar(Habito h) async {
    final repo = ref.read(habitosRepositoryProvider);
    final actuales = state.value ?? const <Habito>[];

    state = AsyncData([
      for (final x in actuales)
        if (x.id == h.id) x.copyWith(hecho: !x.hecho) else x,
    ]);

    try {
      await repo.alternar(h.id, h.hecho);
    } catch (_) {
      // Revertir en pantalla y avisar: un check que se desmarca solo, sin
      // explicación, hace que la usuaria deje de confiar en la app.
      ref.invalidateSelf();
      rethrow;
    }
  }
}

final habitosControllerProvider =
    AsyncNotifierProvider<HabitosController, List<Habito>>(
  HabitosController.new,
);
