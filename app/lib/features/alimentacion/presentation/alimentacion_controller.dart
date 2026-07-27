import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/alimentacion_repository.dart';
import '../domain/alimentacion.dart';
import '../domain/biblioteca_seed.dart';
import '../domain/motor.dart';

final alimentacionRepositoryProvider = Provider<AlimentacionRepository>(
  (ref) => AlimentacionRepository(ref.read(supabaseServiceProvider)),
);

/// La biblioteca aprobada (contenido curado), para resolver nombres en la UI.
final bibliotecaProvider = Provider<Biblioteca>((ref) => bibliotecaAprobada());

/// Perfiles con metas. Si aún no hay perfiles reales guardados, usa los
/// provisionales (metas aproximadas) para que el motor pueda trabajar.
final perfilesNutricionalesProvider =
    FutureProvider<List<PerfilNutricional>>((ref) async {
  ref.watch(usuarioActualProvider);
  final guardados = await ref.read(alimentacionRepositoryProvider).perfiles();
  final conMeta = guardados.where((p) => p.kcalObjetivo != null).toList();
  return conMeta.isNotEmpty ? conMeta : perfilesProvisionales();
});

/// Lunes de la semana que contiene [d].
DateTime lunesDe(DateTime d) {
  final soloDia = DateTime(d.year, d.month, d.day);
  return soloDia.subtract(Duration(days: soloDia.weekday - 1));
}

/// El plan de la semana actual, generado por el motor determinista.
final planSemanaProvider = FutureProvider<PlanSemana>((ref) async {
  final perfiles = await ref.watch(perfilesNutricionalesProvider.future);
  final biblioteca = bibliotecaAprobada();
  final inicio = lunesDe(DateTime.now());
  return const MotorNutricional().generar(
    perfiles: perfiles,
    biblioteca: biblioteca,
    inicioSemana: inicio,
  );
});
