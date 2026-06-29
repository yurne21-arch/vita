import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/projects_repository.dart';
import 'projects_controller.dart';
import 'proyectos_widgets.dart';

/// Hoja para crear o editar un proyecto. Devuelve el id si se creó.
Future<Object?> mostrarEditorProyecto(
  BuildContext context,
  WidgetRef ref, {
  Project? existente,
}) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _EditorProyecto(existente: existente),
    ),
  );
}

class _EditorProyecto extends ConsumerStatefulWidget {
  const _EditorProyecto({this.existente});
  final Project? existente;
  @override
  ConsumerState<_EditorProyecto> createState() => _EditorProyectoState();
}

class _EditorProyectoState extends ConsumerState<_EditorProyecto> {
  late final TextEditingController _titulo;
  late final TextEditingController _objetivo;
  late final TextEditingController _porque;
  String? _area;
  DateTime? _fecha;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _titulo = TextEditingController(text: e?.titulo ?? '');
    _objetivo = TextEditingController(text: e?.objetivo ?? '');
    _porque = TextEditingController(text: e?.descripcion ?? '');
    _area = e?.area;
    _fecha = e?.fechaObjetivo;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _objetivo.dispose();
    _porque.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty || _guardando) return;
    setState(() => _guardando = true);
    final acc = ref.read(proyectosAccionesProvider);
    try {
      if (widget.existente == null) {
        final id = await acc.crearProyecto(
          titulo: titulo,
          objetivo: _objetivo.text,
          descripcion: _porque.text,
          area: _area,
          fechaObjetivo: _fecha,
        );
        if (mounted) Navigator.of(context).pop(id);
      } else {
        await acc.editarProyecto(
          widget.existente!.id,
          titulo: titulo,
          objetivo: _objetivo.text,
          descripcion: _porque.text,
          area: _area,
          fechaObjetivo: _fecha,
        );
        final e = widget.existente!;
        final actualizado = Project(
          id: e.id,
          titulo: titulo,
          descripcion:
              _porque.text.trim().isEmpty ? null : _porque.text.trim(),
          objetivo:
              _objetivo.text.trim().isEmpty ? null : _objetivo.text.trim(),
          area: _area,
          estado: e.estado,
          esPrincipal: e.esPrincipal,
          fechaObjetivo: _fecha,
          progresoManual: e.progresoManual,
          orden: e.orden,
          createdAt: e.createdAt,
          updatedAt: DateTime.now(),
          completadoAt: e.completadoAt,
        );
        if (mounted) Navigator.of(context).pop(actualizado);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esNuevo = widget.existente == null;
    return SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        children: [
          Text(esNuevo ? 'Nuevo proyecto' : 'Editar proyecto',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _titulo,
            autofocus: esNuevo,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Título', hintText: '¿Qué vas a construir?'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _objetivo,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Objetivo', hintText: '¿Qué resultado buscas?'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _porque,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Por qué (motivación)',
                hintText: 'Lo que te recuerda no abandonarlo'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _area,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Área'),
            items: [
              const DropdownMenuItem<String>(
                  value: null, child: Text('Sin área')),
              for (final a in kAreas)
                DropdownMenuItem<String>(value: a, child: Text(a)),
            ],
            onChanged: (v) => setState(() => _area = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _SelectorFecha(
            fecha: _fecha,
            onCambiar: (d) => setState(() => _fecha = d),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.olive,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(esNuevo ? 'Crear proyecto' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }
}

/// Hoja para crear o editar un paso/hito.
Future<void> mostrarEditorTarea(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  ProjectTask? existente,
  String tipoInicial = 'paso',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _EditorTarea(
        projectId: projectId,
        existente: existente,
        tipoInicial: tipoInicial,
      ),
    ),
  );
}

class _EditorTarea extends ConsumerStatefulWidget {
  const _EditorTarea({
    required this.projectId,
    this.existente,
    this.tipoInicial = 'paso',
  });
  final String projectId;
  final ProjectTask? existente;
  final String tipoInicial;
  @override
  ConsumerState<_EditorTarea> createState() => _EditorTareaState();
}

class _EditorTareaState extends ConsumerState<_EditorTarea> {
  late final TextEditingController _texto;
  late String _tipo;
  DateTime? _fecha;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _texto = TextEditingController(text: e?.texto ?? '');
    _tipo = e?.tipo ?? widget.tipoInicial;
    _fecha = e?.fechaObjetivo;
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _guardando) return;
    setState(() => _guardando = true);
    final acc = ref.read(proyectosAccionesProvider);
    try {
      if (widget.existente == null) {
        if (_tipo == 'hito') {
          await acc.crearHito(widget.projectId, texto, fechaObjetivo: _fecha);
        } else {
          await acc.crearPaso(widget.projectId, texto, fechaObjetivo: _fecha);
        }
      } else {
        await acc.editarTarea(widget.existente!,
            texto: texto, tipo: _tipo, fechaObjetivo: _fecha);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esNuevo = widget.existente == null;
    return SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        children: [
          Text(esNuevo ? 'Nuevo paso o hito' : 'Editar',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _texto,
            autofocus: esNuevo,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Descripción', hintText: '¿Cuál es el paso?'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Paso'),
                selected: _tipo == 'paso',
                onSelected: (_) => setState(() => _tipo = 'paso'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: const Text('Hito'),
                selected: _tipo == 'hito',
                onSelected: (_) => setState(() => _tipo = 'hito'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SelectorFecha(
            fecha: _fecha,
            onCambiar: (d) => setState(() => _fecha = d),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.olive,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(esNuevo ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}

/// Hoja para registrar un avance o nota rápida en la bitácora.
Future<void> mostrarRegistroBitacora(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required bool esNota,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _RegistroBitacora(projectId: projectId, esNota: esNota),
    ),
  );
}

class _RegistroBitacora extends ConsumerStatefulWidget {
  const _RegistroBitacora({required this.projectId, required this.esNota});
  final String projectId;
  final bool esNota;
  @override
  ConsumerState<_RegistroBitacora> createState() => _RegistroBitacoraState();
}

class _RegistroBitacoraState extends ConsumerState<_RegistroBitacora> {
  final _texto = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _guardando) return;
    setState(() => _guardando = true);
    final acc = ref.read(proyectosAccionesProvider);
    try {
      if (widget.esNota) {
        await acc.notaRapida(widget.projectId, texto: texto);
      } else {
        await acc.avanceRapido(widget.projectId, texto: texto);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        children: [
          Text(widget.esNota ? 'Nueva nota' : 'Registrar avance',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _texto,
            autofocus: true,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
                labelText: widget.esNota ? 'Nota' : 'Avance',
                hintText: widget.esNota
                    ? 'Algo que quieras recordar'
                    : '¿Qué avanzaste?'),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.olive,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}

/// Selector de fecha objetivo opcional (reutilizado por los editores).
class _SelectorFecha extends StatelessWidget {
  const _SelectorFecha({required this.fecha, required this.onCambiar});
  final DateTime? fecha;
  final ValueChanged<DateTime?> onCambiar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final hoy = DateTime.now();
        final d = await showDatePicker(
          context: context,
          initialDate: fecha ?? hoy,
          firstDate: DateTime(hoy.year - 1),
          lastDate: DateTime(hoy.year + 6),
        );
        if (d != null) onCambiar(d);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(
              fecha == null
                  ? 'Fecha objetivo (opcional)'
                  : '${fecha!.day}/${fecha!.month}/${fecha!.year}',
              style: TextStyle(
                  color: fecha == null ? cs.onSurfaceVariant : cs.onSurface),
            ),
            const Spacer(),
            if (fecha != null)
              GestureDetector(
                onTap: () => onCambiar(null),
                child: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
