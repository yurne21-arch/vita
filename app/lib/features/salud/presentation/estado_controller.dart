import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/estado_repository.dart';

/// Expone el estado de hoy y permite registrar nuevas métricas.
class EstadoController extends AsyncNotifier<EstadoHoy> {
  @override
  Future<EstadoHoy> build() {
    return ref.read(estadoRepositoryProvider).estadoDeHoy();
  }

  Future<void> registrar({
    double? peso,
    int? energia,
    double? sueno,
    int? animo,
  }) async {
    await ref.read(estadoRepositoryProvider).registrar(
          peso: peso,
          energia: energia,
          sueno: sueno,
          animo: animo,
        );
    ref.invalidateSelf();
    await future;
  }
}

final estadoControllerProvider =
    AsyncNotifierProvider<EstadoController, EstadoHoy>(EstadoController.new);
