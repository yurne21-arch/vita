import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/projects_repository.dart';
import 'projects_controller.dart';
import 'proyecto_editores.dart';
import 'proyectos_widgets.dart';

class ProyectoDetalleScreen extends ConsumerStatefulWidget {
  const ProyectoDetalleScreen({required this.proyecto, super.key});
  final Project proyecto;

  @override
  ConsumerState<ProyectoDetalleScreen> createState() =>
      _ProyectoDetalleScreenState();
}

class _ProyectoDetalleScreenState
    extends ConsumerState<ProyectoDetalleScreen> {
  late Project _p;

  @override
  void initState() {
    super.initState();
    _p = widget.proyecto;
  }

  ProyectosAcciones get _acc => ref.read(proyectosAccionesProvider);

  Future<void> _editar() async {
    final r = await mostrarEditorProyecto(context, ref, existente: _p);
    if (r is Project && mounted) setState(() => _p = r);
  }

  Future<void> _cambioEstado(String op) async {
    switch (op) {
      case 'principal':
        await _acc.marcarComoPrincipal(_p.id);
        if (mounted) {
          setState(() => _p = _p.copyWith(estado: 'activo', esPrincipal: true));
        }
        break;
      case 'pausar':
        await _acc.pausarProyecto(_p.id);
        if (mounted) {
          setState(
              () => _p = _p.copyWith(estado: 'pausado', esPrincipal: false));
        }
        break;
      case 'completar':
        await _acc.completarProyecto(_p.id);
        if (mounted) {
          setState(() => _p = _p.copyWith(
              estado: 'completado',
              esPrincipal: false,
              completadoAt: DateTime.now()));
        }
        break;
      case 'archivar':
        await _acc.archivarProyecto(_p.id);
        if (mounted) {
          setState(
              () => _p = _p.copyWith(estado: 'archivado', esPrincipal: false));
        }
        break;
    }
  }

  Future<void> _eliminar() async {
    final ok = await _confirmar(
      context,
      'Eliminar proyecto',
      'Se borrará el proyecto junto con todos sus pasos, hitos y su bitácora. '
          'Esta acción no se puede deshacer. ¿Continuar?',
      'Eliminar',
    );
    if (ok != true) return;
    await _acc.eliminarProyecto(_p.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surface;

    final tareasAsync = ref.watch(tareasDeProyectoProvider(_p.id));
    final bitacoraAsync = ref.watch(bitacoraDeProyectoProvider(_p.id));
    final proximoAsync = ref.watch(proximoPasoProvider(_p.id));

    final tareas = tareasAsync.valueOrNull ?? const <ProjectTask>[];
    final progreso = _p.progresoCon(tareas);
    final proximo = proximoAsync.valueOrNull;
    final tienePasos = _p.tienePasos(tareas);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        scrolledUnderElevation: 0,
        title: Text(_p.titulo, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            onSelected: (op) {
              if (op == 'editar') {
                _editar();
              } else if (op == 'eliminar') {
                _eliminar();
              } else {
                _cambioEstado(op);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              if (!_p.esPrincipal)
                const PopupMenuItem(
                    value: 'principal', child: Text('Marcar como principal')),
              if (_p.activo)
                const PopupMenuItem(value: 'pausar', child: Text('Pausar')),
              if (!_p.completado)
                const PopupMenuItem(
                    value: 'completar', child: Text('Completar')),
              if (!_p.archivado)
                const PopupMenuItem(
                    value: 'archivar', child: Text('Archivar')),
              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final bp = bpDe(c.maxWidth);
            final pad = padLateral(bp);
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxLienzo),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        pad, AppSpacing.lg, pad, AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Cabecera(proyecto: _p, progreso: progreso, bp: bp),
                        const SizedBox(height: AppSpacing.md),
                        BarraProximoPaso(
                          proximoTexto: proximo?.texto,
                          tienePasos: tienePasos,
                          activo: _p.activo,
                          onAvanzar: () => avanzarProyecto(context, ref,
                              projectId: _p.id, proximo: proximo),
                          onAgregarPaso: () => mostrarEditorTarea(context, ref,
                              projectId: _p.id, tipoInicial: 'paso'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _DashboardSecciones(
                          bp: bp,
                          tareas: _SeccionTareas(
                            tareasAsync: tareasAsync,
                            acc: _acc,
                            onNuevo: (tipo) => mostrarEditorTarea(context, ref,
                                projectId: _p.id, tipoInicial: tipo),
                            onEditar: (t) => mostrarEditorTarea(context, ref,
                                projectId: _p.id, existente: t),
                          ),
                          bitacora: _SeccionBitacora(
                            bitacoraAsync: bitacoraAsync,
                            onAvance: () => mostrarRegistroBitacora(
                                context, ref,
                                projectId: _p.id, esNota: false),
                            onNota: () => mostrarRegistroBitacora(context, ref,
                                projectId: _p.id, esNota: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Distribuye Pasos (izquierda, más ancho) y Bitácora (derecha) en escritorio
/// y tablet; las apila en móvil.
class _DashboardSecciones extends StatelessWidget {
  const _DashboardSecciones({
    required this.bp,
    required this.tareas,
    required this.bitacora,
  });
  final VitaBp bp;
  final Widget tareas;
  final Widget bitacora;

  @override
  Widget build(BuildContext context) {
    if (bp == VitaBp.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tareas,
          const SizedBox(height: AppSpacing.lg),
          bitacora,
        ],
      );
    }
    final flexTareas = bp == VitaBp.desktop ? 7 : 1;
    final flexBitacora = bp == VitaBp.desktop ? 5 : 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: flexTareas, child: tareas),
        const SizedBox(width: AppSpacing.lg),
        Expanded(flex: flexBitacora, child: bitacora),
      ],
    );
  }
}

// ───────────────── Cabecera (héroe) ─────────────────

class _Cabecera extends StatelessWidget {
  const _Cabecera(
      {required this.proyecto, required this.progreso, required this.bp});
  final Project proyecto;
  final int progreso;
  final VitaBp bp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final esMovil = bp == VitaBp.mobile;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChipEstado(estado: proyecto.estado),
            if (proyecto.esPrincipal) const _PillPrincipal(),
            if (proyecto.area != null) EtiquetaArea(area: proyecto.area),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(proyecto.titulo,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
        if (proyecto.objetivo != null) ...[
          const SizedBox(height: 6),
          Text(proyecto.objetivo!,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
        ],
        if (proyecto.fechaObjetivo != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Meta: ${proyecto.fechaObjetivo!.day}/${proyecto.fechaObjetivo!.month}/${proyecto.fechaObjetivo!.year}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ],
    );

    return _Panel(
      padding: EdgeInsets.all(esMovil ? AppSpacing.lg : AppSpacing.xl),
      child: esMovil
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnilloProgreso(progreso: progreso, tamano: 64, grosor: 6),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(proyecto.titulo,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                info,
                if (proyecto.descripcion != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Motivacion(texto: proyecto.descripcion!),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnilloProgreso(progreso: progreso, tamano: 104, grosor: 9),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      info,
                      if (proyecto.descripcion != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _Motivacion(texto: proyecto.descripcion!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Motivacion extends StatelessWidget {
  const _Motivacion({required this.texto});
  final String texto;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_outline,
              size: 16, color: AppColors.accentSoft),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(texto,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(height: 1.35, color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _PillPrincipal extends StatelessWidget {
  const _PillPrincipal();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text('Principal',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ───────────────── Pasos / Hitos ─────────────────

class _SeccionTareas extends StatelessWidget {
  const _SeccionTareas({
    required this.tareasAsync,
    required this.acc,
    required this.onNuevo,
    required this.onEditar,
  });

  final AsyncValue<List<ProjectTask>> tareasAsync;
  final ProyectosAcciones acc;
  final ValueChanged<String> onNuevo;
  final ValueChanged<ProjectTask> onEditar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tareas = tareasAsync.valueOrNull ?? const <ProjectTask>[];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Pasos e hitos',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (tareas.isNotEmpty)
                IconButton(
                  tooltip: 'Agregar paso',
                  onPressed: () => onNuevo('paso'),
                  icon: const Icon(Icons.add, color: AppColors.accent),
                ),
            ],
          ),
          if (tareasAsync.isLoading && tareas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (tareas.isEmpty)
            _VacioPasos(onNuevo: onNuevo)
          else ...[
            for (var i = 0; i < tareas.length; i++)
              _TareaRow(
                tarea: tareas[i],
                primera: i == 0,
                ultima: i == tareas.length - 1,
                onToggle: () => tareas[i].completada
                    ? acc.reabrirTarea(tareas[i])
                    : acc.completarTarea(tareas[i]),
                onEditar: () => onEditar(tareas[i]),
                onSubir: () => acc.subirTarea(tareas[i]),
                onBajar: () => acc.bajarTarea(tareas[i]),
                onEliminar: () async {
                  final ok = await _confirmar(context, 'Eliminar',
                      '¿Eliminar "${tareas[i].texto}"?', 'Eliminar');
                  if (ok == true) acc.eliminarTarea(tareas[i]);
                },
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onNuevo('paso'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Paso'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onNuevo('hito'),
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: const Text('Hito'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VacioPasos extends StatelessWidget {
  const _VacioPasos({required this.onNuevo});
  final ValueChanged<String> onNuevo;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.checklist_rtl_outlined,
                color: AppColors.accentSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Divide tu objetivo en pasos',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Empieza por el próximo paso concreto. Suma hitos para los\nmomentos importantes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => onNuevo('paso'),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11)),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Paso'),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => onNuevo('hito'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11)),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Hito'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TareaRow extends StatelessWidget {
  const _TareaRow({
    required this.tarea,
    required this.primera,
    required this.ultima,
    required this.onToggle,
    required this.onEditar,
    required this.onSubir,
    required this.onBajar,
    required this.onEliminar,
  });

  final ProjectTask tarea;
  final bool primera;
  final bool ultima;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onSubir;
  final VoidCallback onBajar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hecho = tarea.completada;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, right: AppSpacing.sm),
              child: Icon(
                hecho ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 22,
                color: hecho ? AppColors.accent : cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (tarea.esHito) ...[
                        const _BadgeHito(),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          tarea.texto,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.25,
                            decoration:
                                hecho ? TextDecoration.lineThrough : null,
                            color: hecho ? cs.onSurfaceVariant : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tarea.fechaObjetivo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${tarea.fechaObjetivo!.day}/${tarea.fechaObjetivo!.month}/${tarea.fechaObjetivo!.year}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
            onSelected: (op) {
              switch (op) {
                case 'editar':
                  onEditar();
                  break;
                case 'subir':
                  onSubir();
                  break;
                case 'bajar':
                  onBajar();
                  break;
                case 'eliminar':
                  onEliminar();
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              if (!primera)
                const PopupMenuItem(value: 'subir', child: Text('Subir')),
              if (!ultima)
                const PopupMenuItem(value: 'bajar', child: Text('Bajar')),
              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeHito extends StatelessWidget {
  const _BadgeHito();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text('Hito',
          style: TextStyle(
              color: AppColors.warning,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ───────────────── Bitácora ─────────────────

class _SeccionBitacora extends StatelessWidget {
  const _SeccionBitacora({
    required this.bitacoraAsync,
    required this.onAvance,
    required this.onNota,
  });

  final AsyncValue<List<ProjectLogEntry>> bitacoraAsync;
  final VoidCallback onAvance;
  final VoidCallback onNota;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final entradas = bitacoraAsync.valueOrNull ?? const <ProjectLogEntry>[];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Bitácora',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: onAvance,
                icon: const Icon(Icons.trending_up, size: 16),
                label: const Text('Avance'),
              ),
              TextButton.icon(
                onPressed: onNota,
                icon: const Icon(Icons.sticky_note_2_outlined, size: 16),
                label: const Text('Nota'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (bitacoraAsync.isLoading && entradas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (entradas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('Aún no hay registros. Tu historia empieza aquí.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            )
          else
            for (var i = 0; i < entradas.length; i++)
              _BitacoraFila(
                entrada: entradas[i],
                primera: i == 0,
                ultima: i == entradas.length - 1,
              ),
        ],
      ),
    );
  }
}

class _BitacoraFila extends StatelessWidget {
  const _BitacoraFila(
      {required this.entrada, required this.primera, required this.ultima});
  final ProjectLogEntry entrada;
  final bool primera;
  final bool ultima;

  (IconData, Color, String) _meta() {
    switch (entrada.tipo) {
      case 'creado':
        return (Icons.flag_circle_outlined, AppColors.accentSoft, 'Creado');
      case 'hito_completado':
        return (Icons.emoji_events_outlined, AppColors.warning, 'Hito');
      case 'cambio_estado':
        return (Icons.swap_horiz, AppColors.info, 'Estado');
      case 'nota':
        return (Icons.sticky_note_2_outlined, AppColors.info, 'Nota');
      default:
        return (Icons.trending_up, AppColors.accent, 'Avance');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (icono, color, etiqueta) = _meta();
    final rail = cs.outlineVariant.withValues(alpha: 0.5);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                    width: 2,
                    height: 6,
                    color: primera ? Colors.transparent : rail),
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, size: 14, color: color),
                ),
                Expanded(
                  child: Container(
                      width: 2, color: ultima ? Colors.transparent : rail),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(etiqueta,
                          style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700, color: color)),
                      const Spacer(),
                      Text(_fechaRel(entrada.fecha),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                  if (entrada.texto != null && entrada.texto!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(entrada.texto!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.3)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── compartidos ─────────────────

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

Future<bool?> _confirmar(
    BuildContext context, String titulo, String mensaje, String boton) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: Text(boton),
        ),
      ],
    ),
  );
}

String _fechaRel(DateTime d) {
  final ahora = DateTime.now();
  final diff = ahora.difference(d);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 7) return 'hace ${diff.inDays} días';
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];
  return '${d.day} ${meses[d.month - 1]}';
}
