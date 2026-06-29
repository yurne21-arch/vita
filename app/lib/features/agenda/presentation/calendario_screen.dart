import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/agenda_repository.dart';
import 'agenda_controller.dart';
import 'evento_editor.dart';

enum _Vista { hoy, semana, mes }

/// Color sutil por categoría (apagado, no saturado).
Color colorCategoria(String? c) {
  switch (c) {
    case 'Trabajo / Empresa':
      return const Color(0xFF4A6B8A); // azul apagado
    case 'Personal':
      return const Color(0xFF6B7A4F); // oliva
    case 'Familia':
      return const Color(0xFFB07A5A); // terracota suave
    case 'Salud':
      return const Color(0xFF4E7A51); // verde salud
    case 'Colegio / Juan Miguel':
      return const Color(0xFF6F6391); // índigo suave
    case 'Finanzas':
      return const Color(0xFF9A8231); // dorado apagado
    case 'Viaje':
      return const Color(0xFF3F7E78); // teal
    case 'Otro':
      return const Color(0xFF7A7568); // gris cálido
    default:
      return const Color(0xFF7A7568);
  }
}

class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  _Vista _vista = _Vista.mes;
  late DateTime _mesAncla;
  late DateTime _diaSeleccionado;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _mesAncla = DateTime(n.year, n.month, 1);
    _diaSeleccionado = DateTime(n.year, n.month, n.day);
  }

  DateTime get _hoy {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _primerDiaGrid(DateTime mes) =>
      mes.subtract(Duration(days: mes.weekday - 1));

  RangoFechas _rangoActivo() {
    switch (_vista) {
      case _Vista.hoy:
        return rangoHoy();
      case _Vista.semana:
        return rangoSemana();
      case _Vista.mes:
        final ini = _primerDiaGrid(_mesAncla);
        return RangoFechas(ini, ini.add(const Duration(days: 42)));
    }
  }

  void _mes(int delta) {
    setState(() {
      _mesAncla = DateTime(_mesAncla.year, _mesAncla.month + delta, 1);
      final h = _hoy;
      _diaSeleccionado =
          (h.year == _mesAncla.year && h.month == _mesAncla.month)
              ? h
              : _mesAncla;
    });
  }

  void _accion(Evento e, String op) {
    final acc = ref.read(agendaAccionesProvider);
    if (op == 'realizado') {
      acc.cambiarEstado(e.id, 'realizado');
    } else if (op == 'pendiente') {
      acc.cambiarEstado(e.id, 'pendiente');
    } else if (op == 'cancelado') {
      acc.cambiarEstado(e.id, 'cancelado');
    } else if (op == 'eliminar') {
      acc.eliminar(e.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventosEnRangoProvider(_rangoActivo()));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarEditorEvento(context, ref,
            fechaSugerida: _vista == _Vista.mes ? _diaSeleccionado : _hoy),
        icon: const Icon(Icons.add),
        label: const Text('Evento'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_Vista>(
                segments: const [
                  ButtonSegment(value: _Vista.hoy, label: Text('Hoy')),
                  ButtonSegment(value: _Vista.semana, label: Text('Semana')),
                  ButtonSegment(value: _Vista.mes, label: Text('Mes')),
                ],
                selected: {_vista},
                onSelectionChanged: (s) => setState(() => _vista = s.first),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text('No se pudo cargar tu calendario.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
              data: (eventos) {
                switch (_vista) {
                  case _Vista.hoy:
                    return _VistaHoy(
                      eventos: eventos,
                      onTap: (e) =>
                          mostrarEditorEvento(context, ref, existente: e),
                      onMenu: _accion,
                    );
                  case _Vista.semana:
                    return _VistaSemana(
                      eventos: eventos,
                      onTap: (e) =>
                          mostrarEditorEvento(context, ref, existente: e),
                      onMenu: _accion,
                      onCrearDia: (d) => mostrarEditorEvento(context, ref,
                          fechaSugerida: d),
                    );
                  case _Vista.mes:
                    return _VistaMes(
                      mesAncla: _mesAncla,
                      hoy: _hoy,
                      diaSeleccionado: _diaSeleccionado,
                      eventos: eventos,
                      onMesAnterior: () => _mes(-1),
                      onMesSiguiente: () => _mes(1),
                      onDia: (d) => setState(() => _diaSeleccionado = d),
                      onCrearEnDia: () => mostrarEditorEvento(context, ref,
                          fechaSugerida: _diaSeleccionado),
                      onTap: (e) =>
                          mostrarEditorEvento(context, ref, existente: e),
                      onMenu: _accion,
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== VISTA HOY ======================

class _VistaHoy extends StatelessWidget {
  const _VistaHoy({
    required this.eventos,
    required this.onTap,
    required this.onMenu,
  });

  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (eventos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_outlined,
                  size: 36, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.sm),
              Text('Sin eventos para hoy.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xs),
              Text('Toca el botón + para agendar.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
      children: [
        for (final e in eventos)
          _EventoTile(
              evento: e, onTap: () => onTap(e), onMenu: (op) => onMenu(e, op)),
      ],
    );
  }
}

// ====================== VISTA SEMANA ======================

class _VistaSemana extends StatelessWidget {
  const _VistaSemana({
    required this.eventos,
    required this.onTap,
    required this.onMenu,
    required this.onCrearDia,
  });

  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;
  final ValueChanged<DateTime> onCrearDia;

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now();
    final base = DateTime(n.year, n.month, n.day);
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = c.maxWidth >= 760;
        if (ancho) {
          return _SemanaColumnas(
            base: base,
            eventos: eventos,
            onTap: onTap,
            onCrearDia: onCrearDia,
          );
        }
        return _SemanaLista(
          base: base,
          eventos: eventos,
          onTap: onTap,
          onMenu: onMenu,
        );
      },
    );
  }
}

class _SemanaLista extends StatelessWidget {
  const _SemanaLista({
    required this.base,
    required this.eventos,
    required this.onTap,
    required this.onMenu,
  });

  final DateTime base;
  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
      itemCount: 7,
      itemBuilder: (_, i) {
        final dia = base.add(Duration(days: i));
        final delDia = eventos.where((e) => _mismoDia(e.inicio, dia)).toList();
        final vacio = delDia.isEmpty;
        return Container(
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          padding: EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md,
              vacio ? AppSpacing.sm : AppSpacing.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: vacio ? 0.25 : 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(
              color: i == 0
                  ? AppColors.olive.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _etiquetaDia(dia, i),
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: i == 0 ? AppColors.olive : null),
                  ),
                  const Spacer(),
                  if (!vacio)
                    Text('${delDia.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              if (vacio)
                Text('Sin eventos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant))
              else
                for (final e in delDia)
                  _EventoTile(
                      evento: e,
                      onTap: () => onTap(e),
                      onMenu: (op) => onMenu(e, op)),
            ],
          ),
        );
      },
    );
  }
}

class _SemanaColumnas extends StatelessWidget {
  const _SemanaColumnas({
    required this.base,
    required this.eventos,
    required this.onTap,
    required this.onCrearDia,
  });

  final DateTime base;
  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final ValueChanged<DateTime> onCrearDia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ColumnaDia(
                  dia: base.add(Duration(days: i)),
                  esHoy: i == 0,
                  eventos: eventos
                      .where((e) => _mismoDia(e.inicio, base.add(Duration(days: i))))
                      .toList(),
                  onTap: onTap,
                  onCrear: () => onCrearDia(base.add(Duration(days: i))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColumnaDia extends StatelessWidget {
  const _ColumnaDia({
    required this.dia,
    required this.esHoy,
    required this.eventos,
    required this.onTap,
    required this.onCrear,
  });

  final DateTime dia;
  final bool esHoy;
  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: esHoy ? 0.55 : 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(
          color: esHoy
              ? AppColors.olive.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_diaCorto(dia.weekday),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
                Text('${dia.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: esHoy ? AppColors.olive : null)),
              ],
            ),
          ),
          if (eventos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('—',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            )
          else
            for (final e in eventos)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: _EventoChip(
                    evento: e,
                    onTap: () => onTap(e)),
              ),
          InkWell(
            onTap: onCrear,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Icon(Icons.add,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text('Agregar',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== VISTA MES ======================

class _VistaMes extends StatelessWidget {
  const _VistaMes({
    required this.mesAncla,
    required this.hoy,
    required this.diaSeleccionado,
    required this.eventos,
    required this.onMesAnterior,
    required this.onMesSiguiente,
    required this.onDia,
    required this.onCrearEnDia,
    required this.onTap,
    required this.onMenu,
  });

  final DateTime mesAncla;
  final DateTime hoy;
  final DateTime diaSeleccionado;
  final List<Evento> eventos;
  final VoidCallback onMesAnterior;
  final VoidCallback onMesSiguiente;
  final ValueChanged<DateTime> onDia;
  final VoidCallback onCrearEnDia;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primerGrid = mesAncla.subtract(Duration(days: mesAncla.weekday - 1));
    final delDia =
        eventos.where((e) => _mismoDia(e.inicio, diaSeleccionado)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: onMesAnterior,
                icon: const Icon(Icons.chevron_left)),
            Text('${_mesNombre(mesAncla.month)} ${mesAncla.year}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            IconButton(
                onPressed: onMesSiguiente,
                icon: const Icon(Icons.chevron_right)),
          ],
        ),
        Row(
          children: [
            for (final d in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(d,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
        for (var fila = 0; fila < 6; fila++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _CeldaMes(
                    dia: primerGrid.add(Duration(days: fila * 7 + col)),
                    mesActual: mesAncla.month,
                    hoy: hoy,
                    seleccionado: _mismoDia(
                        primerGrid.add(Duration(days: fila * 7 + col)),
                        diaSeleccionado),
                    eventos: eventos
                        .where((e) => _mismoDia(e.inicio,
                            primerGrid.add(Duration(days: fila * 7 + col))))
                        .toList(),
                    onTap: () =>
                        onDia(primerGrid.add(Duration(days: fila * 7 + col))),
                  ),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(_fechaLarga(diaSeleccionado),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: onCrearEnDia,
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.olive),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Crear'),
              ),
            ],
          ),
        ),
        if (delDia.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text('Sin eventos este día.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          )
        else
          for (final e in delDia)
            _EventoTile(
                evento: e,
                onTap: () => onTap(e),
                onMenu: (op) => onMenu(e, op)),
      ],
    );
  }
}

class _CeldaMes extends StatelessWidget {
  const _CeldaMes({
    required this.dia,
    required this.mesActual,
    required this.hoy,
    required this.seleccionado,
    required this.eventos,
    required this.onTap,
  });

  final DateTime dia;
  final int mesActual;
  final DateTime hoy;
  final bool seleccionado;
  final List<Evento> eventos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esDeMes = dia.month == mesActual;
    final esHoy = _mismoDia(dia, hoy);
    const maxBarras = 2;
    final extra = eventos.length - maxBarras;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 82,
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: seleccionado
              ? AppColors.olive.withValues(alpha: 0.14)
              : (esDeMes
                  ? theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionado
                ? AppColors.olive
                : (esHoy
                    ? AppColors.olive.withValues(alpha: 0.7)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            width: seleccionado ? 1.4 : 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Número de día
            SizedBox(
              height: 18,
              child: Align(
                alignment: Alignment.centerLeft,
                child: esHoy
                    ? Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.olive,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${dia.day}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      )
                    : Text('${dia.day}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: esDeMes
                              ? null
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                        )),
              ),
            ),
            const SizedBox(height: 1),
            // Eventos (barras compactas)
            for (final e in eventos.take(maxBarras))
              _MiniEventoBar(evento: e),
            if (extra > 0)
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 1),
                child: Text('+$extra más',
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniEventoBar extends StatelessWidget {
  const _MiniEventoBar({required this.evento});
  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = colorCategoria(evento.categoria);
    final critico = evento.importancia == 'critico';
    final importante = evento.importancia == 'importante';
    final tachado = evento.realizado || evento.cancelado;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: cat.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(3),
        border: Border(left: BorderSide(color: cat, width: 2.5)),
      ),
      child: Row(
        children: [
          if (critico)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 2),
              decoration: const BoxDecoration(
                  color: AppColors.danger, shape: BoxShape.circle),
            ),
          Expanded(
            child: Text(
              evento.todoElDia
                  ? evento.titulo
                  : '${_horaDe(evento.inicio)} ${evento.titulo}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9.5,
                height: 1.1,
                fontWeight: importante ? FontWeight.w700 : FontWeight.w500,
                decoration: tachado ? TextDecoration.lineThrough : null,
                color: tachado
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== TILES DE EVENTO ======================

/// Chip compacto para columnas (semana desktop).
class _EventoChip extends StatelessWidget {
  const _EventoChip({
    required this.evento,
    required this.onTap,
  });

  final Evento evento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = colorCategoria(evento.categoria);
    final critico = evento.importancia == 'critico';
    final importante = evento.importancia == 'importante';
    final tachado = evento.realizado || evento.cancelado;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: cat.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: cat, width: importante || critico ? 4 : 2.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!evento.todoElDia)
              Text(_horaDe(evento.inicio),
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant)),
            Text(
              evento.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: tachado ? TextDecoration.lineThrough : null,
                color: tachado ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
            if (critico)
              Text('Crítico',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.danger, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

/// Tile completo para listas (Hoy, Semana móvil, detalle de día en Mes).
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
    final cat = colorCategoria(evento.categoria);
    final done = evento.realizado;
    final cancel = evento.cancelado;
    final tachado = done || cancel;
    final critico = evento.importancia == 'critico';
    final importante = evento.importancia == 'importante';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: critico
                ? AppColors.danger.withValues(alpha: 0.06)
                : (importante
                    ? AppColors.olive.withValues(alpha: 0.05)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border(
              left: BorderSide(
                  color: cat, width: importante || critico ? 5 : 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  evento.todoElDia ? 'Todo\nel día' : _horaDe(evento.inicio),
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            evento.titulo,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration:
                                  tachado ? TextDecoration.lineThrough : null,
                              color: tachado
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                        if (critico) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const _EtiquetaCritico(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration:
                              BoxDecoration(color: cat, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            evento.categoria ?? 'Sin categoría',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    if (evento.descripcion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(evento.descripcion!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
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
      ),
    );
  }
}

class _EtiquetaCritico extends StatelessWidget {
  const _EtiquetaCritico();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('Crítico',
          style: TextStyle(
              color: AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
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

// ====================== utilidades ======================

bool _mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _horaDe(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _diaCorto(int weekday) {
  const d = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  return d[weekday - 1];
}

String _mesNombre(int m) {
  const meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  return meses[m - 1];
}

String _etiquetaDia(DateTime dia, int indice) {
  if (indice == 0) return 'Hoy';
  if (indice == 1) return 'Mañana';
  const dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
  ];
  final nombre = dias[dia.weekday - 1];
  final capit = nombre[0].toUpperCase() + nombre.substring(1);
  return '$capit ${dia.day} de ${_mesNombre(dia.month).toLowerCase()}';
}

String _fechaLarga(DateTime d) {
  const dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
  ];
  final dia = dias[d.weekday - 1];
  final capit = dia[0].toUpperCase() + dia.substring(1);
  return '$capit ${d.day} de ${_mesNombre(d.month).toLowerCase()}';
}
