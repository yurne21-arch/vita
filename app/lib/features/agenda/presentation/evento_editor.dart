import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/agenda_repository.dart';
import 'agenda_controller.dart';

/// Abre el editor de evento (crear o editar) como hoja inferior.
Future<void> mostrarEditorEvento(
  BuildContext context,
  WidgetRef ref, {
  Evento? existente,
  DateTime? fechaSugerida,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _EventoEditor(
      existente: existente,
      fechaSugerida: fechaSugerida,
    ),
  );
}

class _EventoEditor extends ConsumerStatefulWidget {
  const _EventoEditor({this.existente, this.fechaSugerida});
  final Evento? existente;
  final DateTime? fechaSugerida;

  @override
  ConsumerState<_EventoEditor> createState() => _EventoEditorState();
}

class _EventoEditorState extends ConsumerState<_EventoEditor> {
  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  late DateTime _fecha; // solo fecha (sin hora)
  bool _todoElDia = false;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _guardando = false;

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _titulo = TextEditingController(text: e?.titulo ?? '');
    _descripcion = TextEditingController(text: e?.descripcion ?? '');
    final base = e?.inicio ?? widget.fechaSugerida ?? DateTime.now();
    _fecha = DateTime(base.year, base.month, base.day);
    _todoElDia = e?.todoElDia ?? false;
    if (e != null && !e.todoElDia) {
      _horaInicio = TimeOfDay.fromDateTime(e.inicio);
      if (e.fin != null) _horaFin = TimeOfDay.fromDateTime(e.fin!);
    } else if (e == null) {
      final ahora = TimeOfDay.now();
      _horaInicio = ahora;
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  DateTime _combinar(DateTime dia, TimeOfDay? hora) {
    final h = hora ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(dia.year, dia.month, dia.day, h.hour, h.minute);
  }

  Future<void> _elegirFecha() async {
    final sel = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (sel != null) setState(() => _fecha = sel);
  }

  Future<void> _elegirHora({required bool inicio}) async {
    final sel = await showTimePicker(
      context: context,
      initialTime:
          (inicio ? _horaInicio : _horaFin) ?? TimeOfDay.now(),
    );
    if (sel != null) {
      setState(() {
        if (inicio) {
          _horaInicio = sel;
        } else {
          _horaFin = sel;
        }
      });
    }
  }

  Future<void> _guardar() async {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) return;

    final inicio = _combinar(_fecha, _todoElDia ? null : _horaInicio);
    DateTime? fin;
    if (!_todoElDia && _horaFin != null) {
      fin = _combinar(_fecha, _horaFin);
      if (fin.isBefore(inicio)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('La hora de término no puede ser antes del inicio.')),
        );
        return;
      }
    }

    setState(() => _guardando = true);
    try {
      final ctrl = ref.read(agendaControllerProvider.notifier);
      if (_esEdicion) {
        await ctrl.editar(
          widget.existente!.id,
          titulo: titulo,
          inicio: inicio,
          descripcion: _descripcion.text,
          fin: fin,
          todoElDia: _todoElDia,
        );
      } else {
        await ctrl.crear(
          titulo: titulo,
          inicio: inicio,
          descripcion: _descripcion.text,
          fin: fin,
          todoElDia: _todoElDia,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')),
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
            Text(_esEdicion ? 'Editar evento' : 'Nuevo evento',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _titulo,
              autofocus: !_esEdicion,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _elegirFecha,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(_fechaLargaEditor(_fecha)),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Todo el día'),
              value: _todoElDia,
              onChanged: (v) => setState(() => _todoElDia = v),
            ),
            if (!_todoElDia)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _elegirHora(inicio: true),
                      child: Text(_horaInicio == null
                          ? 'Inicio'
                          : 'Inicio ${_horaTexto(_horaInicio!)}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _elegirHora(inicio: false),
                      child: Text(_horaFin == null
                          ? 'Fin (opcional)'
                          : 'Fin ${_horaTexto(_horaFin!)}'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descripcion,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
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
                    : Text(_esEdicion ? 'Guardar' : 'Crear evento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _horaTexto(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _fechaLargaEditor(DateTime d) {
  const dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
  ];
  const meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
  final dia = dias[d.weekday - 1];
  final mes = meses[d.month - 1];
  final capit = dia[0].toUpperCase() + dia.substring(1);
  return '$capit ${d.day} de $mes';
}
