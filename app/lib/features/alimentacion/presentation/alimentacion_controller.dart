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

/// Lunes de inicio de la quincena que contiene [d]. Rejilla estable de 14 días
/// anclada al lunes 2024-01-01, para que dos semanas seguidas caigan en la
/// misma quincena (la compra es quincenal, no semanal).
DateTime quincenaDe(DateTime d) {
  final lun = lunesDe(d);
  final ref = DateTime(2024, 1, 1); // lunes de referencia
  final semanas = lun.difference(ref).inDays ~/ 7;
  return ref.add(Duration(days: (semanas ~/ 2) * 14));
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

/// Las compras registradas de la usuaria (viajes al súper, con su gasto en
/// Finanzas). Se puede registrar cuantas se quiera (varios supermercados).
final comprasProvider = FutureProvider<List<Compra>>((ref) async {
  ref.watch(usuarioActualProvider);
  return ref.read(alimentacionRepositoryProvider).compras();
});

/// Estados de comida de la semana actual (comí / no comí / cambiada), indexados
/// por `fecha|momento`. Los fija la usuaria desde Menú, Hoy o Mi Vida.
final estadosComidaProvider =
    FutureProvider<Map<String, EstadoComida>>((ref) async {
  ref.watch(usuarioActualProvider);
  final inicio = lunesDe(DateTime.now());
  final fin = inicio.add(const Duration(days: 6));
  final list =
      await ref.read(alimentacionRepositoryProvider).estadosComida(inicio, fin);
  return {for (final e in list) e.clave: e};
});

/// La sesión de cocción de la semana actual (si ya cocinó y cuándo).
final cocinaSesionProvider = FutureProvider<CocinaSesion?>((ref) async {
  ref.watch(usuarioActualProvider);
  final inicio = lunesDe(DateTime.now());
  return ref.read(alimentacionRepositoryProvider).cocinaSesion(inicio);
});

/// La lista de compra de la QUINCENA actual, persistida y con estado por ítem.
/// Se siembra sumando lo que piden las dos semanas del plan (la compra es
/// quincenal); después conserva lo que la usuaria va marcando. Cada quincena
/// nueva genera su propia lista según lo que se consume (huevos, frescos, etc.).
final listaComprasProvider = FutureProvider<List<CompraItem>>((ref) async {
  ref.watch(usuarioActualProvider);
  final perfiles = await ref.watch(perfilesNutricionalesProvider.future);
  final biblioteca = bibliotecaAprobada();
  final inicio = quincenaDe(DateTime.now());
  final fin = inicio.add(const Duration(days: 13));

  const motor = MotorNutricional();
  final semana1 = motor.generar(
      perfiles: perfiles, biblioteca: biblioteca, inicioSemana: inicio);
  final semana2 = motor.generar(
      perfiles: perfiles,
      biblioteca: biblioteca,
      inicioSemana: inicio.add(const Duration(days: 7)),
      rotacion: 1);

  // Suma las cantidades de las dos semanas por (nombre, unidad).
  final acum = <String,
      ({String nombre, String? categoria, double cantidad, String? unidad})>{};
  for (final plan in [semana1, semana2]) {
    for (final it in [...plan.compras.principal, ...plan.compras.reposicion]) {
      final clave = '${it.nombre}|${it.unidad}';
      final prev = acum[clave];
      acum[clave] = (
        nombre: it.nombre,
        categoria: it.categoria,
        cantidad: (prev?.cantidad ?? 0) + it.cantidad,
        unidad: it.unidad,
      );
    }
  }
  final semilla = [
    for (final v in acum.values)
      (
        nombre: v.nombre,
        categoria: v.categoria,
        cantidad: v.cantidad as double?,
        unidad: v.unidad,
      ),
  ];

  return ref
      .read(alimentacionRepositoryProvider)
      .asegurarLista(inicio: inicio, fin: fin, semilla: semilla);
});
