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

  void abrirDetalle(BuildContext context, Project p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProyectoDetalleScreen(proyecto: p)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1815) : cs.surface;
    final wide = MediaQuery.sizeOf(context).width >= 900;

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
          if (wide)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: FilledButton.icon(
                onPressed: () => mostrarEditorProyecto(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo proyecto'),
              ),
            ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => mostrarEditorProyecto(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo proyecto'),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Hero — Proyecto Principal
                principal.when(
                  loading: () => const _CargandoPanel(),
                  error: (_, __) => const _ErrorPanel(),
                  data: (p) => p == null
                      ? _HeroVacio(
                          onCrear: () => mostrarEditorProyecto(context, ref))
                      : _HeroPrincipal(
                          proyecto: p,
                          onAbrir: () => abrirDetalle(context, p),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _Seccion(
                  titulo: 'Activos',
                  async: activos,
                  // El principal ya aparece en el hero: no repetir.
                  filtro: (p) => !p.esPrincipal,
                  vacio: 'No tienes proyectos activos.',
                  onAbrir: (p) => abrirDetalle(context, p),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Seccion(
                  titulo: 'Pausados',
                  async: pausados,
                  vacio: 'Nada en pausa.',
                  ocultarSiVacio: true,
                  onAbrir: (p) => abrirDetalle(context, p),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Seccion(
                  titulo: 'Completados y archivados',
                  async: completados,
                  vacio: 'Aún no completas proyectos.',
                  ocultarSiVacio: true,
                  tenue: true,
                  onAbrir: (p) => abrirDetalle(context, p),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────── Hero principal ─────────────────

class _HeroPrincipal extends ConsumerWidget {
  const _HeroPrincipal({required this.proyecto, required this.onAbrir});
  final Project proyecto;
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

    return _PanelHero(
      onTap: onAbrir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Eyebrow('PROYECTO PRINCIPAL'),
              const Spacer(),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnilloProgreso(progreso: progreso, tamano: 84, grosor: 8),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proyecto.titulo,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
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
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_forward, size: 16, color: AppColors.oliveSoft),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    proximo?.texto ?? 'Sin pasos pendientes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  ref.read(proyectosAccionesProvider).avanzar(proyecto.id),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.olive,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Avanzar'),
            ),
          ),
        ],
      ),
    );
  }
}

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
                  color: AppColors.olive.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_outlined,
                    color: AppColors.oliveSoft),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCrear,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.olive,
                padding: const EdgeInsets.symmetric(vertical: 14),
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

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.async,
    required this.vacio,
    required this.onAbrir,
    this.filtro,
    this.ocultarSiVacio = false,
    this.tenue = false,
  });

  final String titulo;
  final AsyncValue<List<Project>> async;
  final String vacio;
  final ValueChanged<Project> onAbrir;
  final bool Function(Project)? filtro;
  final bool ocultarSiVacio;
  final bool tenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final todos = async.valueOrNull ?? const <Project>[];
    final lista =
        filtro == null ? todos : todos.where(filtro!).toList();

    if (ocultarSiVacio && !async.isLoading && lista.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
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
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 4, vertical: AppSpacing.xs),
            child: Text(vacio,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          )
        else
          for (final p in lista)
            _TarjetaProyecto(
              proyecto: p,
              tenue: tenue,
              onAbrir: () => onAbrir(p),
            ),
      ],
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
    final acc = ref.read(proyectosAccionesProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: cs.surfaceContainerLow.withValues(alpha: tenue ? 0.5 : 1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onAbrir,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                AnilloProgreso(progreso: progreso, tamano: 46, grosor: 5),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (proyecto.esPrincipal) ...[
                            const Icon(Icons.star,
                                size: 14, color: AppColors.olive),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(proyecto.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ChipEstado(estado: proyecto.estado),
                          if (proyecto.area != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(child: EtiquetaArea(area: proyecto.area)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _MenuProyecto(
                  proyecto: proyecto,
                  onEditar: () =>
                      mostrarEditorProyecto(context, ref, existente: proyecto),
                  onPrincipal: () => acc.marcarComoPrincipal(proyecto.id),
                  onPausar: () => acc.pausarProyecto(proyecto.id),
                  onCompletar: () => acc.completarProyecto(proyecto.id),
                  onArchivar: () => acc.archivarProyecto(proyecto.id),
                  onEliminar: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Eliminar proyecto'),
                        content: Text(
                            'Se borrará "${proyecto.titulo}" con sus pasos y bitácora. No se puede deshacer.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancelar')),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
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
      border: Border.all(color: AppColors.olive.withValues(alpha: 0.35)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
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
        height: 120,
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
