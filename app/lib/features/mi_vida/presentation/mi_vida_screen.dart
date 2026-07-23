import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/versiculos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/errores.dart';
import '../../../core/widgets/eyebrow.dart';
import '../../../core/widgets/vita_card.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../salud/data/estado_repository.dart';
import '../../salud/presentation/estado_controller.dart';
import '../data/habitos_repository.dart';
import '../data/prioridades_repository.dart';
import '../../agenda/data/agenda_repository.dart';
import '../../agenda/presentation/agenda_controller.dart';
import '../../agenda/presentation/evento_editor.dart';
import 'habitos_controller.dart';
import 'prioridades_controller.dart';
import 'package:go_router/go_router.dart';
import '../../proyectos/data/projects_repository.dart';
import '../../proyectos/presentation/projects_controller.dart';
import '../../proyectos/presentation/proyecto_detalle_screen.dart';
import '../../proyectos/presentation/proyecto_editores.dart';
import '../../proyectos/presentation/proyectos_widgets.dart';

const EdgeInsets _kCardPad = EdgeInsets.fromLTRB(20, 18, 20, 18);
const double _kGap = 12;
const double _kDesktopMax = 1280;

// Puntos de quiebre: escritorio ≥1000, tablet 640–1000, móvil <640.
const double _kBpDesktop = 1000;
const double _kBpTablet = 640;

/// MI VIDA — escritorio editorial responsive. Tres composiciones reales:
/// 12 columnas (desktop), 2 columnas (tablet), 1 columna (móvil).
/// Orden: Saludo → Versículo → Hoy importa → Estado → Agenda → Proyecto →
/// Hábitos. Dios arriba.
///
/// Solo se muestra lo que existe: no hay tarjetas de módulos futuros
/// (entrenamiento, menú, cierre del día). Una tarjeta que no hace nada le
/// cuesta a la usuaria un scroll cada día y no le devuelve nada.
class MiVidaScreen extends ConsumerWidget {
  const MiVidaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Cerrar sesión vive en Ajustes: no es una acción de uso diario y no
      // debería estar a un toque de distancia en la pantalla principal.
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: const Text('VITA'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            if (w >= _kBpDesktop) return const _DesktopLayout();
            if (w >= _kBpTablet) return const _TabletLayout();
            return const _MobileLayout();
          },
        ),
      ),
    );
  }
}

// ============================ LAYOUTS ============================

/// Escritorio: grid editorial de 12 columnas, centrado y limitado para no
/// estirarse al infinito, pero aprovechando el ancho.
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kDesktopMax),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
          children: [
            const _BuenosDias(),
            const SizedBox(height: AppSpacing.xl),
            const _Versiculo(), // Dios arriba
            const SizedBox(height: _kGap),
            const _Prioridades(), // protagonista, ancho completo
            const SizedBox(height: _kGap),
            const _EstadoGeneral(), // compacta, ancho completo
            const SizedBox(height: _kGap),
            // Cada tarjeta a su altura de contenido: así "TU DÍA" vacío no se
            // estira para igualar a "PROYECTO PRINCIPAL".
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(child: _Agenda()),
                SizedBox(width: _kGap),
                Expanded(child: _ProyectoPrincipal()),
              ],
            ),
            const SizedBox(height: _kGap),
            const _Habitos(),
          ],
        ),
      ),
    );
  }
}

/// Tablet: dos columnas. Mantiene el orden; pares donde tiene sentido.
class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const _BuenosDias(),
        const SizedBox(height: AppSpacing.lg),
        const _Versiculo(),
        const SizedBox(height: _kGap),
        const _Prioridades(),
        const SizedBox(height: _kGap),
        const _EstadoGeneral(),
        const SizedBox(height: _kGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(child: _Agenda()),
            SizedBox(width: _kGap),
            Expanded(child: _ProyectoPrincipal()),
          ],
        ),
        const SizedBox(height: _kGap),
        const _Habitos(),
      ],
    );
  }
}

/// Móvil: una sola columna, orden exacto.
class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
      children: const [
        _BuenosDias(),
        SizedBox(height: AppSpacing.md),
        _Versiculo(),
        SizedBox(height: _kGap),
        _Prioridades(),
        SizedBox(height: _kGap),
        _EstadoGeneral(),
        SizedBox(height: _kGap),
        _Agenda(),
        SizedBox(height: _kGap),
        _ProyectoPrincipal(),
        SizedBox(height: _kGap),
        _Habitos(),
      ],
    );
  }
}

// ============================ TARJETAS ============================

class _BuenosDias extends ConsumerWidget {
  const _BuenosDias();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(profileControllerProvider).maybeWhen(
          data: (p) => p?.displayName ?? 'Yurby',
          orElse: () => 'Yurby',
        );
    final now = DateTime.now();
    final saludo = now.hour < 12
        ? 'Buenos días'
        : now.hour < 20
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$saludo, $name.',
          style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -0.3),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_fechaLarga(now)} · Tu día ya está preparado.',
          style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class _Versiculo extends StatelessWidget {
  const _Versiculo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = versiculoDelDia(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Eyebrow('VERSÍCULO DEL DÍA'),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"${v.texto}"',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            v.cita,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Prioridades extends ConsumerWidget {
  const _Prioridades();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(prioridadesControllerProvider);
    final prioridades = async.valueOrNull ?? const <Prioridad>[];

    return Container(
      width: double.infinity,
      padding: _kCardPad,
      decoration: BoxDecoration(
        color: const Color(0x146B7A4F),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0x336B7A4F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('HOY IMPORTA'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tus tres prioridades del día.',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          ),
          const SizedBox(height: AppSpacing.md),
          if (async.isLoading && prioridades.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (async.hasError && prioridades.isEmpty)
            ErrorEnTarjeta(
              mensaje: mensajeDeError(async.error!),
              onReintentar: () => ref.invalidate(prioridadesControllerProvider),
            )
          else if (prioridades.isEmpty)
            _PrioridadesVacio(
              onAgregar: () => _dialogoPrioridad(context, ref),
            )
          else ...[
            for (var i = 0; i < prioridades.length; i++)
              _PrioridadRow(
                posicion: i + 1,
                prioridad: prioridades[i],
                puedeSubir: i > 0,
                puedeBajar: i < prioridades.length - 1,
                onToggle: () => accionSegura(
                  context,
                  () => ref
                      .read(prioridadesControllerProvider.notifier)
                      .alternar(prioridades[i]),
                ),
                onEditar: () =>
                    _dialogoPrioridad(context, ref, existente: prioridades[i]),
                onEliminar: () => accionSegura(
                  context,
                  () => ref
                      .read(prioridadesControllerProvider.notifier)
                      .eliminar(prioridades[i].id),
                ),
                onSubir: () => accionSegura(
                  context,
                  () => ref
                      .read(prioridadesControllerProvider.notifier)
                      .mover(i, -1),
                ),
                onBajar: () => accionSegura(
                  context,
                  () => ref
                      .read(prioridadesControllerProvider.notifier)
                      .mover(i, 1),
                ),
              ),
            if (prioridades.length < PrioridadesRepository.maximoPorDia)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: _AgregarPrioridad(
                  onTap: () => _dialogoPrioridad(context, ref),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PrioridadesVacio extends StatelessWidget {
  const _PrioridadesVacio({required this.onAgregar});
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aún no defines lo esencial de hoy.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AgregarPrioridad(onTap: onAgregar),
      ],
    );
  }
}

class _AgregarPrioridad extends StatelessWidget {
  const _AgregarPrioridad({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Agregar prioridad'),
      ),
    );
  }
}

class _PrioridadRow extends StatelessWidget {
  const _PrioridadRow({
    required this.posicion,
    required this.prioridad,
    required this.puedeSubir,
    required this.puedeBajar,
    required this.onToggle,
    required this.onEditar,
    required this.onEliminar,
    required this.onSubir,
    required this.onBajar,
  });

  final int posicion; // 1, 2, 3 (posición visible)
  final Prioridad prioridad;
  final bool puedeSubir;
  final bool puedeBajar;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onSubir;
  final VoidCallback onBajar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = prioridad.completada;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // IconButton (no GestureDetector): garantiza un área táctil de 48dp.
          IconButton(
            onPressed: onToggle,
            tooltip: done ? 'Marcar pendiente' : 'Marcar hecha',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color:
                  done ? AppColors.accent : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 18,
            child: Text(
              '$posicion.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: GestureDetector(
              onTap: onEditar,
              behavior: HitTestBehavior.opaque,
              child: Text(
                prioridad.texto,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            tooltip: 'Opciones',
            onSelected: (op) {
              if (op == 'subir') {
                onSubir();
              } else if (op == 'bajar') {
                onBajar();
              } else if (op == 'editar') {
                onEditar();
              } else if (op == 'eliminar') {
                onEliminar();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'subir',
                enabled: puedeSubir,
                child: const Row(children: [
                  Icon(Icons.arrow_upward, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Mover arriba'),
                ]),
              ),
              PopupMenuItem<String>(
                value: 'bajar',
                enabled: puedeBajar,
                child: const Row(children: [
                  Icon(Icons.arrow_downward, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Mover abajo'),
                ]),
              ),
              const PopupMenuItem<String>(
                value: 'editar',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Editar'),
                ]),
              ),
              const PopupMenuItem<String>(
                value: 'eliminar',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Eliminar'),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _dialogoPrioridad(
  BuildContext context,
  WidgetRef ref, {
  Prioridad? existente,
}) async {
  final controller = TextEditingController(text: existente?.texto ?? '');
  final esEdicion = existente != null;
  final notifier = ref.read(prioridadesControllerProvider.notifier);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(esEdicion ? 'Editar prioridad' : 'Nueva prioridad'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: '¿Qué es lo esencial hoy?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (esEdicion)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await accionSegura(
                    context, () => notifier.eliminar(existente.id));
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Eliminar'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              final txt = value.text.trim();
              return FilledButton(
                onPressed: txt.isEmpty
                    ? null
                    : () async {
                        // Cerrar primero y avisar después: si el guardado falla
                        // (p. ej. el tope de 3), la usuaria ve el motivo en vez
                        // de un diálogo que se cierra sin más.
                        Navigator.of(ctx).pop();
                        await accionSegura(
                          context,
                          () => esEdicion
                              ? notifier.editarTexto(existente.id, txt)
                              : notifier.agregar(txt),
                        );
                      },
                child: Text(esEdicion ? 'Guardar' : 'Agregar'),
              );
            },
          ),
        ],
      );
    },
  );
  controller.dispose();
}

class _EstadoGeneral extends ConsumerWidget {
  const _EstadoGeneral();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(estadoControllerProvider);
    final estado = async.valueOrNull;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _abrirRegistroEstado(context, ref, estado),
      child: VitaCard(
        padding: _kCardPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Eyebrow('CÓMO ESTÁS HOY'),
                Icon(Icons.add, size: 18, color: AppColors.accent),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (async.hasError && estado == null)
              ErrorEnTarjeta(
                mensaje: mensajeDeError(async.error!),
                onReintentar: () => ref.invalidate(estadoControllerProvider),
              )
            else
              Row(
                children: [
                  _Metric(
                      label: 'Peso',
                      value: _fmtPesoCard(
                          estado?.pesoUltimo, estado?.pesoTendencia)),
                  _Metric(
                      label: 'Energía',
                      value: _energiaPalabra(estado?.energia)),
                  _Metric(
                      label: 'Sueño',
                      value: _fmtSuenoCard(
                          estado?.suenoCalidad, estado?.suenoHoras)),
                  _Metric(label: 'Ánimo', value: _animoPalabra(estado?.animo)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String _numEs(double v) {
  final s =
      (v == v.roundToDouble()) ? v.toInt().toString() : v.toStringAsFixed(1);
  return s.replaceAll('.', ',');
}

// La vista cotidiana habla en lenguaje humano, no en puntuación "x de 5".
// El número (1–5) se conserva en el modelo, históricos y el registro.
String _energiaPalabra(int? v) {
  if (v == null) return '—';
  if (v <= 2) return 'Baja';
  if (v == 3) return 'Estable';
  if (v == 4) return 'Buena';
  return 'Alta';
}

String _animoPalabra(int? v) {
  if (v == null) return '—';
  if (v <= 2) return 'Sensible';
  if (v == 3) return 'Estable';
  if (v == 4) return 'Bueno';
  return 'Alto';
}

String _fmtPesoCard(double? p, double? t) {
  if (p == null) return '—';
  var s = '${_numEs(p)} kg';
  if (t != null && t.abs() >= 0.05) s += t > 0 ? '  ↑' : '  ↓';
  return s;
}

const _suenoPalabra = {1: 'Mal', 2: 'Regular', 3: 'Bien'};

String _fmtSuenoCard(int? calidad, double? horas) {
  if (calidad != null) return _suenoPalabra[calidad] ?? '—';
  if (horas != null) return '${_numEs(horas)} h';
  return '—';
}

Future<void> _abrirRegistroEstado(
    BuildContext context, WidgetRef ref, EstadoHoy? actual) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RegistrarEstadoSheet(actual: actual),
  );
}

class _Agenda extends ConsumerWidget {
  const _Agenda();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventosEnRangoProvider(rangoHoy()));
    final ahora = DateTime.now();
    final eventosHoy = (async.valueOrNull ?? const <Evento>[])
        .where((e) =>
            e.inicio.year == ahora.year &&
            e.inicio.month == ahora.month &&
            e.inicio.day == ahora.day)
        .toList();

    return VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Eyebrow('TU DÍA'),
              IconButton(
                onPressed: () => mostrarEditorEvento(context, ref,
                    fechaSugerida:
                        DateTime(ahora.year, ahora.month, ahora.day)),
                tooltip: 'Agendar evento',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 18, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (async.isLoading && eventosHoy.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (async.hasError && eventosHoy.isEmpty)
            ErrorEnTarjeta(
              mensaje: mensajeDeError(async.error!),
              onReintentar: () =>
                  ref.invalidate(eventosEnRangoProvider(rangoHoy())),
            )
          else if (eventosHoy.isEmpty)
            const _EmptyHint(
              icon: Icons.event_available_outlined,
              title: 'Sin eventos para hoy.',
              subtitle: 'Toca + para agendar. Tu día aparecerá aquí, en orden.',
            )
          else
            for (final e in eventosHoy)
              _EventoHoyRow(
                evento: e,
                onTap: () => mostrarEditorEvento(context, ref, existente: e),
                onMenu: (op) {
                  final acc = ref.read(agendaAccionesProvider);
                  accionSegura(context, () async {
                    if (op == 'eliminar') {
                      await acc.eliminar(e.id);
                    } else {
                      await acc.cambiarEstado(e.id, op);
                    }
                  });
                },
              ),
        ],
      ),
    );
  }
}

class _EventoHoyRow extends StatelessWidget {
  const _EventoHoyRow({
    required this.evento,
    required this.onTap,
    required this.onMenu,
  });

  final Evento evento;
  final VoidCallback onTap;
  final ValueChanged<String> onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tachado = evento.realizado || evento.cancelado;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                evento.todoElDia ? '— —' : _horaCorta(evento.inicio),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                evento.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: tachado ? TextDecoration.lineThrough : null,
                  color: tachado ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              tooltip: 'Opciones',
              onSelected: onMenu,
              itemBuilder: (_) => [
                if (!evento.realizado)
                  const PopupMenuItem<String>(
                    value: 'realizado',
                    child: Row(children: [
                      Icon(Icons.check_circle_outline, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Text('Marcar realizado'),
                    ]),
                  )
                else
                  const PopupMenuItem<String>(
                    value: 'pendiente',
                    child: Row(children: [
                      Icon(Icons.radio_button_unchecked, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Text('Marcar pendiente'),
                    ]),
                  ),
                if (!evento.cancelado)
                  const PopupMenuItem<String>(
                    value: 'cancelado',
                    child: Row(children: [
                      Icon(Icons.block, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Text('Cancelar'),
                    ]),
                  ),
                const PopupMenuItem<String>(
                  value: 'eliminar',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text('Eliminar'),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _horaCorta(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _ProyectoPrincipal extends ConsumerWidget {
  const _ProyectoPrincipal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proyectoPrincipalProvider);
    final p = async.valueOrNull;

    if (async.hasError && p == null) {
      return VitaCard(
        padding: _kCardPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('PROYECTO PRINCIPAL'),
            const SizedBox(height: AppSpacing.md),
            ErrorEnTarjeta(
              mensaje: mensajeDeError(async.error!),
              onReintentar: () => ref.invalidate(proyectoPrincipalProvider),
            ),
          ],
        ),
      );
    }

    if (async.isLoading && p == null) {
      return const VitaCard(
        padding: _kCardPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow('PROYECTO PRINCIPAL'),
            SizedBox(height: AppSpacing.md),
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      );
    }

    if (p == null) {
      return VitaCard(
        padding: _kCardPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('PROYECTO PRINCIPAL'),
            const SizedBox(height: AppSpacing.sm),
            const _EmptyHint(
              icon: Icons.flag_outlined,
              title: 'Todavía no elegiste tu proyecto principal.',
              subtitle:
                  'Cuando lo elijas, verás aquí tu progreso y el próximo paso.',
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/proyectos'),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.accent),
                child: const Text('Elegir proyecto'),
              ),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tareas = ref.watch(tareasDeProyectoProvider(p.id)).valueOrNull ??
        const <ProjectTask>[];
    final progreso = p.progresoCon(tareas);
    final proximo = ref.watch(proximoPasoProvider(p.id)).valueOrNull;
    final tienePasos = p.tienePasos(tareas);
    final textoProximo = proximo != null
        ? proximo.texto
        : (tienePasos ? 'Todos los pasos completos' : 'Agrega tu primer paso');
    final bitacora = ref.watch(bitacoraDeProyectoProvider(p.id)).valueOrNull ??
        const <ProjectLogEntry>[];
    ProjectLogEntry? ultimo;
    for (final e in bitacora) {
      if (e.tipo == 'avance' || e.tipo == 'hito_completado') {
        ultimo = e;
        break;
      }
    }
    final u = ultimo;

    return VitaCard(
      padding: _kCardPad,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProyectoDetalleScreen(proyecto: p)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Eyebrow('PROYECTO PRINCIPAL'),
                const Spacer(),
                Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                AnilloProgreso(progreso: progreso, tamano: 52, grosor: 5),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (p.objetivo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(p.objetivo!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.arrow_forward,
                    size: 15, color: AppColors.accentSoft),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(textoProximo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (u != null && u.texto != null && u.texto!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Último: ${u.texto!}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: Builder(builder: (context) {
                // 3 estados: sin pasos / con próximo paso / todos completos.
                if (!tienePasos) {
                  return FilledButton.icon(
                    onPressed: () => mostrarEditorTarea(context, ref,
                        projectId: p.id, tipoInicial: 'paso'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar paso'),
                  );
                }
                if (proximo != null) {
                  return FilledButton.icon(
                    onPressed: () => avanzarProyecto(context, ref,
                        projectId: p.id, proximo: proximo),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Avanzar'),
                  );
                }
                // Hay pasos y todos están completos => Completar proyecto.
                return FilledButton.icon(
                  onPressed: () => accionSegura(
                    context,
                    () => ref
                        .read(proyectosAccionesProvider)
                        .completarProyecto(p.id),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Completar proyecto'),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta secundaria — Hábitos (real, reutiliza el controlador existente).
class _Habitos extends ConsumerWidget {
  const _Habitos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitosAsync = ref.watch(habitosControllerProvider);

    return VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Eyebrow('HÁBITOS'),
              IconButton(
                tooltip: 'Administrar hábitos',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.tune, size: 18, color: AppColors.accent),
                onPressed: () => _administrarHabitos(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          habitosAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorEnTarjeta(
              mensaje: mensajeDeError(e),
              onReintentar: () => ref.invalidate(habitosControllerProvider),
            ),
            data: (habitos) {
              if (habitos.isEmpty) {
                return const _EmptyHint(
                  icon: Icons.check_circle_outline,
                  title: 'Aún no tienes hábitos.',
                  subtitle: 'Empieza con pocos; menos es más.',
                );
              }
              // Sin contador "x de y": es un marcador, y los marcadores generan
              // culpa. La usuaria ve sus hábitos, no su nota del día.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final h in habitos)
                    _HabitoRow(
                      habito: h,
                      onTap: () => accionSegura(
                        context,
                        () => ref
                            .read(habitosControllerProvider.notifier)
                            .alternar(h),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Hoja para administrar hábitos: lista con editar/quitar + agregar.
Future<void> _administrarHabitos(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final theme = Theme.of(context);
        final habitos = ref.watch(habitosControllerProvider).valueOrNull ??
            const <Habito>[];
        return Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
              AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tus hábitos',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              for (final h in habitos)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(h.emoji ?? '•',
                      style: const TextStyle(fontSize: 18)),
                  title: Text(h.nombre),
                  subtitle: h.hora != null ? Text(h.hora!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () =>
                            _dialogoHabito(context, ref, existente: h),
                      ),
                      IconButton(
                        tooltip: 'Quitar',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => accionSegura(
                          context,
                          () => ref
                              .read(habitosControllerProvider.notifier)
                              .eliminar(h.id),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _dialogoHabito(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar hábito'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Diálogo para crear o editar un hábito (emoji + nombre + hora).
Future<void> _dialogoHabito(BuildContext context, WidgetRef ref,
    {Habito? existente}) async {
  final nombre = TextEditingController(text: existente?.nombre ?? '');
  final emoji = TextEditingController(text: existente?.emoji ?? '');
  final hora = TextEditingController(text: existente?.hora ?? '');
  final esEdicion = existente != null;

  final guardar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(esEdicion ? 'Editar hábito' : 'Nuevo hábito'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                child: TextField(
                  controller: emoji,
                  decoration: const InputDecoration(hintText: '💊'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: nombre,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: hora,
            decoration: const InputDecoration(
                labelText: 'Hora (opcional, ej. 9:00 PM)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );

  final n = nombre.text;
  final e = emoji.text;
  final h = hora.text;
  nombre.dispose();
  emoji.dispose();
  hora.dispose();
  if (guardar != true || n.trim().isEmpty || !context.mounted) return;

  await accionSegura(context, () async {
    final ctrl = ref.read(habitosControllerProvider.notifier);
    if (esEdicion) {
      await ctrl.editar(existente.id, nombre: n, emoji: e, hora: h);
    } else {
      await ctrl.crear(nombre: n, emoji: e, hora: h);
    }
  });
}

// ============================ PIEZAS ============================

// El eyebrow ahora vive en core/widgets/eyebrow.dart.

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vacio = value == '—';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: vacio ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Estado vacío. Sin `action`: un texto que parece enlace pero no lo es enseña
/// a la usuaria que tocar la pantalla no sirve de nada.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
      ],
    );
  }
}

class _HabitoRow extends StatelessWidget {
  const _HabitoRow({required this.habito, required this.onTap});
  final Habito habito;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = habito.hecho;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Text(habito.emoji ?? '•', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                habito.nombre,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              color:
                  done ? AppColors.accent : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================ util ============================

String _fechaLarga(DateTime d) {
  const dias = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];
  const meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre'
  ];
  final dia = dias[d.weekday - 1];
  final mes = meses[d.month - 1];
  final capit = dia[0].toUpperCase() + dia.substring(1);
  return '$capit ${d.day} de $mes';
}

// ============================ REGISTRO ESTADO ============================

class _RegistrarEstadoSheet extends ConsumerStatefulWidget {
  const _RegistrarEstadoSheet({this.actual});
  final EstadoHoy? actual;

  @override
  ConsumerState<_RegistrarEstadoSheet> createState() =>
      _RegistrarEstadoSheetState();
}

class _RegistrarEstadoSheetState extends ConsumerState<_RegistrarEstadoSheet> {
  int? _energia;
  int? _animo;
  int? _sueno; // 1 mal, 2 regular, 3 bien
  late final TextEditingController _horas;
  late final TextEditingController _peso;
  bool _mostrarPeso = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.actual;
    _energia = a?.energia;
    _animo = a?.animo;
    _sueno = a?.suenoCalidad;
    _horas = TextEditingController(
        text: a?.suenoHoras != null ? _numEs(a!.suenoHoras!) : '');
    _peso = TextEditingController();
    // El peso solo se sugiere si aún no se registró esta semana.
    _mostrarPeso = a != null && !a.pesoEstaSemana;
  }

  @override
  void dispose() {
    _horas.dispose();
    _peso.dispose();
    super.dispose();
  }

  double? _parse(String t) {
    final limpio = t.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;
    return double.tryParse(limpio);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final ctrl = ref.read(estadoControllerProvider.notifier);
      await ctrl.registrarDiario(
        energia: _energia,
        animo: _animo,
        suenoCalidad: _sueno,
        suenoHoras: _parse(_horas.text),
      );
      final peso = _parse(_peso.text);
      if (peso != null) await ctrl.registrarPeso(peso);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo guardar. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Cómo estás hoy?',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('Registra solo cómo te sientes hoy.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
            _CampoLabel('Energía del día'),
            const SizedBox(height: AppSpacing.sm),
            _Escala(
              value: _energia,
              onChanged: (v) => setState(() => _energia = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CampoLabel('Ánimo del día'),
            const SizedBox(height: AppSpacing.sm),
            _Escala(
              value: _animo,
              onChanged: (v) => setState(() => _animo = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CampoLabel('Sueño'),
            const SizedBox(height: AppSpacing.sm),
            _SuenoSelector(
              value: _sueno,
              onChanged: (v) => setState(() => _sueno = v),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _horas,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Horas de sueño (opcional)',
                suffixText: 'h',
                border: OutlineInputBorder(),
              ),
            ),
            if (_mostrarPeso) ...[
              const SizedBox(height: AppSpacing.lg),
              _CampoLabel('Pesaje semanal · opcional'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _peso,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso',
                  suffixText: 'kg',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _mostrarPeso = true),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Registrar peso'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoLabel extends StatelessWidget {
  const _CampoLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style:
            theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600));
  }
}

/// Selector 1–5 (energía / ánimo). Pulsar de nuevo el mismo número lo limpia.
class _Escala extends StatelessWidget {
  const _Escala({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(value == i ? null : i),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == i
                      ? AppColors.accent
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Text(
                  '$i',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value == i
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Selector de cualidad de sueño: Bien (3) / Regular (2) / Mal (1).
class _SuenoSelector extends StatelessWidget {
  const _SuenoSelector({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  static const _opciones = [
    (3, 'Bien'),
    (2, 'Regular'),
    (1, 'Mal'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < _opciones.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  onChanged(value == _opciones[i].$1 ? null : _opciones[i].$1),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == _opciones[i].$1
                      ? AppColors.accent
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Text(
                  _opciones[i].$2,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value == _opciones[i].$1
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
