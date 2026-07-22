import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/remote/supabase_service.dart';
import '../../../core/providers.dart';

/// Error de dominio del módulo Proyectos, con mensaje claro para mostrar.
class ProjectsException implements Exception {
  ProjectsException(this.mensaje, [this.causa]);
  final String mensaje;
  final Object? causa;
  @override
  String toString() => mensaje;
}

// ╭──────────────────────────────────────────────────────────────╮
// │ Modelos                                                        │
// ╰──────────────────────────────────────────────────────────────╯

/// Un proyecto de la cartera. Editable. Solo uno puede ser principal.
class Project {
  const Project({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.objetivo,
    this.area,
    this.estado = 'activo',
    this.esPrincipal = false,
    this.fechaObjetivo,
    this.progresoManual,
    this.orden = 0,
    required this.createdAt,
    required this.updatedAt,
    this.completadoAt,
  });

  final String id;
  final String titulo;
  final String? descripcion; // el "por qué" / motivación
  final String? objetivo; // resultado buscado
  final String? area; // categoría (mismo vocabulario que Calendario)
  final String estado; // activo | pausado | completado | archivado
  final bool esPrincipal;
  final DateTime? fechaObjetivo; // date
  final int? progresoManual; // 0..100 respaldo si no hay pasos
  final int orden;
  final DateTime createdAt; // local
  final DateTime updatedAt; // local
  final DateTime? completadoAt; // local

  bool get activo => estado == 'activo';
  bool get pausado => estado == 'pausado';
  bool get completado => estado == 'completado';
  bool get archivado => estado == 'archivado';

  /// Progreso 0..100 derivado de los PASOS completados.
  /// Si el proyecto no tiene pasos, cae en `progresoManual` (o 0 si no hay).
  int progresoCon(List<ProjectTask> tareas) {
    final pasos = tareas.where((t) => t.esPaso).toList();
    if (pasos.isEmpty) return progresoManual ?? 0;
    final hechos = pasos.where((t) => t.completada).length;
    return ((hechos / pasos.length) * 100).round();
  }

  /// true si el proyecto tiene al menos un PASO creado (los hitos no cuentan).
  bool tienePasos(List<ProjectTask> tareas) => tareas.any((t) => t.esPaso);

  Project copyWith({
    String? titulo,
    String? descripcion,
    String? objetivo,
    String? area,
    String? estado,
    bool? esPrincipal,
    DateTime? fechaObjetivo,
    int? progresoManual,
    int? orden,
    DateTime? updatedAt,
    DateTime? completadoAt,
  }) =>
      Project(
        id: id,
        titulo: titulo ?? this.titulo,
        descripcion: descripcion ?? this.descripcion,
        objetivo: objetivo ?? this.objetivo,
        area: area ?? this.area,
        estado: estado ?? this.estado,
        esPrincipal: esPrincipal ?? this.esPrincipal,
        fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
        progresoManual: progresoManual ?? this.progresoManual,
        orden: orden ?? this.orden,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completadoAt: completadoAt ?? this.completadoAt,
      );

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id: m['id'] as String,
        titulo: m['titulo'] as String,
        descripcion: m['descripcion'] as String?,
        objetivo: m['objetivo'] as String?,
        area: m['area'] as String?,
        estado: (m['estado'] as String?) ?? 'activo',
        esPrincipal: (m['es_principal'] as bool?) ?? false,
        fechaObjetivo: m['fecha_objetivo'] != null
            ? DateTime.parse(m['fecha_objetivo'] as String)
            : null,
        progresoManual: (m['progreso_manual'] as num?)?.toInt(),
        orden: (m['orden'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
        completadoAt: m['completado_at'] != null
            ? DateTime.parse(m['completado_at'] as String).toLocal()
            : null,
      );
}

/// Un paso o hito dentro de un proyecto. Editable.
class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.texto,
    this.tipo = 'paso',
    this.completada = false,
    this.orden = 0,
    this.fechaObjetivo,
    this.fechaObjetivoOriginal,
    this.nota,
    this.monto,
    this.eventoId,
    required this.createdAt,
    this.completadaAt,
  });

  final String id;
  final String projectId;
  final String texto;
  final String tipo; // paso | hito
  final bool completada;
  final int orden;
  final DateTime? fechaObjetivo; // date (la vigente)
  final DateTime? fechaObjetivoOriginal; // date (la que se fijó al principio)
  final String? nota; // apunte libre del paso
  final double? monto; // costo del paso (opcional): alimenta el presupuesto
  final String? eventoId; // gancho Calendario (no cableado en V1)
  final DateTime createdAt; // local
  final DateTime? completadaAt; // local

  bool get esPaso => tipo == 'paso';
  bool get esHito => tipo == 'hito';

  /// La fecha se movió respecto a la original planificada.
  bool get fechaMovida =>
      fechaObjetivo != null &&
      fechaObjetivoOriginal != null &&
      !_mismoDia(fechaObjetivo!, fechaObjetivoOriginal!);

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  ProjectTask copyWith({
    String? texto,
    String? tipo,
    bool? completada,
    int? orden,
    DateTime? fechaObjetivo,
    DateTime? fechaObjetivoOriginal,
    String? nota,
    double? monto,
    String? eventoId,
    DateTime? completadaAt,
  }) =>
      ProjectTask(
        id: id,
        projectId: projectId,
        texto: texto ?? this.texto,
        tipo: tipo ?? this.tipo,
        completada: completada ?? this.completada,
        orden: orden ?? this.orden,
        fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
        fechaObjetivoOriginal:
            fechaObjetivoOriginal ?? this.fechaObjetivoOriginal,
        nota: nota ?? this.nota,
        monto: monto ?? this.monto,
        eventoId: eventoId ?? this.eventoId,
        createdAt: createdAt,
        completadaAt: completadaAt ?? this.completadaAt,
      );

  factory ProjectTask.fromMap(Map<String, dynamic> m) => ProjectTask(
        id: m['id'] as String,
        projectId: m['project_id'] as String,
        texto: m['texto'] as String,
        tipo: (m['tipo'] as String?) ?? 'paso',
        completada: (m['completada'] as bool?) ?? false,
        orden: (m['orden'] as num?)?.toInt() ?? 0,
        fechaObjetivo: m['fecha_objetivo'] != null
            ? DateTime.parse(m['fecha_objetivo'] as String)
            : null,
        fechaObjetivoOriginal: m['fecha_objetivo_original'] != null
            ? DateTime.parse(m['fecha_objetivo_original'] as String)
            : null,
        nota: m['nota'] as String?,
        monto: (m['monto'] as num?)?.toDouble(),
        eventoId: m['evento_id'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        completadaAt: m['completada_at'] != null
            ? DateTime.parse(m['completada_at'] as String).toLocal()
            : null,
      );
}

/// Una entrada de la bitácora. APPEND-ONLY: nunca se edita ni se borra.
class ProjectLogEntry {
  const ProjectLogEntry({
    required this.id,
    required this.projectId,
    this.taskId,
    required this.fecha,
    this.tipo = 'avance',
    this.texto,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String? taskId; // gancho opcional a un paso/hito
  final DateTime fecha; // local
  final String tipo; // creado | avance | nota | hito_completado | cambio_estado
  final String? texto;
  final DateTime createdAt; // local

  factory ProjectLogEntry.fromMap(Map<String, dynamic> m) => ProjectLogEntry(
        id: m['id'] as String,
        projectId: m['project_id'] as String,
        taskId: m['task_id'] as String?,
        fecha: DateTime.parse(m['fecha'] as String).toLocal(),
        tipo: (m['tipo'] as String?) ?? 'avance',
        texto: m['texto'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}

// ╭──────────────────────────────────────────────────────────────╮
// │ Repositorio                                                    │
// ╰──────────────────────────────────────────────────────────────╯

class ProjectsRepository {
  ProjectsRepository(this._service);
  final SupabaseService _service;
  SupabaseClient get _c => _service.client;

  static const _pCols =
      'id, titulo, descripcion, objetivo, area, estado, es_principal, '
      'fecha_objetivo, progreso_manual, orden, created_at, updated_at, completado_at';
  static const _tCols =
      'id, project_id, texto, tipo, completada, orden, fecha_objetivo, '
      'fecha_objetivo_original, nota, monto, evento_id, created_at, completada_at';
  static const _lCols =
      'id, project_id, task_id, fecha, tipo, texto, created_at';

  // ---- helpers ----

  String? _limpio(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();

  String? _fechaSolo(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _userId() {
    final u = _c.auth.currentUser;
    if (u == null) {
      throw ProjectsException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    return u.id;
  }

  Future<T> _guard<T>(String accion, Future<T> Function() fn) async {
    try {
      return await fn();
    } on ProjectsException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProjectsException('No se pudo $accion. ${e.message}', e);
    } catch (e) {
      throw ProjectsException('No se pudo $accion.', e);
    }
  }

  // ════════════════════ PROJECTS ════════════════════

  /// Crea un proyecto y devuelve su id. El estado nace como 'activo'.
  Future<String> crearProyecto({
    required String titulo,
    String? descripcion,
    String? objetivo,
    String? area,
    DateTime? fechaObjetivo,
    int? progresoManual,
    bool esPrincipal = false,
  }) async {
    final uid = _userId();
    return _guard('crear el proyecto', () async {
      final row = await _c
          .from('projects')
          .insert({
            'user_id': uid,
            'titulo': titulo.trim(),
            'descripcion': _limpio(descripcion),
            'objetivo': _limpio(objetivo),
            'area': _limpio(area),
            'fecha_objetivo': _fechaSolo(fechaObjetivo),
            'progreso_manual': progresoManual,
            'es_principal': esPrincipal,
          })
          .select('id')
          .single();
      return row['id'] as String;
    });
  }

  /// Edita los campos editables del proyecto (no toca estado ni principal).
  ///
  /// No escribe `progreso_manual`: el editor nunca lo envía, así que incluirlo
  /// en el update lo ponía en NULL en cada edición. Se conserva tal como esté.
  Future<void> editarProyecto(
    String id, {
    required String titulo,
    String? descripcion,
    String? objetivo,
    String? area,
    DateTime? fechaObjetivo,
  }) =>
      _guard('guardar el proyecto', () async {
        await _c.from('projects').update({
          'titulo': titulo.trim(),
          'descripcion': _limpio(descripcion),
          'objetivo': _limpio(objetivo),
          'area': _limpio(area),
          'fecha_objetivo': _fechaSolo(fechaObjetivo),
        }).eq('id', id);
      });

  /// Pausa el proyecto. El trigger le quita la marca de principal si la tenía.
  Future<void> pausarProyecto(String id) =>
      _guard('pausar el proyecto', () async {
        await _c.from('projects').update({'estado': 'pausado'}).eq('id', id);
      });

  /// Marca el proyecto como completado. El trigger estampa `completado_at`.
  Future<void> completarProyecto(String id) =>
      _guard('completar el proyecto', () async {
        await _c.from('projects').update({'estado': 'completado'}).eq('id', id);
      });

  /// Archiva el proyecto (sale de la vista principal de la cartera).
  Future<void> archivarProyecto(String id) =>
      _guard('archivar el proyecto', () async {
        await _c.from('projects').update({'estado': 'archivado'}).eq('id', id);
      });

  /// Marca este proyecto como principal (y lo reactiva). El trigger desmarca
  /// automáticamente al principal anterior: solo uno puede serlo.
  Future<void> marcarComoPrincipal(String id) =>
      _guard('marcar como principal', () async {
        await _c
            .from('projects')
            .update({'estado': 'activo', 'es_principal': true}).eq('id', id);
      });

  /// El único proyecto principal de la usuaria, o null si no hay.
  Future<Project?> obtenerProyectoPrincipal() async {
    final u = _c.auth.currentUser;
    if (u == null) return null;
    return _guard('cargar el proyecto principal', () async {
      final row = await _c
          .from('projects')
          .select(_pCols)
          .eq('user_id', u.id)
          .eq('es_principal', true)
          .maybeSingle();
      return row == null ? null : Project.fromMap(row);
    });
  }

  Future<List<Project>> listarActivos() => _listar(['activo']);

  Future<List<Project>> listarPausados() => _listar(['pausado']);

  Future<List<Project>> listarCompletadosArchivados() =>
      _listar(['completado', 'archivado'], porCompletado: true);

  Future<List<Project>> _listar(List<String> estados,
      {bool porCompletado = false}) async {
    final u = _c.auth.currentUser;
    if (u == null) return [];
    return _guard('cargar los proyectos', () async {
      final List rows;
      if (porCompletado) {
        rows = await _c
            .from('projects')
            .select(_pCols)
            .eq('user_id', u.id)
            .inFilter('estado', estados)
            .order('completado_at', ascending: false)
            .order('updated_at', ascending: false);
      } else {
        // Orden por fecha objetivo (lo más próximo primero); los que no tienen
        // fecha quedan al final. Desempate por creación.
        rows = await _c
            .from('projects')
            .select(_pCols)
            .eq('user_id', u.id)
            .inFilter('estado', estados)
            .order('fecha_objetivo', ascending: true, nullsFirst: false)
            .order('created_at');
      }
      return rows
          .map((m) => Project.fromMap(m as Map<String, dynamic>))
          .toList();
    });
  }

  /// Elimina un proyecto. ⚠️ Borrado en cascada: arrastra sus pasos/hitos y
  /// TODA su bitácora. Para perder solo de la vista, prefiere archivarProyecto.
  Future<void> eliminarProyecto(String id) =>
      _guard('eliminar el proyecto', () async {
        await _c.from('projects').delete().eq('id', id);
      });

  // ════════════════════ PROJECT_TASKS ════════════════════

  Future<int> _siguienteOrden(String projectId) async {
    final rows = await _c
        .from('project_tasks')
        .select('orden')
        .eq('project_id', projectId)
        .order('orden', ascending: false)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return 0;
    return ((list.first['orden'] as num).toInt()) + 1;
  }

  Future<String> crearPaso(String projectId, String texto,
          {DateTime? fechaObjetivo, String? nota, double? monto}) =>
      _crearTarea(projectId, texto, 'paso', fechaObjetivo, nota, monto);

  Future<String> crearHito(String projectId, String texto,
          {DateTime? fechaObjetivo, String? nota, double? monto}) =>
      _crearTarea(projectId, texto, 'hito', fechaObjetivo, nota, monto);

  Future<String> _crearTarea(String projectId, String texto, String tipo,
      DateTime? fechaObjetivo, String? nota, double? monto) {
    final uid = _userId();
    final etiqueta = tipo == 'hito' ? 'el hito' : 'el paso';
    return _guard('crear $etiqueta', () async {
      final orden = await _siguienteOrden(projectId);
      final fecha = _fechaSolo(fechaObjetivo);
      final row = await _c
          .from('project_tasks')
          .insert({
            'project_id': projectId,
            'user_id': uid,
            'texto': texto.trim(),
            'tipo': tipo,
            'orden': orden,
            'fecha_objetivo': fecha,
            // La fecha original nace igual a la primera fecha fijada.
            'fecha_objetivo_original': fecha,
            'nota': _limpio(nota),
            'monto': monto,
          })
          .select('id')
          .single();
      return row['id'] as String;
    });
  }

  /// Edita un paso/hito. Pasa el estado completo deseado (texto, tipo, fecha,
  /// nota); `tipo` permite convertir un paso en hito o viceversa.
  ///
  /// Si el paso nunca tuvo fecha original y ahora se le fija una, esa queda como
  /// la planificada. La fecha original **nunca** se reescribe: es la referencia
  /// para ver si la fecha se movió.
  Future<void> editarTarea(
    String id, {
    required String texto,
    required String tipo,
    DateTime? fechaObjetivo,
    String? nota,
    double? monto,
  }) =>
      _guard('guardar la tarea', () async {
        final fecha = _fechaSolo(fechaObjetivo);
        final datos = <String, dynamic>{
          'texto': texto.trim(),
          'tipo': tipo,
          'fecha_objetivo': fecha,
          'nota': _limpio(nota),
          'monto': monto,
        };
        // Fija la fecha original solo si aún no existe y ahora hay una fecha.
        if (fecha != null) {
          final actual = await _c
              .from('project_tasks')
              .select('fecha_objetivo_original')
              .eq('id', id)
              .maybeSingle();
          if (actual != null && actual['fecha_objetivo_original'] == null) {
            datos['fecha_objetivo_original'] = fecha;
          }
        }
        await _c.from('project_tasks').update(datos).eq('id', id);
      });

  /// Anota en la bitácora que se movió la fecha de un paso (append-only).
  Future<void> registrarFechaMovida(String projectId,
          {String? texto, String? taskId}) =>
      _log(projectId, 'fecha_movida', texto: texto, taskId: taskId);

  /// Marca completada (el trigger estampa `completada_at`).
  Future<void> completarTarea(String id) =>
      _guard('completar la tarea', () async {
        await _c
            .from('project_tasks')
            .update({'completada': true}).eq('id', id);
      });

  /// Reabre (el trigger limpia `completada_at`).
  Future<void> reabrirTarea(String id) =>
      _guard('reabrir la tarea', () async {
        await _c
            .from('project_tasks')
            .update({'completada': false}).eq('id', id);
      });

  Future<void> eliminarTarea(String id) =>
      _guard('eliminar la tarea', () async {
        await _c.from('project_tasks').delete().eq('id', id);
      });

  Future<List<ProjectTask>> listarTareasPorProyecto(String projectId) =>
      _guard('cargar las tareas', () async {
        final rows = await _c
            .from('project_tasks')
            .select(_tCols)
            .eq('project_id', projectId)
            .order('orden')
            .order('created_at');
        return (rows as List)
            .map((m) => ProjectTask.fromMap(m as Map<String, dynamic>))
            .toList();
      });

  /// Sube una tarea una posición (intercambia orden con la anterior).
  Future<void> subirTarea(String id) => _moverTarea(id, -1);

  /// Baja una tarea una posición (intercambia orden con la siguiente).
  Future<void> bajarTarea(String id) => _moverTarea(id, 1);

  Future<void> _moverTarea(String id, int dir) =>
      _guard('reordenar la tarea', () async {
        final actual = await _c
            .from('project_tasks')
            .select('id, project_id, orden')
            .eq('id', id)
            .maybeSingle();
        if (actual == null) return;
        final projectId = actual['project_id'] as String;
        final rows = await _c
            .from('project_tasks')
            .select('id, orden')
            .eq('project_id', projectId)
            .order('orden')
            .order('created_at');
        final lista = (rows as List).cast<Map<String, dynamic>>();
        final idx = lista.indexWhere((r) => r['id'] == id);
        final swap = idx + dir;
        if (idx < 0 || swap < 0 || swap >= lista.length) return;
        final a = lista[idx];
        final b = lista[swap];
        final ordenA = (a['orden'] as num).toInt();
        final ordenB = (b['orden'] as num).toInt();
        // Si el orden quedó duplicado, desempata por posición.
        final nuevoA = ordenA == ordenB ? swap : ordenB;
        final nuevoB = ordenA == ordenB ? idx : ordenA;
        await _c
            .from('project_tasks')
            .update({'orden': nuevoA}).eq('id', a['id'] as String);
        await _c
            .from('project_tasks')
            .update({'orden': nuevoB}).eq('id', b['id'] as String);
      });

  /// Primer PASO pendiente por orden, o null si no quedan.
  Future<ProjectTask?> obtenerProximoPasoPendiente(String projectId) =>
      _guard('cargar el próximo paso', () async {
        final rows = await _c
            .from('project_tasks')
            .select(_tCols)
            .eq('project_id', projectId)
            .eq('tipo', 'paso')
            .eq('completada', false)
            .order('orden')
            .order('created_at')
            .limit(1);
        final list = rows as List;
        return list.isEmpty
            ? null
            : ProjectTask.fromMap(list.first as Map<String, dynamic>);
      });

  // ════════════════════ PROJECT_LOG (append-only) ════════════════════

  Future<void> registrarAvance(String projectId,
          {String? texto, String? taskId}) =>
      _log(projectId, 'avance', texto: texto, taskId: taskId);

  Future<void> registrarNota(String projectId,
          {String? texto, String? taskId}) =>
      _log(projectId, 'nota', texto: texto, taskId: taskId);

  Future<void> registrarHitoCompletado(String projectId,
          {String? texto, String? taskId}) =>
      _log(projectId, 'hito_completado', texto: texto, taskId: taskId);

  Future<void> registrarCambioEstado(String projectId,
          {String? texto, String? taskId}) =>
      _log(projectId, 'cambio_estado', texto: texto, taskId: taskId);

  /// Entrada 'creado' (primitiva de bajo nivel; la usa el controlador al crear).
  Future<void> registrarCreado(String projectId,
          {String? texto, String? taskId}) =>
      _log(projectId, 'creado', texto: texto, taskId: taskId);

  Future<void> _log(String projectId, String tipo,
      {String? texto, String? taskId}) {
    final uid = _userId();
    return _guard('registrar en la bitácora', () async {
      await _c.from('project_log').insert({
        'project_id': projectId,
        'user_id': uid,
        'task_id': taskId,
        'tipo': tipo,
        'texto': _limpio(texto),
      });
    });
  }

  /// Bitácora del proyecto, de la más reciente a la más antigua.
  Future<List<ProjectLogEntry>> listarBitacora(String projectId) =>
      _guard('cargar la bitácora', () async {
        final rows = await _c
            .from('project_log')
            .select(_lCols)
            .eq('project_id', projectId)
            .order('fecha', ascending: false);
        return (rows as List)
            .map((m) => ProjectLogEntry.fromMap(m as Map<String, dynamic>))
            .toList();
      });
}

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => ProjectsRepository(ref.read(supabaseServiceProvider)),
);
