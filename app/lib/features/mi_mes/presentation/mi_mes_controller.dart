import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/mi_mes_repository.dart';
import '../domain/mi_mes.dart';

DateTime _mesActual() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, 1);
}

/// Mes que se está viendo (primer día del mes). Arranca en el mes actual.
final mesSeleccionadoProvider = StateProvider<DateTime>((ref) => _mesActual());

/// Meses con algo registrado (para el selector).
final mesesConDatosProvider = FutureProvider<List<DateTime>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(miMesRepositoryProvider).mesesConDatos();
});

/// Balance (espejo) del mes seleccionado.
final balanceMesProvider = FutureProvider<BalanceMes>((ref) {
  ref.watch(usuarioActualProvider);
  final mes = ref.watch(mesSeleccionadoProvider);
  return ref.watch(miMesRepositoryProvider).balanceDelMes(mes);
});

/// Reflexión escrita por la usuaria para el mes seleccionado (o null).
final reflexionMesProvider = FutureProvider<ReflexionMes?>((ref) {
  ref.watch(usuarioActualProvider);
  final mes = ref.watch(mesSeleccionadoProvider);
  return ref.watch(miMesRepositoryProvider).reflexionDelMes(mes);
});

class MiMesAcciones {
  MiMesAcciones(this._ref);
  final Ref _ref;

  Future<void> guardarReflexion({
    String? salioBien,
    String? aMejorar,
    String? foco,
  }) async {
    final mes = _ref.read(mesSeleccionadoProvider);
    await _ref.read(miMesRepositoryProvider).guardarReflexion(
          mes,
          salioBien: salioBien,
          aMejorar: aMejorar,
          foco: foco,
        );
    _ref.invalidate(reflexionMesProvider);
  }
}

final miMesAccionesProvider =
    Provider<MiMesAcciones>((ref) => MiMesAcciones(ref));
