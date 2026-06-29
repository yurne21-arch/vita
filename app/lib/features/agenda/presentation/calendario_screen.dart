import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/agenda_repository.dart';
import 'agenda_controller.dart';
import 'evento_editor.dart';

enum _Vista { hoy, semana, mes }

class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  _Vista _vista = _Vista.hoy;
  late DateTime _mesAncla; // primer día del mes visible
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
      // Si hoy cae en el mes nuevo, selecciónalo; si no, el día 1.
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
                    return _ListaDia(
                      eventos: eventos,
                      onTap: (e) =>
                          mostrarEditorEvento(context, ref, existente: e),
                      onMenu: _accion,
                      vacioTexto: 'Sin eventos para hoy.',
                    );
                  case _Vista.semana:
                    return _VistaSemana(
                      eventos: eventos,
                      onTap: (e) =>
                          mostrarEditorEvento(context, ref, existente: e),
                      onMenu: _accion,
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

// ---------------- Vista Semana ----------------

class _VistaSemana extends StatelessWidget {
  const _VistaSemana({
    required this.eventos,
    required this.onTap,
    required this.onMenu,
  });

  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now();
    final base = DateTime(n.year, n.month, n.day);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, 96),
      itemCount: 7,
      itemBuilder: (_, i) {
        final dia = base.add(Duration(days: i));
        final delDia = eventos.where((e) => _mismoDia(e.inicio, dia)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.lg, bottom: AppSpacing.sm),
              child: Text(
                _etiquetaDia(dia, i),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: i == 0 ? AppColors.olive : null,
                    ),
              ),
            ),
            if (delDia.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('Sin eventos.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              )
            else
              for (final e in delDia)
                _EventoTile(evento: e, onTap: () => onTap(e), onMenu: (op) => onMenu(e, op)),
            const Divider(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

// ---------------- Vista Día (Hoy) ----------------

class _ListaDia extends StatelessWidget {
  const _ListaDia({
    required this.eventos,
    required this.onTap,
    required this.onMenu,
    required this.vacioTexto,
  });

  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;
  final String vacioTexto;

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(vacioTexto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
      children: [
        for (final e in eventos)
          _EventoTile(
              evento: e, onTap: () => onTap(e), onMenu: (op) => onMenu(e, op)),
      ],
    );
  }
}

// ---------------- Vista Mes ----------------

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
    final conEventos = <String>{
      for (final e in eventos) _clave(e.inicio),
    };
    final delDia =
        eventos.where((e) => _mismoDia(e.inicio, diaSeleccionado)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, 96),
      children: [
        // Encabezado mes con navegación
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onMesAnterior,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_mesNombre(mesAncla.month)} ${mesAncla.year}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            IconButton(
              onPressed: onMesSiguiente,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Etiquetas de día
        Row(
          children: [
            for (final d in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
              Expanded(
                child: Center(
                  child: Text(d,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Cuadrícula 6x7
        for (var fila = 0; fila < 6; fila++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                _CeldaDia(
                  dia: primerGrid.add(Duration(days: fila * 7 + col)),
                  mesActual: mesAncla.month,
                  hoy: hoy,
                  seleccionado: _mismoDia(
                      primerGrid.add(Duration(days: fila * 7 + col)),
                      diaSeleccionado),
                  tieneEventos: conEventos.contains(_clave(
                      primerGrid.add(Duration(days: fila * 7 + col)))),
                  onTap: () =>
                      onDia(primerGrid.add(Duration(days: fila * 7 + col))),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        // Eventos del día seleccionado
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _fechaLarga(diaSeleccionado),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: onCrearEnDia,
                style: TextButton.styleFrom(foregroundColor: AppColors.olive),
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
                evento: e, onTap: () => onTap(e), onMenu: (op) => onMenu(e, op)),
      ],
    );
  }
}

class _CeldaDia extends StatelessWidget {
  const _CeldaDia({
    required this.dia,
    required this.mesActual,
    required this.hoy,
    required this.seleccionado,
    required this.tieneEventos,
    required this.onTap,
  });

  final DateTime dia;
  final int mesActual;
  final DateTime hoy;
  final bool seleccionado;
  final bool tieneEventos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esDeMes = dia.month == mesActual;
    final esHoy = _mismoDia(dia, hoy);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: seleccionado
                  ? AppColors.olive
                  : (esHoy
                      ? const Color(0x146B7A4F)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: esHoy && !seleccionado
                  ? Border.all(color: AppColors.olive)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${dia.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: esHoy ? FontWeight.w700 : FontWeight.w500,
                    color: seleccionado
                        ? Colors.white
                        : (esDeMes
                            ? null
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4)),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tieneEventos
                        ? (seleccionado ? Colors.white : AppColors.olive)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Tile de evento + menú ----------------

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
              width: 52,
              child: Text(
                evento.todoElDia ? 'Todo\nel día' : _horaDe(evento.inicio),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PuntoImportancia(importancia: evento.importancia),
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
                  if (evento.categoria != null)
                    Text(evento.categoria!,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
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

class _PuntoImportancia extends StatelessWidget {
  const _PuntoImportancia({required this.importancia});
  final String importancia;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (importancia) {
      case 'critico':
        color = AppColors.danger;
      case 'importante':
        color = const Color(0xFFC9933F); // ámbar discreto
      default:
        color = Theme.of(context).colorScheme.outlineVariant;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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

// ---------------- utilidades ----------------

bool _mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _clave(DateTime d) => '${d.year}-${d.month}-${d.day}';

String _horaDe(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
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
