import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/projects_repository.dart';
import 'projects_controller.dart';
import 'proyecto_detalle_screen.dart';
import 'proyecto_editores.dart';
import 'proyectos_widgets.dart';

class ProyectosScreen extends ConsumerWidget {
  const ProyectosScreen({super.key});

  void _abrirDetalle(BuildContext context, Project p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProyectoDetalleScreen(proyecto: p)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surface;
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    final mostrarBotonArriba = anchoPantalla >= 700;

    final principal = ref.watch(proyectoPrincipalProvider);
    final activos = ref.watch(proyectosActivosProvider);
    final pausados = ref.watch(proyectosPausadosProvider);
    final completados = ref.watch(proyectosCompletadosProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Proyectos'),
        backgroundColor: bg,
        scrolledUnderElevation: 0,
        actions: [
          if (mostrarBotonArriba)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: FilledButton.icon(
                onPressed: () => mostrarEditorProyecto(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo proyecto'),
              ),
            ),
        ],
      ),
      floatingActionButton: mostrarBotonArriba
          ? null
          : FloatingActionButton.extended(
              onPressed: () => mostrarEditorProyecto(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo proyecto'),
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final bp = bpDe(c.maxWidth);
            final pad = padLateral(bp);
            final cols = colsCartera(c.maxWidth);
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
                        principal.when(
                          loading: () => const _CargandoPanel(),
                          error: (_, __) => const _ErrorPanel(),
                          data: (p) => p == null
                              ? _HeroVacio(
                                  onCrear: () =>
                                      mostrarEditorProyecto(context, ref))
                              : _HeroPrincipal(
                                  proyecto: p,
                                  desktop: bp == VitaBp.desktop,
                                  onAbrir: () => _abrirDetalle(context, p),
                                ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: () =>
                                mostrarEditorProyecto(context, ref),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 13),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nuevo proyecto'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SeccionCartera(
                          titulo: 'Activos',
                          async: activos,
                          cols: cols,
                          // TODOS los activos, incluido el principal (con chip).
                          filtro: (p) => true,
                          ocultarSiVacio: false,
                          vacio: _VacioActivos(
                              onCrear: () => mostrarEditorProyecto(context, ref)),
                          onAbrir: (p) => _abrirDetalle(context, p),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SeccionCartera(
                          titulo: 'Pausados',
                          async: pausados,
                          cols: cols,
                          ocultarSiVacio: true,
                          onAbrir: (p) => _abrirDetalle(context, p),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SeccionCartera(
                          titulo: 'Completados y archivados',
                          async: completados,
                          cols: cols,
                          ocultarSiVacio: true,
                          tenue: true,
                          onAbrir: (p) => _abrirDetalle(context, p),
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

// ───────────────── Hero principal ─────────────────

class _HeroPrincipal extends ConsumerWidget {
  const _HeroPrincipal({
    required this.proyecto,
    required this.desktop,
    required this.onAbrir,
  });
  final Project proyecto;
  final bool desktop;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tareas =
        ref.watch(tareasDeProyectoProvider(proyecto.id)).valueOrNull ??
            const <ProjectTask>[];
    final proximo = ref.watch(proximoPasoProvider(proyecto.id)).valueOrNull;
    final progreso = proyecto.progresoCon(tareas);

    final encabezado = Row(
      children: [
        const Eyebrow('PROYECTO PRINCIPAL'),
        const Spacer(),
        Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      ],
    );

    final identidad = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnilloProgreso(
            progreso: progreso, tamano: desktop ? 96 : 72, grosor: desktop ? 9 : 7),
        SizedBox(width: desktop ? AppSpacing.xl : AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(proyecto.titulo,
                  style: (desktop
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
              if (proyecto.objetivo != null) ...[
                const SizedBox(height: 4),
                Text(proyecto.objetivo!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
              ],
              if (proyecto.area != null) ...[
                const SizedBox(height: 8),
                EtiquetaArea(area: proyecto.area),
              ],
            ],
          ),
        ),
      ],
    );

    final barra = BarraProximoPaso(
      proximoTexto: proximo?.texto,
      tienePasos: proyecto.tienePasos(tareas),
      activo: proyecto.activo,
      onAvanzar: () => avanzarProyecto(context, ref,
          projectId: proyecto.id, proximo: proximo),
      onAgregarPaso: () => mostrarEditorTarea(context, ref,
          projectId: proyecto.id, tipoInicial: 'paso'),
    );

    return _PanelHero(
      onTap: onAbrir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          encabezado,
          const SizedBox(height: AppSpacing.md),
          identidad,
          const SizedBox(height: AppSpacing.md),
          barra,
        ],
      ),
    );
  }
}

/// Barra compacta del hero: próximo paso + Avanzar (horizontal, nunca vertical).
class _HeroVacio extends StatelessWidget {
  const _HeroVacio({required this.onCrear});
  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return _PanelHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('PROYECTO PRINCIPAL'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.flag_outlined, color: AppColors.accentSoft),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Elige tu proyecto principal',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'VITA destaca un solo proyecto a la vez. Crea el tuyo o marca uno desde su menú.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onCrear,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear proyecto'),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── Secciones de cartera ─────────────────

class _SeccionCartera extends StatelessWidget {
  const _SeccionCartera({
    required this.titulo,
    required this.async,
    required this.cols,
    required this.onAbrir,
    this.filtro,
    this.vacio,
    this.ocultarSiVacio = false,
    this.tenue = false,
  });

  final String titulo;
  final AsyncValue<List<Project>> async;
  final int cols;
  final ValueChanged<Project> onAbrir;
  final bool Function(Project)? filtro;
  final Widget? vacio;
  final bool ocultarSiVacio;
  final bool tenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final todos = async.valueOrNull ?? const <Project>[];
    final lista = filtro == null ? todos : todos.where(filtro!).toList();

    if (ocultarSiVacio && !async.isLoading && lista.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.md),
          child: Row(
            children: [
              Text(titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tenue ? cs.onSurfaceVariant : null)),
              const SizedBox(width: AppSpacing.sm),
              if (lista.isNotEmpty)
                Text('${lista.length}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        if (async.isLoading && lista.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (lista.isEmpty)
          vacio ??
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 2, vertical: AppSpacing.xs),
                child: Text('Nada por aquí.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              )
        else
          RejillaFluida(
            columnas: cols,
            hijos: [
              for (final p in lista)
                _TarjetaProyecto(
                  proyecto: p,
                  tenue: tenue,
                  onAbrir: () => onAbrir(p),
                ),
            ],
          ),
      ],
    );
  }
}

class _VacioActivos extends StatelessWidget {
  const _VacioActivos({required this.onCrear});
  final VoidCallback onCrear;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.4),
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspaces_outline,
                color: AppColors.accentSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Sin proyectos activos',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Crea tu primer proyecto y empieza por tu próximo paso.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onCrear,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nuevo proyecto'),
          ),
        ],
      ),
    );
  }
}

class _TarjetaProyecto extends ConsumerWidget {
  const _TarjetaProyecto({
    required this.proyecto,
    required this.onAbrir,
    this.tenue = false,
  });
  final Project proyecto;
  final VoidCallback onAbrir;
  final bool tenue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tareas =
        ref.watch(tareasDeProyectoProvider(proyecto.id)).valueOrNull ??
            const <ProjectTask>[];
    final progreso = proyecto.progresoCon(tareas);
    final proximo = ref.watch(proximoPasoProvider(proyecto.id)).valueOrNull;
    final acc = ref.read(proyectosAccionesProvider);

    return Material(
      color: cs.surfaceContainerLow.withValues(alpha: tenue ? 0.5 : 1),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onAbrir,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnilloProgreso(progreso: progreso, tamano: 48, grosor: 5),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(proyecto.titulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (proyecto.esPrincipal)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        size: 12, color: AppColors.accent),
                                    const SizedBox(width: 3),
                                    Text('Principal',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ChipEstado(estado: proyecto.estado),
                            if (proyecto.area != null)
                              EtiquetaArea(area: proyecto.area),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _MenuProyecto(
                    proyecto: proyecto,
                    onEditar: () => mostrarEditorProyecto(context, ref,
                        existente: proyecto),
                    onPrincipal: () => acc.marcarComoPrincipal(proyecto.id),
                    onPausar: () => acc.pausarProyecto(proyecto.id),
                    onCompletar: () => acc.completarProyecto(proyecto.id),
                    onArchivar: () => acc.archivarProyecto(proyecto.id),
                    onEliminar: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Eliminar proyecto'),
                          content: Text(
                              'Se borrará "${proyecto.titulo}" con sus pasos y bitácora. No se puede deshacer.'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(false),
                                child: const Text('Cancelar')),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogCtx).pop(true),
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) acc.eliminarProyecto(proyecto.id);
                    },
                  ),
                ],
              ),
              if (proximo != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward,
                          size: 14, color: AppColors.accentSoft),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(proximo.texto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuProyecto extends StatelessWidget {
  const _MenuProyecto({
    required this.proyecto,
    required this.onEditar,
    required this.onPrincipal,
    required this.onPausar,
    required this.onCompletar,
    required this.onArchivar,
    required this.onEliminar,
  });

  final Project proyecto;
  final VoidCallback onEditar;
  final VoidCallback onPrincipal;
  final VoidCallback onPausar;
  final VoidCallback onCompletar;
  final VoidCallback onArchivar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: 'Opciones',
      icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
      onSelected: (op) {
        switch (op) {
          case 'editar':
            onEditar();
            break;
          case 'principal':
            onPrincipal();
            break;
          case 'pausar':
            onPausar();
            break;
          case 'completar':
            onCompletar();
            break;
          case 'archivar':
            onArchivar();
            break;
          case 'eliminar':
            onEliminar();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'editar', child: Text('Editar')),
        if (!proyecto.esPrincipal)
          const PopupMenuItem(
              value: 'principal', child: Text('Marcar como principal')),
        if (proyecto.activo)
          const PopupMenuItem(value: 'pausar', child: Text('Pausar')),
        if (!proyecto.completado)
          const PopupMenuItem(value: 'completar', child: Text('Completar')),
        if (!proyecto.archivado)
          const PopupMenuItem(value: 'archivar', child: Text('Archivar')),
        const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
      ],
    );
  }
}

// ───────────────── paneles utilitarios ─────────────────

class _PanelHero extends StatelessWidget {
  const _PanelHero({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final deco = BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
    final contenido = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
    if (onTap == null) {
      return Container(decoration: deco, child: contenido);
    }
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: deco,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: contenido,
        ),
      ),
    );
  }
}

class _CargandoPanel extends StatelessWidget {
  const _CargandoPanel();
  @override
  Widget build(BuildContext context) {
    return const _PanelHero(
      child: SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel();
  @override
  Widget build(BuildContext context) {
    return _PanelHero(
      child: Text('No se pudo cargar tus proyectos.',
          style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
