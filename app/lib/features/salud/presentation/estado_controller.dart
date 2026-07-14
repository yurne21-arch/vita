import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/estado_repository.dart';

/// Expone el estado de hoy y permite registrar (rápido diario + peso).
class EstadoController extends AsyncNotifier<EstadoHoy> {
  @override
  Future<EstadoHoy> build() {
    ref.watch(usuarioActualProvider); // recarga si cambia la sesión
    return ref.read(estadoRepositoryProvider).estadoDeHoy();
  }

  Future<void> registrarDiario({
    int? energia,
    int? animo,
    int? suenoCalidad,
    double? suenoHoras,
  }) async {
    await ref.read(estadoRepositoryProvider).registrarDiario(
          energia: energia,
          animo: animo,
          suenoCalidad: suenoCalidad,
          suenoHoras: suenoHoras,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> registrarPeso(double peso) async {
    await ref.read(estadoRepositoryProvider).registrarPeso(peso);
    ref.invalidateSelf();
    await future;
  }
}

final estadoControllerProvider =
    AsyncNotifierProvider<EstadoController, EstadoHoy>(EstadoController.new);
