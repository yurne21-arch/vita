import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/projects_repository.dart';

// ╭──────────────────────────────────────────────────────────────╮
// │ Lecturas — cada provider entrega AsyncValue (loading/error/    │
// │ data). Las acciones invalidan lo que corresponda.              │
// │                                                                │
// │ Todos observan `usuarioActualProvider`: al cambiar de sesión,  │
// │ se recargan en vez de mostrarle a la nueva usuaria los datos   │
// │ cacheados de la anterior.                                      │
// ╰──────────────────────────────────────────────────────────────╯

/// El único proyecto principal de la usuaria (o null).
final proyectoPrincipalProvider = FutureProvider<Project?>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(projectsRepositoryProvider).obtenerProyectoPrincipal();
});

/// Cartera: proyectos por estado.
final proyectosActivosProvider = FutureProvider<List<Project>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(projectsRepositoryProvider).listarActivos();
});

final proyectosPausadosProvider = FutureProvider<List<Project>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(projectsRepositoryProvider).listarPausados();
});

final proyectosCompletadosProvider = FutureProvider<List<Project>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(projectsRepositoryProvider).listarCompletadosArchivados();
});

/// Tareas (pasos + hitos) de un proyecto, por id.
final tareasDeProyectoProvider =
    FutureProvider.family<List<ProjectTask>, String>(
  (ref, id) =>
      ref.watch(projectsRepositoryProvider).listarTareasPorProyecto(id),
);

/// Bitácora de un proyecto, por id (más reciente primero).
final bitacoraDeProyectoProvider =
    FutureProvider.family<List<ProjectLogEntry>, String>(
  (ref, id) => ref.watch(projectsRepositoryProvider).listarBitacora(id),
);

/// Próximo paso pendiente de un proyecto, por id.
final proximoPasoProvider = FutureProvider.family<ProjectTask?, String>(
  (ref, id) =>
      ref.watch(projectsRepositoryProvider).obtenerProximoPasoPendiente(id),
);

/// Metas disponibles para vincular a un proyecto (de Finanzas).
final metasVinculablesProvider = FutureProvider<List<MetaRef>>((ref) {
  ref.watch(usuarioActualProvider);
  return ref.watch(projectsRepositoryProvider).metasParaVincular();
});

/// Progreso 0..100 derivado de los PASOS completados. 0 si no hay pasos.
/// (Para el respaldo con `progresoManual` cuando no hay pasos, usar
/// `Project.progresoCon(tareas)` desde donde se tenga el Project.)
final progresoDeProyectoProvider = FutureProvider.family<int, String>(
  (ref, id) async {
    final tareas = await ref.watch(tareasDeProyectoProvider(id).future);
    final pasos = tareas.where((t) => t.esPaso).toList();
    if (pasos.isEmpty) return 0;
    final hechos = pasos.where((t) => t.completada).length;
    return ((hechos / pasos.length) * 100).round();
  },
);

// ── Proyecto seleccionado (lo fija la UI al abrir un detalle) ──

final proyectoSeleccionadoIdProvider = StateProvider<String?>((ref) => null);

final tareasSeleccionadoProvider =
    Provider<AsyncValue<List<ProjectTask>>>((ref) {
  final id = ref.watch(proyectoSeleccionadoIdProvider);
  if (id == null) return const AsyncData<List<ProjectTask>>([]);
  return ref.watch(tareasDeProyectoProvider(id));
});

final bitacoraSeleccionadoProvider =
    Provider<AsyncValue<List<ProjectLogEntry>>>((ref) {
  final id = ref.watch(proyectoSeleccionadoIdProvider);
  if (id == null) return const AsyncData<List<ProjectLogEntry>>([]);
  return ref.watch(bitacoraDeProyectoProvider(id));
});

final proximoPasoSeleccionadoProvider =
    Provider<AsyncValue<ProjectTask?>>((ref) {
  final id = ref.watch(proyectoSeleccionadoIdProvider);
  if (id == null) return const AsyncData<ProjectTask?>(null);
  return ref.watch(proximoPasoProvider(id));
});

final progresoSeleccionadoProvider = Provider<AsyncValue<int>>((ref) {
  final id = ref.watch(proyectoSeleccionadoIdProvider);
  if (id == null) return const AsyncData<int>(0);
  return ref.watch(progresoDeProyectoProvider(id));
});

// ╭──────────────────────────────────────────────────────────────╮
// │ Acciones — componen repo + bitácora automática + invalidación. │
// │ El "cuándo registrar" vive aquí (no en el repositorio).        │
// ╰──────────────────────────────────────────────────────────────╯

class ProyectosAcciones {
  ProyectosAcciones(this._ref);
  final Ref _ref;

  ProjectsRepository get _repo => _ref.read(projectsRepositoryProvider);

  void _refrescarCartera() {
    _ref.invalidate(proyectoPrincipalProvider);
    _ref.invalidate(proyectosActivosProvider);
    _ref.invalidate(proyectosPausadosProvider);
    _ref.invalidate(proyectosCompletadosProvider);
  }

  void _refrescarProyecto(String projectId) {
    _ref.invalidate(tareasDeProyectoProvider(projectId));
    _ref.invalidate(bitacoraDeProyectoProvider(projectId));
    _ref.invalidate(proximoPasoProvider(projectId));
    _ref.invalidate(progresoDeProyectoProvider(projectId));
    // Por si es el principal: refresca su progreso/próximo paso en Mi Vida.
    _ref.invalidate(proyectoPrincipalProvider);
  }

  // ───────────────── Proyectos ─────────────────

  /// Crea el proyecto y registra automáticamente la entrada 'creado'.
  Future<String> crearProyecto({
    required String titulo,
    String? descripcion,
    String? objetivo,
    String? area,
    DateTime? fechaObjetivo,
    int? progresoManual,
    String? metaId,
    bool esPrincipal = false,
  }) async {
    final id = await _repo.crearProyecto(
      titulo: titulo,
      descripcion: descripcion,
      objetivo: objetivo,
      area: area,
      fechaObjetivo: fechaObjetivo,
      progresoManual: progresoManual,
      metaId: metaId,
      esPrincipal: esPrincipal,
    );
    await _repo.registrarCreado(id, texto: 'Proyecto creado'); // bitácora auto
    _refrescarCartera();
    return id;
  }

  Future<void> editarProyecto(
    String id, {
    required String titulo,
    String? descripcion,
    String? objetivo,
    String? area,
    DateTime? fechaObjetivo,
    String? metaId,
  }) async {
    await _repo.editarProyecto(
      id,
      titulo: titulo,
      descripcion: descripcion,
      objetivo: objetivo,
      area: area,
      fechaObjetivo: fechaObjetivo,
      metaId: metaId,
    );
    _refrescarCartera();
    _refrescarProyecto(id);
  }

  /// Pausa y registra 'cambio_estado'.
  Future<void> pausarProyecto(String id) async {
    await _repo.pausarProyecto(id);
    await _repo.registrarCambioEstado(id, texto: 'Proyecto pausado');
    _refrescarCartera();
    _refrescarProyecto(id);
  }

  /// Completa y registra 'cambio_estado'.
  Future<void> completarProyecto(String id) async {
    await _repo.completarProyecto(id);
    await _repo.registrarCambioEstado(id, texto: 'Proyecto completado');
    _refrescarCartera();
    _refrescarProyecto(id);
  }

  /// Archiva y registra 'cambio_estado'.
  Future<void> archivarProyecto(String id) async {
    await _repo.archivarProyecto(id);
    await _repo.registrarCambioEstado(id, texto: 'Proyecto archivado');
    _refrescarCartera();
    _refrescarProyecto(id);
  }

  /// Lo vuelve principal (y lo reactiva). El trigger desmarca al anterior.
  Future<void> marcarComoPrincipal(String id) async {
    await _repo.marcarComoPrincipal(id);
    _refrescarCartera();
    _refrescarProyecto(id);
  }

  /// ⚠️ Borrado en cascada (pasos + bitácora). Limpia la selección si aplica.
  Future<void> eliminarProyecto(String id) async {
    await _repo.eliminarProyecto(id);
    if (_ref.read(proyectoSeleccionadoIdProvider) == id) {
      _ref.read(proyectoSeleccionadoIdProvider.notifier).state = null;
    }
    _refrescarCartera();
  }

  // ───────────────── Pasos / Hitos ─────────────────

  Future<String> crearPaso(String projectId, String texto,
      {DateTime? fechaObjetivo, String? nota, double? monto}) async {
    final id = await _repo.crearPaso(projectId, texto,
        fechaObjetivo: fechaObjetivo, nota: nota, monto: monto);
    _refrescarProyecto(projectId);
    return id;
  }

  Future<String> crearHito(String projectId, String texto,
      {DateTime? fechaObjetivo, String? nota, double? monto}) async {
    final id = await _repo.crearHito(projectId, texto,
        fechaObjetivo: fechaObjetivo, nota: nota, monto: monto);
    _refrescarProyecto(projectId);
    return id;
  }

  Future<void> editarTarea(
    ProjectTask tarea, {
    required String texto,
    required String tipo,
    DateTime? fechaObjetivo,
    String? nota,
    double? monto,
    String? motivoFecha,
  }) async {
    await _repo.editarTarea(tarea.id,
        texto: texto,
        tipo: tipo,
        fechaObjetivo: fechaObjetivo,
        nota: nota,
        monto: monto);
    // Si la fecha se movió, queda registro en la bitácora (sin culpa: solo el
    // hecho —y el motivo si lo dio— para ver lo planificado vs lo real).
    if (!_mismaFecha(tarea.fechaObjetivo, fechaObjetivo)) {
      final motivo = motivoFecha?.trim();
      await _repo.registrarFechaMovida(
        tarea.projectId,
        taskId: tarea.id,
        texto: 'Fecha de «${tarea.texto}»: '
            '${_fmtFecha(tarea.fechaObjetivo)} → ${_fmtFecha(fechaObjetivo)}'
            '${(motivo != null && motivo.isNotEmpty) ? ' — $motivo' : ''}',
      );
    }
    _refrescarProyecto(tarea.projectId);
  }

  static bool _mismaFecha(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _fmtFecha(DateTime? d) =>
      d == null ? 'sin fecha' : '${d.day}/${d.month}/${d.year}';

  /// Completa un paso/hito y registra en bitácora:
  /// hito → 'hito_completado'; paso → 'avance'.
  Future<void> completarTarea(ProjectTask tarea) async {
    await _repo.completarTarea(tarea.id);
    if (tarea.esHito) {
      await _repo.registrarHitoCompletado(tarea.projectId,
          texto: tarea.texto, taskId: tarea.id);
    } else {
      await _repo.registrarAvance(tarea.projectId,
          texto: 'Paso completado: ${tarea.texto}', taskId: tarea.id);
    }
    _refrescarProyecto(tarea.projectId);
  }

  /// Reabre (sin registrar en bitácora).
  Future<void> reabrirTarea(ProjectTask tarea) async {
    await _repo.reabrirTarea(tarea.id);
    _refrescarProyecto(tarea.projectId);
  }

  Future<void> eliminarTarea(ProjectTask tarea) async {
    await _repo.eliminarTarea(tarea.id);
    _refrescarProyecto(tarea.projectId);
  }

  Future<void> subirTarea(ProjectTask tarea) async {
    await _repo.subirTarea(tarea.id);
    _refrescarProyecto(tarea.projectId);
  }

  Future<void> bajarTarea(ProjectTask tarea) async {
    await _repo.bajarTarea(tarea.id);
    _refrescarProyecto(tarea.projectId);
  }

  // ───────────────── Avances / notas rápidas ─────────────────

  /// Avance rápido manual → registra 'avance'.
  Future<void> avanceRapido(String projectId, {String? texto}) async {
    await _repo.registrarAvance(projectId, texto: texto);
    _refrescarProyecto(projectId);
  }

  /// Nota rápida → registra 'nota'.
  Future<void> notaRapida(String projectId, {String? texto}) async {
    await _repo.registrarNota(projectId, texto: texto);
    _refrescarProyecto(projectId);
  }

  /// Botón "Avanzar" de Mi Vida: completa el próximo paso pendiente (que ya
  /// registra 'avance'); si no quedan pasos, registra un avance simple.
  Future<void> avanzar(String projectId) async {
    final paso = await _repo.obtenerProximoPasoPendiente(projectId);
    if (paso != null) {
      await completarTarea(paso);
    } else {
      await _repo.registrarAvance(projectId, texto: 'Avance registrado');
      _refrescarProyecto(projectId);
    }
  }
}

final proyectosAccionesProvider =
    Provider<ProyectosAcciones>((ref) => ProyectosAcciones(ref));
