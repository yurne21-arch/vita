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
      return const Color(0xFF5E7A93);
    case 'Personal':
      return const Color(0xFF7C8A5E);
    case 'Familia':
      return const Color(0xFFB08968);
    case 'Salud':
      return const Color(0xFF5E9E83);
    case 'Colegio / Juan Miguel':
      return const Color(0xFF8E7CA6);
    case 'Finanzas':
      return const Color(0xFFC2A45A);
    case 'Viaje':
      return const Color(0xFF5FA0A0);
    case 'Otro':
      return const Color(0xFF8A857A);
    default:
      return const Color(0xFF8A857A);
  }
}

const double _kPanelWidth = 270; // panel lateral más angosto (más espacio a la grilla)
const double _kBpPanel = 900;
const int _kMaxEventosColumna = 3; // tope estilo Google antes de "+X más"

class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  _Vista _vista = _Vista.mes;
  late DateTime _mesAncla;
  late DateTime _semanaAncla; // primer día de la ventana de 7 días visible
  late DateTime _diaSeleccionado;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _mesAncla = DateTime(n.year, n.month, 1);
    _semanaAncla = DateTime(n.year, n.month, n.day);
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
        return RangoFechas(_semanaAncla, _semanaAncla.add(const Duration(days: 7)));
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

  void _semana(int delta) {
    setState(() {
      _semanaAncla = _semanaAncla.add(Duration(days: 7 * delta));
    });
  }

  void _nuevo() => mostrarEditorEvento(context, ref,
      fechaSugerida: _vista == _Vista.mes ? _diaSeleccionado : _hoy);

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

  void _abrirHojaDia(DateTime fecha, List<Evento> delDia) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surfaceContainerLow,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scroll) => _ContenidoDia(
          fecha: fecha,
          eventos: delDia,
          scrollController: scroll,
          onTap: (e) => mostrarEditorEvento(context, ref, existente: e),
          onMenu: _accion,
          onToggle: _toggleRealizado,
          onNuevo: () =>
              mostrarEditorEvento(context, ref, fechaSugerida: fecha),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventosEnRangoProvider(_rangoActivo()));
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1815) : cs.surface;
    final wide = MediaQuery.sizeOf(context).width >= _kBpPanel;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: bg,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              onPressed: _nuevo,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo evento'),
            ),
      body: SafeArea(
        child: Column(
          children: [
            _BarraSuperior(
              vista: _vista,
              wide: wide,
              onChanged: (v) => setState(() => _vista = v),
              onNuevo: _nuevo,
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
          wide: wide,
          onTap: (e) => mostrarEditorEvento(context, ref, existente: e),
          onMenu: _accion,
          onToggle: _toggleRealizado,
          onNuevo: _nuevo,
        );
      case _Vista.semana:
        return _VistaSemana(
          base: _semanaAncla,
          hoy: _hoy,
          eventos: eventos,
          wide: wide,
          onAnterior: () => _semana(-1),
          onSiguiente: () => _semana(1),
          onTap: (e) => mostrarEditorEvento(context, ref, existente: e),
          onMenu: _accion,
          onToggle: _toggleRealizado,
          onCrearDia: (d) =>
              mostrarEditorEvento(context, ref, fechaSugerida: d),
          onVerDia: _abrirHojaDia,
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
                  d, eventos.where((e) => _mismoDia(e.inicio, d)).toList());
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

// ====================== BARRA SUPERIOR ======================

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({
    required this.vista,
    required this.wide,
    required this.onChanged,
    required this.onNuevo,
  });

  final _Vista vista;
  final bool wide;
  final ValueChanged<_Vista> onChanged;
  final VoidCallback onNuevo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          wide ? AppSpacing.lg : AppSpacing.md,
          AppSpacing.md,
          wide ? AppSpacing.lg : AppSpacing.md,
          AppSpacing.sm),
      child: Row(
        children: [
          _SelectorVista(vista: vista, onChanged: onChanged),
          const Spacer(),
          if (wide)
            FilledButton.icon(
              onPressed: onNuevo,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.olive,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo evento'),
            ),
        ],
      ),
    );
  }
}

class _SelectorVista extends StatelessWidget {
  const _SelectorVista({required this.vista, required this.onChanged});
  final _Vista vista;
  final ValueChanged<_Vista> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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

class _PillHoy extends StatelessWidget {
  const _PillHoy();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text('HOY',
          style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800)),
    );
  }
}

/// Encabezado con flechas de navegación reutilizable (mes/semana).
class _NavCabecera extends StatelessWidget {
  const _NavCabecera({
    required this.titulo,
    required this.onAnterior,
    required this.onSiguiente,
    this.trailing,
  });

  final String titulo;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          _BotonRedondo(icon: Icons.chevron_left, onTap: onAnterior),
          const SizedBox(width: AppSpacing.sm),
          Text(titulo,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, letterSpacing: -0.4)),
          const SizedBox(width: AppSpacing.sm),
          _BotonRedondo(icon: Icons.chevron_right, onTap: onSiguiente),
          const Spacer(),
          if (trailing != null) Flexible(child: trailing!),
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

    final grid = Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
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
                                  primerGrid
                                      .add(Duration(days: fila * 7 + col)),
                                  diaSeleccionado),
                              ultimaFila: fila == 5,
                              ultimaCol: col == 6,
                              eventos: eventos
                                  .where((e) => _mismoDia(
                                      e.inicio,
                                      primerGrid.add(
                                          Duration(days: fila * 7 + col))))
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
    );

    final cabecera = _NavCabecera(
      titulo: '${_mesNombre(mesAncla.month)} ${mesAncla.year}',
      onAnterior: onMesAnterior,
      onSiguiente: onMesSiguiente,
      trailing: _Leyenda(eventos: eventos),
    );

    if (!wide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          children: [
            cabecera,
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: grid),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        children: [
          cabecera,
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: grid),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(width: _kPanelWidth, child: panel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.eventos});
  final List<Evento> eventos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cats = <String>{
      for (final e in eventos)
        if (e.categoria != null) e.categoria!,
    }.toList();
    if (cats.isEmpty) return const SizedBox.shrink();

    const maxVisible = 5;
    final visibles = cats.take(maxVisible).toList();
    final extra = cats.length - visibles.length;

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.md,
      runSpacing: 4,
      children: [
        for (final c in visibles)
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
        if (extra > 0)
          Text('+$extra',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700)),
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
        width: 38,
        height: 38,
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
          for (final d in const [
            'LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Center(
                  child: Text(d,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
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
              ? AppColors.olive.withValues(alpha: 0.18)
              : (esDeMes
                  ? Colors.transparent
                  : cs.surfaceContainerHighest.withValues(alpha: 0.16)),
          // Día seleccionado: borde oliva además del fondo.
          border: seleccionado
              ? Border.all(color: AppColors.olive, width: 1.5)
              : Border(
                  right: ultimaCol
                      ? BorderSide.none
                      : BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.35)),
                  bottom: ultimaFila
                      ? BorderSide.none
                      : BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.35)),
                ),
          borderRadius: seleccionado ? BorderRadius.circular(8) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 27,
                  height: 25,
                  alignment: Alignment.center,
                  decoration: esHoy
                      ? const BoxDecoration(
                          color: AppColors.olive, shape: BoxShape.circle)
                      : null,
                  child: Text(
                    '${dia.day}',
                    style: TextStyle(
                      fontSize: 15,
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
              const SizedBox(height: 2),
              Expanded(child: _EventosCelda(eventos: eventos)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eventos visibles dentro de la celda, según altura disponible y tope.
class _EventosCelda extends StatelessWidget {
  const _EventosCelda({required this.eventos});
  final List<Evento> eventos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const perBar = 23.0;
        final cabenPorAlto = (c.maxHeight / perBar).floor();
        final capacidad =
            cabenPorAlto < _kMaxEventosColumna ? cabenPorAlto : _kMaxEventosColumna;
        if (capacidad <= 0) {
          return Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final e in eventos.take(4))
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: catColor(e.categoria), shape: BoxShape.circle),
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
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
      height: 21,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.only(left: 6, right: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border(left: BorderSide(color: c, width: 3)),
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
                fontSize: 12,
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
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.oliveSoft,
                  )),
              const SizedBox(height: 2),
              Text(
                '${fecha.day} de ${_mesNombre(fecha.month).toLowerCase()}',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: -0.3),
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
            child: FilledButton.tonalIcon(
              onPressed: onNuevo,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.olive.withValues(alpha: 0.16),
                foregroundColor: AppColors.oliveSoft,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar evento'),
            ),
          ),
        ),
      ],
    );

    if (!esPanel) return contenido;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
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
    this.compacto = false,
  });

  final Evento evento;
  final VoidCallback onTap;
  final ValueChanged<String> onMenu;
  final VoidCallback onToggle;
  final bool compacto;

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
    final vpad = compacto ? 7.0 : 9.0; // ~10% más baja en modo compacto

    return Padding(
      padding: EdgeInsets.only(bottom: compacto ? AppSpacing.xs : AppSpacing.sm),
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
                left: BorderSide(
                    color: c, width: importante || critico ? 4 : 3),
              ),
            ),
            padding: EdgeInsets.fromLTRB(AppSpacing.md, vpad, AppSpacing.xs, vpad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 2, right: AppSpacing.sm),
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
                      SizedBox(height: compacto ? 4 : 5),
                      _EtiquetaCategoria(categoria: evento.categoria),
                      if (evento.descripcion != null && !compacto)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
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

class _EtiquetaCategoria extends StatelessWidget {
  const _EtiquetaCategoria({required this.categoria});
  final String? categoria;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = catColor(categoria);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            categoria ?? 'Sin categoría',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant),
          ),
        ],
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
    required this.wide,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
    required this.onNuevo,
  });

  final DateTime fecha;
  final List<Evento> eventos;
  final bool wide;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;
  final ValueChanged<Evento> onToggle;
  final VoidCallback onNuevo;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: _AgendaDia(
                    fecha: fecha,
                    eventos: eventos,
                    onTap: onTap,
                    onMenu: onMenu,
                    onToggle: onToggle)),
            const SizedBox(width: AppSpacing.lg),
            SizedBox(
                width: _kPanelWidth,
                child: _ResumenDia(
                    fecha: fecha, eventos: eventos, onNuevo: onNuevo)),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_diaSemana(fecha).toUpperCase(),
                      style: const TextStyle(
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
                      _FilaTimeline(
                        evento: e,
                        onTap: () => onTap(e),
                        onMenu: (op) => onMenu(e, op),
                        onToggle: () => onToggle(e),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Columna principal de la vista Hoy: agenda con línea de tiempo.
class _AgendaDia extends StatelessWidget {
  const _AgendaDia({
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
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainer.withValues(alpha: 0.5),
              border: Border(
                  bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: Row(
              children: [
                Text('Agenda del día',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
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
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                    itemCount: eventos.length,
                    itemBuilder: (_, i) => _FilaTimeline(
                      evento: eventos[i],
                      primero: i == 0,
                      ultimo: i == eventos.length - 1,
                      onTap: () => onTap(eventos[i]),
                      onMenu: (op) => onMenu(eventos[i], op),
                      onToggle: () => onToggle(eventos[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Fila de agenda: gutter de hora + riel con presencia + tarjeta compacta.
class _FilaTimeline extends StatelessWidget {
  const _FilaTimeline({
    required this.evento,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
    this.primero = false,
    this.ultimo = false,
  });

  final Evento evento;
  final VoidCallback onTap;
  final ValueChanged<String> onMenu;
  final VoidCallback onToggle;
  final bool primero;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = catColor(evento.categoria);
    final rail = cs.outlineVariant.withValues(alpha: 0.55);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    evento.todoElDia ? '—' : _horaDe(evento.inicio),
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                  if (!evento.todoElDia && evento.fin != null)
                    Text(_horaDe(evento.fin!),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          // Riel con más presencia
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                    width: 2.5,
                    height: 12,
                    color: primero ? Colors.transparent : rail),
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: cs.surfaceContainerLow, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: c.withValues(alpha: 0.4),
                          blurRadius: 5,
                          spreadRadius: 0.5),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                      width: 2.5,
                      color: ultimo ? Colors.transparent : rail),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _EventoCard(
                evento: evento,
                compacto: true,
                onTap: onTap,
                onMenu: onMenu,
                onToggle: onToggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Columna lateral de la vista Hoy: resumen del día (con estructura para IA).
class _ResumenDia extends StatelessWidget {
  const _ResumenDia({
    required this.fecha,
    required this.eventos,
    required this.onNuevo,
  });

  final DateTime fecha;
  final List<Evento> eventos;
  final VoidCallback onNuevo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ahora = DateTime.now();

    final activos = eventos.where((e) => !e.cancelado).toList();
    final realizados = eventos.where((e) => e.realizado).length;

    // Próximo evento (no cancelado, con hora, que aún no empieza).
    Evento? proximo;
    for (final e in activos) {
      if (!e.todoElDia && e.inicio.isAfter(ahora)) {
        proximo = e;
        break;
      }
    }

    // Horas ocupadas (eventos con fin, no cancelados).
    var ocupado = Duration.zero;
    for (final e in activos) {
      if (!e.todoElDia && e.fin != null && e.fin!.isAfter(e.inicio)) {
        ocupado += e.fin!.difference(e.inicio);
      }
    }

    // Tiempo libre estimado de aquí a las 22:00 (estructura base, mejorará con IA).
    final finJornada = DateTime(fecha.year, fecha.month, fecha.day, 22);
    var libre = finJornada.isAfter(ahora)
        ? finJornada.difference(ahora) - ocupado
        : Duration.zero;
    if (libre.isNegative) libre = Duration.zero;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(_diaSemana(fecha).toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.oliveSoft)),
          const SizedBox(height: 2),
          Text(
            '${fecha.day} de ${_mesNombre(fecha.month).toLowerCase()}',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Resumen inteligente (base; luego lo potenciará la IA)
          _ResumenFila(
            icon: Icons.schedule_outlined,
            label: 'Próximo',
            valor: proximo == null
                ? 'Sin próximos'
                : '${_horaDe(proximo.inicio)} · ${proximo.titulo}',
          ),
          _ResumenFila(
            icon: Icons.hourglass_bottom_outlined,
            label: 'Ocupado',
            valor: _dur(ocupado),
          ),
          _ResumenFila(
            icon: Icons.spa_outlined,
            label: 'Libre restante',
            valor: _dur(libre),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('RESUMEN',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
              const Spacer(),
              Text('$realizados/${eventos.length} hechos',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Estructura reservada para sugerencias de IA (aún no activa)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.olive.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined,
                    size: 18, color: AppColors.oliveSoft),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Sugerencias de VITA · próximamente',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onNuevo,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.olive.withValues(alpha: 0.16),
                foregroundColor: AppColors.oliveSoft,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo evento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenFila extends StatelessWidget {
  const _ResumenFila(
      {required this.icon, required this.label, required this.valor});
  final IconData icon;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                Text(valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== VISTA SEMANA ======================

class _VistaSemana extends StatelessWidget {
  const _VistaSemana({
    required this.base,
    required this.hoy,
    required this.eventos,
    required this.wide,
    required this.onAnterior,
    required this.onSiguiente,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
    required this.onCrearDia,
    required this.onVerDia,
  });

  final DateTime base;
  final DateTime hoy;
  final List<Evento> eventos;
  final bool wide;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;
  final ValueChanged<Evento> onToggle;
  final ValueChanged<DateTime> onCrearDia;
  final void Function(DateTime, List<Evento>) onVerDia;

  @override
  Widget build(BuildContext context) {
    final fin = base.add(const Duration(days: 6));
    final titulo =
        '${base.day} ${_mesCorto(base.month)} – ${fin.day} ${_mesCorto(fin.month)}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
          wide ? AppSpacing.lg : AppSpacing.md, 0,
          wide ? AppSpacing.lg : AppSpacing.md, AppSpacing.md),
      child: Column(
        children: [
          _NavCabecera(
            titulo: titulo,
            onAnterior: onAnterior,
            onSiguiente: onSiguiente,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: wide
                ? _SemanaColumnas(
                    base: base,
                    hoy: hoy,
                    eventos: eventos,
                    onTap: onTap,
                    onCrearDia: onCrearDia,
                    onVerDia: onVerDia,
                  )
                : _SemanaLista(
                    base: base,
                    hoy: hoy,
                    eventos: eventos,
                    onTap: onTap,
                    onMenu: onMenu,
                    onToggle: onToggle,
                    onVerDia: onVerDia,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SemanaLista extends StatelessWidget {
  const _SemanaLista({
    required this.base,
    required this.hoy,
    required this.eventos,
    required this.onTap,
    required this.onMenu,
    required this.onToggle,
    required this.onVerDia,
  });

  final DateTime base;
  final DateTime hoy;
  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final void Function(Evento, String) onMenu;
  final ValueChanged<Evento> onToggle;
  final void Function(DateTime, List<Evento>) onVerDia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xs, 0, 96),
      itemCount: 7,
      itemBuilder: (_, i) {
        final dia = base.add(Duration(days: i));
        final esHoy = _mismoDia(dia, hoy);
        final delDia = eventos.where((e) => _mismoDia(e.inicio, dia)).toList();
        final vacio = delDia.isEmpty;
        final visibles = delDia.take(_kMaxEventosColumna).toList();
        final extra = delDia.length - visibles.length;
        return Container(
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: vacio ? 0.4 : 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: esHoy
                  ? AppColors.olive.withValues(alpha: 0.6)
                  : cs.outlineVariant.withValues(alpha: 0.4),
              width: esHoy ? 1.4 : 1,
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
                    Text(_etiquetaDiaSemana(dia, hoy),
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: esHoy ? AppColors.olive : null)),
                    const SizedBox(width: AppSpacing.sm),
                    if (esHoy) const _PillHoy(),
                    const Spacer(),
                    if (!vacio)
                      Text('${delDia.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700)),
                  ],
                ),
                if (vacio)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Sin eventos',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  )
                else ...[
                  const SizedBox(height: AppSpacing.xs),
                  for (final e in visibles)
                    _EventoCard(
                      evento: e,
                      onTap: () => onTap(e),
                      onMenu: (op) => onMenu(e, op),
                      onToggle: () => onToggle(e),
                    ),
                  if (extra > 0)
                    _MasIndicador(
                      texto: '+$extra más',
                      onTap: () => onVerDia(dia, delDia),
                    ),
                ],
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
    required this.hoy,
    required this.eventos,
    required this.onTap,
    required this.onCrearDia,
    required this.onVerDia,
  });

  final DateTime base;
  final DateTime hoy;
  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final ValueChanged<DateTime> onCrearDia;
  final void Function(DateTime, List<Evento>) onVerDia;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
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
                            color: cs.outlineVariant.withValues(alpha: 0.35)),
                  ),
                ),
                child: _ColumnaDia(
                  dia: base.add(Duration(days: i)),
                  esHoy: _mismoDia(base.add(Duration(days: i)), hoy),
                  eventos: eventos
                      .where((e) =>
                          _mismoDia(e.inicio, base.add(Duration(days: i))))
                      .toList(),
                  onTap: onTap,
                  onCrear: () => onCrearDia(base.add(Duration(days: i))),
                  onVerDia: onVerDia,
                ),
              ),
            ),
        ],
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
    required this.onVerDia,
  });

  final DateTime dia;
  final bool esHoy;
  final List<Evento> eventos;
  final ValueChanged<Evento> onTap;
  final VoidCallback onCrear;
  final void Function(DateTime, List<Evento>) onVerDia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final visibles = eventos.take(_kMaxEventosColumna).toList();
    final extra = eventos.length - visibles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
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
              if (esHoy)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: _PillHoy(),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(6),
            children: [
              for (final e in visibles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ChipColumna(evento: e, onTap: () => onTap(e)),
                ),
              if (extra > 0)
                _MasIndicador(
                  texto: '+$extra más',
                  onTap: () => onVerDia(dia, eventos),
                  centrado: true,
                ),
              InkWell(
                onTap: onCrear,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Icon(Icons.add,
                        size: 16,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
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

class _MasIndicador extends StatelessWidget {
  const _MasIndicador(
      {required this.texto, required this.onTap, this.centrado = false});
  final String texto;
  final VoidCallback onTap;
  final bool centrado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Text(texto,
        style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.oliveSoft));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: centrado ? Center(child: t) : Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                t,
                const SizedBox(width: 4),
                Icon(Icons.expand_more, size: 15, color: cs.onSurfaceVariant),
              ],
            )),
      ),
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

String _dur(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0 && m == 0) return '0 min';
  if (h == 0) return '$m min';
  if (m == 0) return '${h}h';
  return '${h}h $m min';
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

String _mesCorto(int m) {
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];
  return meses[m - 1];
}

String _etiquetaDiaSemana(DateTime dia, DateTime hoy) {
  if (_mismoDia(dia, hoy)) return 'Hoy';
  if (_mismoDia(dia, hoy.add(const Duration(days: 1)))) return 'Mañana';
  final nombre = _diaSemana(dia);
  final capit = nombre[0].toUpperCase() + nombre.substring(1);
  return '$capit ${dia.day} de ${_mesNombre(dia.month).toLowerCase()}';
}
