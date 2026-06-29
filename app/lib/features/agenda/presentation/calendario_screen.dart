import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/agenda_repository.dart';
import 'agenda_controller.dart';
import 'evento_editor.dart';

enum _Vista { hoy, semana, mes }

/// Color sutil por categoría — paleta apagada, profesional (no arcoíris).
Color catColor(String? c) {
  switch (c) {
    case 'Trabajo / Empresa':
      return const Color(0xFF5E7A93); // azul pizarra
    case 'Personal':
      return const Color(0xFF7C8A5E); // salvia
    case 'Familia':
      return const Color(0xFFB08968); // arcilla
    case 'Salud':
      return const Color(0xFF5E9E83); // verde suave
    case 'Colegio / Juan Miguel':
      return const Color(0xFF8E7CA6); // lavanda
    case 'Finanzas':
      return const Color(0xFFC2A45A); // dorado apagado
    case 'Viaje':
      return const Color(0xFF5FA0A0); // cian apagado
    case 'Otro':
      return const Color(0xFF8A857A); // gris cálido
    default:
      return const Color(0xFF8A857A);
  }
}

const double _kPanelWidth = 340;
const double _kBpPanel = 900; // ≥ esto: panel lateral; si no, hoja inferior

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
    if (op == 'editar') {
      mostrarEditorEvento(context, ref, existente: e);
    } else if (op == 'realizado') {
      acc.cambiarEstado(e.id, 'realizado');
    } else if (op == 'pendiente') {
      acc.cambiarEstado(e.id, 'pendiente');
    } else if (op == 'cancelado') {
      acc.cambiarEstado(e.id, 'cancelado');
    } else if (op == 'eliminar') {
      acc.eliminar(e.id);
    }
  }

  void _toggleRealizado(Evento e) {
    ref
        .read(agendaAccionesProvider)
        .cambiarEstado(e.id, e.realizado ? 'pendiente' : 'realizado');
  }

  void _abrirHojaDia(List<Evento> delDia) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scroll) => _ContenidoDia(
          fecha: _diaSeleccionado,
          eventos: delDia,
          scrollController: scroll,
          onTap: (e) => mostrarEditorEvento(context, ref, existente: e),
          onMenu: _accion,
          onToggle: _toggleRealizado,
          onNuevo: () => mostrarEditorEvento(context, ref,
              fechaSugerida: _diaSeleccionado),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventosEnRangoProvider(_rangoActivo()));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: cs.surface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarEditorEvento(context, ref,
            fechaSugerida: _vista == _Vista.mes ? _diaSeleccionado : _hoy),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= _kBpPanel;
            return Column(
              children: [
                _SelectorVista(
                  vista: _vista,
                  onChanged: (v) => setState(() => _vista = v),
                ),
                Expanded(
                  child: async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _ErrorCarga(),
                    data: (eventos) => _cuerpo(eventos, wide),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cuerpo(List<Evento> eventos, bool wide) {
    switch (_vista) {
      case _Vista.hoy:
        return _VistaHoy(
          fecha: _hoy,
          eventos: eventos,
          onTap: (e) => mostrarEditorEvento(context, ref, existente: e),
          onMenu: _accion,
          onToggle: _toggleRealizado,
        );
      case _Vista.semana:
        return _VistaSemana(
          eventos: eventos,
          wide: wide,
          onTap: (e) => mostrarEditorEvento(context, ref, existente: e),
          onMenu: _accion,
          onToggle: _toggleRealizado,
          onCrearDia: (d) =>
              mostrarEditorEvento(context, ref, fechaSugerida: d),
        );
      case _Vista.mes:
        final delDia = eventos
            .where((e) => _mismoDia(e.inicio, _diaSeleccionado))
            .toList();
        return _VistaMes(
          mesAncla: _mesAncla,
          hoy: _hoy,
          diaSeleccionado: _diaSeleccionado,
          eventos: eventos,
          wide: wide,
          onMesAnterior: () => _mes(-1),
          onMesSiguiente: () => _mes(1),
          onDia: (d) {
            setState(() => _diaSeleccionado = d);
            if (!wide) {
              _abrirHojaDia(
                  eventos.where((e) => _mismoDia(e.inicio, d)).toList());
            }
          },
          panel: _ContenidoDia(
            fecha: _diaSeleccionado,
            eventos: delDia,
            onTap: (e) => mostrarEditorEvento(context, ref, existente: e),
            onMenu: _accion,
            onToggle: _toggleRealizado,
            onNuevo: () => mostrarEditorEvento(context, ref,
                fechaSugerida: _diaSeleccionado),
          ),
        );
    }
  }
}

// ====================== SELECTOR DE VISTA ======================

class _SelectorVista extends StatelessWidget {
  const _SelectorVista({required this.vista, required this.onChanged});
  final _Vista vista;
  final ValueChanged<_Vista> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final v in _Vista.values)
                _SegItem(
                  label: switch (v) {
                    _Vista.hoy => 'Hoy',
                    _Vista.semana => 'Semana',
                    _Vista.mes => 'Mes',
                  },
                  activo: v == vista,
                  onTap: () => onChanged(v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegItem extends StatelessWidget {
  const _SegItem(
      {required this.label, required this.activo, required this.onTap});
  final String label;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? AppColors.olive : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: activo ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text('No se pudo cargar tu calendario.',
            style: Theme.of(context).textTheme.bodyMedium),
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
    required this.wide,
    required this.onMesAnterior,
    required this.onMesSiguiente,
    required this.onDia,
    required this.panel,
  });

  final DateTime mesAncla;
  final DateTime hoy;
  final DateTime diaSeleccionado;
  final List<Evento> eventos;
  final bool wide;
  final VoidCallback onMesAnterior;
  final VoidCallback onMesSiguiente;
  final ValueChanged<DateTime> onDia;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primerGrid = mesAncla.subtract(Duration(days: mesAncla.weekday - 1));

    final calendario = Column(
      children: [
        _CabeceraMes(
          mesAncla: mesAncla,
          eventos: eventos,
          onAnterior: onMesAnterior,
          onSiguiente: onMesSiguiente,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _EncabezadoDias(),
                Expanded(
                  child: Column(
                    children: [
                      for (var fila = 0; fila < 6; fila++)
                        Expanded(
                          child: Row(
                            children: [
                              for (var col = 0; col < 7; col++)
                                Expanded(
                                  child: _CeldaMes(
                                    dia: primerGrid
                                        .add(Duration(days: fila * 7 + col)),
                                    mesActual: mesAncla.month,
                                    hoy: hoy,
                                    seleccionado: _mismoDia(
                                        primerGrid.add(
                                            Duration(days: fila * 7 + col)),
                                        diaSeleccionado),
                                    ultimaFila: fila == 5,
                                    ultimaCol: col == 6,
                                    eventos: eventos
                                        .where((e) => _mismoDia(
                                            e.inicio,
                                            primerGrid.add(Duration(
                                                days: fila * 7 + col))))
                                        .toList(),
                                    onTap: () => onDia(primerGrid
                                        .add(Duration(days: fila * 7 + col))),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!wide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: calendario,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: calendario),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(width: _kPanelWidth, child: panel),
        ],
      ),
    );
  }
}

class _CabeceraMes extends StatelessWidget {
  const _CabeceraMes({
    required this.mesAncla,
    required this.eventos,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final DateTime mesAncla;
  final List<Evento> eventos;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cats = <String>{
      for (final e in eventos)
        if (e.categoria != null) e.categoria!,
    }.toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          _BotonRedondo(icon: Icons.chevron_left, onTap: onAnterior),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${_mesNombre(mesAncla.month)} ${mesAncla.year}',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          const SizedBox(width: AppSpacing.sm),
          _BotonRedondo(icon: Icons.chevron_right, onTap: onSiguiente),
          const Spacer(),
          if (cats.isNotEmpty)
            Flexible(
              child: _Leyenda(categorias: cats),
            ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.categorias});
  final List<String> categorias;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.md,
      runSpacing: 4,
      children: [
        for (final c in categorias)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: catColor(c), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(c,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
      ],
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 20, color: cs.onSurface),
      ),
    );
  }
}

class _EncabezadoDias extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.5),
        border: Border(
            bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          for (final d in const ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: cs.onSurfaceVariant,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CeldaMes extends StatelessWidget {
  const _CeldaMes({
    required this.dia,
    required this.mesActual,
    required this.hoy,
    required this.seleccionado,
    required this.ultimaFila,
    required this.ultimaCol,
    required this.eventos,
    required this.onTap,
  });

  final DateTime dia;
  final int mesActual;
  final DateTime hoy;
  final bool seleccionado;
  final bool ultimaFila;
  final bool ultimaCol;
  final List<Evento> eventos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final esDeMes = dia.month == mesActual;
    final esHoy = _mismoDia(dia, hoy);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: seleccionado
              ? AppColors.olive.withValues(alpha: 0.16)
              : (esDeMes
                  ? Colors.transparent
                  : cs.surfaceContainerHighest.withValues(alpha: 0.18)),
          border: Border(
            right: ultimaCol
                ? BorderSide.none
                : BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
            bottom: ultimaFila
                ? BorderSide.none
                : BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Número de día (hoy: blanco en círculo oliva)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: esHoy
                      ? const BoxDecoration(
                          color: AppColors.olive, shape: BoxShape.circle)
                      : null,
                  child: Text(
                    '${dia.day}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: esHoy ? FontWeight.w700 : FontWeight.w600,
                      color: esHoy
                          ? Colors.white
                          : (esDeMes
                              ? cs.onSurface
                              : cs.onSurfaceVariant.withValues(alpha: 0.45)),
                    ),
                  ),
                ),
              ),
              // Eventos (capacidad según altura disponible)
              Expanded(
                child: _EventosCelda(
                  eventos: eventos,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eventos visibles dentro de la celda, según la altura disponible.
class _EventosCelda extends StatelessWidget {
  const _EventosCelda({required this.eventos});
  final List<Evento> eventos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const perBar = 19.0;
        final capacidad = (c.maxHeight / perBar).floor();
        if (capacidad <= 0) {
          // Muy poco espacio: puntos de categoría
          return Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 3,
              children: [
                for (final e in eventos.take(4))
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: catColor(e.categoria),
                        shape: BoxShape.circle),
                  ),
              ],
            ),
          );
        }
        final mostrarTodos = eventos.length <= capacidad;
        final cuantos = mostrarTodos ? eventos.length : capacidad - 1;
        final extra = eventos.length - cuantos;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in eventos.take(cuantos)) _BarraEvento(evento: e),
            if (!mostrarTodos && extra > 0)
              Padding(
                padding: const EdgeInsets.only(left: 3, top: 1),
                child: Text('+$extra más',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
          ],
        );
      },
    );
  }
}

class _BarraEvento extends StatelessWidget {
  const _BarraEvento({required this.evento});
  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = catColor(evento.categoria);
    final critico = evento.importancia == 'critico';
    final importante = evento.importancia == 'importante';
    final tachado = evento.realizado || evento.cancelado;

    return Container(
      height: 17,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.only(left: 5, right: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: c, width: 2.5)),
      ),
      child: Row(
        children: [
          if (critico)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 3),
              decoration: const BoxDecoration(
                  color: AppColors.danger, shape: BoxShape.circle),
            ),
          Expanded(
            child: Text(
              evento.todoElDia
                  ? evento.titulo
                  : '${_horaDe(evento.inicio)}  ${evento.titulo}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.0,
                fontWeight: importante ? FontWeight.w700 : FontWeight.w500,
                decoration: tachado ? TextDecoration.lineThrough : null,
                color: tachado ? cs.onSurfaceVariant : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== PANEL / HOJA DEL DÍA ======================

class _ContenidoDia extends StatelessWidget {
  const _ContenidoDia({
    required this.fecha,
    required this.eventos,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
    required this.onNuevo,
    this.scrollController,
  });

  final DateTime fecha;
  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;
  final ValueChanged<Evento> onToggle;
  final VoidCallback onNuevo;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final esPanel = scrollController == null;

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_diaSemana(fecha).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.oliveSoft,
                  )),
              const SizedBox(height: 2),
              Text(
                '${fecha.day} de ${_mesNombre(fecha.month).toLowerCase()}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
              ),
              const SizedBox(height: 2),
              Text(
                eventos.isEmpty
                    ? 'Sin eventos'
                    : '${eventos.length} ${eventos.length == 1 ? 'evento' : 'eventos'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: eventos.isEmpty
              ? _VacioDia()
              : ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                  children: [
                    for (final e in eventos)
                      _EventoCard(
                        evento: e,
                        onTap: () => onTap(e),
                        onMenu: (op) => onMenu(e, op),
                        onToggle: () => onToggle(e),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onNuevo,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.olive,
                side: BorderSide(color: AppColors.olive.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo evento'),
            ),
          ),
        ),
      ],
    );

    if (!esPanel) return contenido;

    // Panel lateral: tarjeta con profundidad.
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: contenido,
    );
  }
}

class _VacioDia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined,
                size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
            const SizedBox(height: AppSpacing.sm),
            Text('Día libre',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('Crea un evento para empezar.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ====================== TARJETA DE EVENTO ======================

class _EventoCard extends StatelessWidget {
  const _EventoCard({
    required this.evento,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
  });

  final Evento evento;
  final VoidCallback onTap;
  final ValueChanged<String> onMenu;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = catColor(evento.categoria);
    final done = evento.realizado;
    final cancel = evento.cancelado;
    final tachado = done || cancel;
    final critico = evento.importancia == 'critico';
    final importante = evento.importancia == 'importante';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: c, width: importante || critico ? 4 : 3),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle realizado
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, right: AppSpacing.sm),
                    child: Icon(
                      done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: done ? AppColors.olive : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            evento.todoElDia
                                ? 'Todo el día'
                                : _horaDe(evento.inicio),
                            style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant),
                          ),
                          if (critico) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const _PillCritico(),
                          ] else if (importante) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const _PillImportante(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        evento.titulo,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          decoration:
                              tachado ? TextDecoration.lineThrough : null,
                          color: tachado ? cs.onSurfaceVariant : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                                color: c, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              evento.categoria ?? 'Sin categoría',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      if (evento.descripcion != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            evento.descripcion!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant, height: 1.3),
                          ),
                        ),
                      if (cancel)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Cancelado',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: AppColors.danger)),
                        ),
                    ],
                  ),
                ),
                _MenuEvento(evento: evento, onMenu: onMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillCritico extends StatelessWidget {
  const _PillCritico();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text('Crítico',
          style: TextStyle(
              color: AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _PillImportante extends StatelessWidget {
  const _PillImportante();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.olive.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text('Importante',
          style: TextStyle(
              color: AppColors.oliveSoft,
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
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
      tooltip: 'Opciones',
      onSelected: onMenu,
      itemBuilder: (_) => [
        const PopupMenuItem<String>(
          value: 'editar',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 18),
            SizedBox(width: AppSpacing.sm),
            Text('Editar'),
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
          )
        else
          const PopupMenuItem<String>(
            value: 'pendiente',
            child: Row(children: [
              Icon(Icons.undo, size: 18),
              SizedBox(width: AppSpacing.sm),
              Text('Reactivar'),
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

// ====================== VISTA HOY ======================

class _VistaHoy extends StatelessWidget {
  const _VistaHoy({
    required this.fecha,
    required this.eventos,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
  });

  final DateTime fecha;
  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;
  final ValueChanged<Evento> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_diaSemana(fecha).toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.oliveSoft)),
                      Text(
                        '${fecha.day} de ${_mesNombre(fecha.month).toLowerCase()}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    eventos.isEmpty
                        ? ''
                        : '${eventos.length} ${eventos.length == 1 ? 'evento' : 'eventos'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Expanded(
              child: eventos.isEmpty
                  ? _VacioDia()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, AppSpacing.xs, AppSpacing.md, 96),
                      children: [
                        for (final e in eventos)
                          _EventoCard(
                            evento: e,
                            onTap: () => onTap(e),
                            onMenu: (op) => onMenu(e, op),
                            onToggle: () => onToggle(e),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== VISTA SEMANA ======================

class _VistaSemana extends StatelessWidget {
  const _VistaSemana({
    required this.eventos,
    required this.wide,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
    required this.onCrearDia,
  });

  final List<Evento> eventos;
  final bool wide;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;
  final ValueChanged<Evento> onToggle;
  final ValueChanged<DateTime> onCrearDia;

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now();
    final base = DateTime(n.year, n.month, n.day);
    if (wide) {
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
      onToggle: onToggle,
    );
  }
}

class _SemanaLista extends StatelessWidget {
  const _SemanaLista({
    required this.base,
    required this.eventos,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
  });

  final DateTime base;
  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;
  final ValueChanged<Evento> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 96),
      itemCount: 7,
      itemBuilder: (_, i) {
        final dia = base.add(Duration(days: i));
        final delDia = eventos.where((e) => _mismoDia(e.inicio, dia)).toList();
        final vacio = delDia.isEmpty;
        return Container(
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: vacio ? 0.4 : 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: i == 0
                  ? AppColors.olive.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm,
                AppSpacing.sm, vacio ? AppSpacing.sm : AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_etiquetaDia(dia, i),
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: i == 0 ? AppColors.olive : null)),
                    const Spacer(),
                    if (!vacio)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${delDia.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                if (vacio)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Sin eventos',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Column(
                      children: [
                        for (final e in delDia)
                          _EventoCard(
                            evento: e,
                            onTap: () => onTap(e),
                            onMenu: (op) => onMenu(e, op),
                            onToggle: () => onToggle(e),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: i == 6
                          ? BorderSide.none
                          : BorderSide(
                              color:
                                  cs.outlineVariant.withValues(alpha: 0.35)),
                    ),
                  ),
                  child: _ColumnaDia(
                    dia: base.add(Duration(days: i)),
                    esHoy: i == 0,
                    eventos: eventos
                        .where((e) =>
                            _mismoDia(e.inicio, base.add(Duration(days: i))))
                        .toList(),
                    onTap: onTap,
                    onCrear: () => onCrearDia(base.add(Duration(days: i))),
                  ),
                ),
              ),
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
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: esHoy
                ? AppColors.olive.withValues(alpha: 0.14)
                : cs.surfaceContainer.withValues(alpha: 0.5),
            border: Border(
                bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.4))),
          ),
          child: Column(
            children: [
              Text(_diaCorto(dia.weekday).toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text('${dia.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: esHoy ? AppColors.olive : null)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(6),
            children: [
              if (eventos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text('—',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                )
              else
                for (final e in eventos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _ChipColumna(evento: e, onTap: () => onTap(e)),
                  ),
              InkWell(
                onTap: onCrear,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 15, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text('Agregar',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipColumna extends StatelessWidget {
  const _ChipColumna({required this.evento, required this.onTap});
  final Evento evento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = catColor(evento.categoria);
    final critico = evento.importancia == 'critico';
    final importante = evento.importancia == 'importante';
    final tachado = evento.realizado || evento.cancelado;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(7),
          border: Border(
              left: BorderSide(
                  color: c, width: importante || critico ? 3.5 : 2.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!evento.todoElDia)
              Text(_horaDe(evento.inicio),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
            Text(
              evento.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w600,
                decoration: tachado ? TextDecoration.lineThrough : null,
                color: tachado ? cs.onSurfaceVariant : cs.onSurface,
              ),
            ),
            if (critico)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('Crítico',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
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

String _diaSemana(DateTime d) {
  const dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
  ];
  return dias[d.weekday - 1];
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
  final nombre = _diaSemana(dia);
  final capit = nombre[0].toUpperCase() + nombre.substring(1);
  return '$capit ${dia.day} de ${_mesNombre(dia.month).toLowerCase()}';
}
