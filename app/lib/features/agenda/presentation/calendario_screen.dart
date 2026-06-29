import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/agenda_repository.dart';
import 'agenda_controller.dart';
import 'evento_editor.dart';

/// Vista de semana: próximos 7 días, agrupados por día.
class CalendarioScreen extends ConsumerWidget {
  const CalendarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(agendaControllerProvider);

    final hoy = DateTime.now();
    final base = DateTime(hoy.year, hoy.month, hoy.day);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            mostrarEditorEvento(context, ref, fechaSugerida: base),
        icon: const Icon(Icons.add),
        label: const Text('Evento'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('No se pudo cargar tu calendario.',
                style: theme.textTheme.bodyMedium),
          ),
        ),
        data: (eventos) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
            itemCount: 7,
            itemBuilder: (_, i) {
              final dia = base.add(Duration(days: i));
              final delDia = eventos.where((e) {
                final d = e.inicio;
                return d.year == dia.year &&
                    d.month == dia.month &&
                    d.day == dia.day;
              }).toList();
              return _DiaSeccion(
                dia: dia,
                indice: i,
                eventos: delDia,
              );
            },
          );
        },
      ),
    );
  }
}

class _DiaSeccion extends ConsumerWidget {
  const _DiaSeccion({
    required this.dia,
    required this.indice,
    required this.eventos,
  });

  final DateTime dia;
  final int indice;
  final List<Evento> eventos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: AppSpacing.lg, bottom: AppSpacing.sm),
          child: Text(
            _etiquetaDia(dia, indice),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: indice == 0 ? AppColors.olive : null,
            ),
          ),
        ),
        if (eventos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('Sin eventos.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          )
        else
          for (final e in eventos)
            _EventoTile(
              evento: e,
              onTap: () =>
                  mostrarEditorEvento(context, ref, existente: e),
              onMenu: (op) => _accionEvento(ref, e, op),
            ),
        const Divider(height: AppSpacing.lg),
      ],
    );
  }
}

void _accionEvento(WidgetRef ref, Evento e, String op) {
  final ctrl = ref.read(agendaControllerProvider.notifier);
  if (op == 'realizado') {
    ctrl.cambiarEstado(e.id, 'realizado');
  } else if (op == 'pendiente') {
    ctrl.cambiarEstado(e.id, 'pendiente');
  } else if (op == 'cancelado') {
    ctrl.cambiarEstado(e.id, 'cancelado');
  } else if (op == 'eliminar') {
    ctrl.eliminar(e.id);
  }
}

class _EventoTile extends StatelessWidget {
  const _EventoTile({
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
    final done = evento.realizado;
    final cancel = evento.cancelado;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                evento.todoElDia ? 'Todo\nel día' : _horaDe(evento.inicio),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.titulo,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: (done || cancel)
                          ? TextDecoration.lineThrough
                          : null,
                      color: (done || cancel)
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  if (evento.descripcion != null)
                    Text(evento.descripcion!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  if (cancel)
                    Text('Cancelado',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.danger)),
                ],
              ),
            ),
            _MenuEvento(evento: evento, onMenu: onMenu),
          ],
        ),
      ),
    );
  }
}

class _MenuEvento extends StatelessWidget {
  const _MenuEvento({required this.evento, required this.onMenu});
  final Evento evento;
  final ValueChanged<String> onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert,
          size: 20, color: theme.colorScheme.onSurfaceVariant),
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
    );
  }
}

String _horaDe(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _etiquetaDia(DateTime dia, int indice) {
  if (indice == 0) return 'Hoy';
  if (indice == 1) return 'Mañana';
  const dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
  ];
  const meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
  final nombre = dias[dia.weekday - 1];
  final capit = nombre[0].toUpperCase() + nombre.substring(1);
  return '$capit ${dia.day} de ${meses[dia.month - 1]}';
}
