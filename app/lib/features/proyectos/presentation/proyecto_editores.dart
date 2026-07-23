import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/moneda.dart';
import '../data/projects_repository.dart';
import 'projects_controller.dart';
import 'proyectos_widgets.dart';

// ───────────────── Editor de proyecto ─────────────────

/// Hoja para crear o editar un proyecto.
/// Devuelve el id (String) al crear, o el Project actualizado al editar.
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
    builder: (_) => _EditorProyecto(existente: existente),
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
  String? _metaId;
  DateTime? _fecha;
  bool _principal = false;
  bool _masOpciones = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _titulo = TextEditingController(text: e?.titulo ?? '');
    _objetivo = TextEditingController(text: e?.objetivo ?? '');
    _porque = TextEditingController(text: e?.descripcion ?? '');
    _area = e?.area;
    _metaId = e?.metaId;
    _fecha = e?.fechaObjetivo;
    // Si ya hay datos secundarios, abre la sección para no esconderlos.
    _masOpciones = (e?.descripcion != null) || (e?.fechaObjetivo != null);
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
          metaId: _metaId,
          esPrincipal: _principal,
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
          metaId: _metaId,
        );
        final e = widget.existente!;
        final actualizado = Project(
          id: e.id,
          titulo: titulo,
          descripcion: _porque.text.trim().isEmpty ? null : _porque.text.trim(),
          objetivo:
              _objetivo.text.trim().isEmpty ? null : _objetivo.text.trim(),
          area: _area,
          estado: e.estado,
          esPrincipal: e.esPrincipal,
          fechaObjetivo: _fecha,
          progresoManual: e.progresoManual,
          metaId: _metaId,
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
    final cs = theme.colorScheme;
    final esNuevo = widget.existente == null;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          shrinkWrap: true,
          // El teclado no debe tapar el botón: se le deja sitio abajo.
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
              AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
          children: [
            Text(esNuevo ? 'Nuevo proyecto' : 'Editar proyecto',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.lg),

            // ── Principales ──
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
            _SelectorMeta(
              metaId: _metaId,
              onCambiar: (v) => setState(() => _metaId = v),
            ),

            // Marcar principal (solo al crear; en edición se usa el menú ⋮)
            if (esNuevo) ...[
              const SizedBox(height: AppSpacing.xs),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marcar como proyecto principal'),
                subtitle: Text('VITA lo destacará en Mi Vida',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                value: _principal,
                onChanged: (v) => setState(() => _principal = v),
              ),
            ],

            // ── Secundarias (colapsables) ──
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () => setState(() => _masOpciones = !_masOpciones),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(_masOpciones ? Icons.expand_less : Icons.expand_more,
                        size: 20, color: AppColors.accentSoft),
                    const SizedBox(width: 6),
                    Text('Más opciones (opcional)',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.accentSoft,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            if (_masOpciones) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _porque,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Motivación',
                    hintText: 'Lo que te recuerda no abandonarlo'),
              ),
              const SizedBox(height: AppSpacing.md),
              _SelectorFecha(
                fecha: _fecha,
                onCambiar: (d) => setState(() => _fecha = d),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
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
      ),
    );
  }
}

// ───────────────── Editor de paso / hito ─────────────────

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
    builder: (_) => _EditorTarea(
      projectId: projectId,
      existente: existente,
      tipoInicial: tipoInicial,
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
  late final TextEditingController _nota;
  late final TextEditingController _monto;
  final _motivo = TextEditingController();
  late String _tipo;
  DateTime? _fecha;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _texto = TextEditingController(text: e?.texto ?? '');
    _nota = TextEditingController(text: e?.nota ?? '');
    _monto = TextEditingController(
        text: (e?.monto != null && e!.monto! > 0)
            ? milesConPuntos(e.monto!.round())
            : '');
    _tipo = e?.tipo ?? widget.tipoInicial;
    _fecha = e?.fechaObjetivo;
  }

  @override
  void dispose() {
    _texto.dispose();
    _nota.dispose();
    _monto.dispose();
    _motivo.dispose();
    super.dispose();
  }

  /// ¿Cambió la fecha respecto a la que tenía el paso? (para pedir motivo)
  bool get _fechaCambio {
    final e = widget.existente;
    if (e == null) return false;
    final a = e.fechaObjetivo;
    final b = _fecha;
    if (a == null && b == null) return false;
    if (a == null || b == null) return true;
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  Future<void> _guardar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _guardando) return;
    setState(() => _guardando = true);
    final acc = ref.read(proyectosAccionesProvider);
    final nota = _nota.text;
    final monto = parseMonto(_monto.text);
    try {
      if (widget.existente == null) {
        if (_tipo == 'hito') {
          await acc.crearHito(widget.projectId, texto,
              fechaObjetivo: _fecha, nota: nota, monto: monto);
        } else {
          await acc.crearPaso(widget.projectId, texto,
              fechaObjetivo: _fecha, nota: nota, monto: monto);
        }
      } else {
        await acc.editarTarea(widget.existente!,
            texto: texto,
            tipo: _tipo,
            fechaObjetivo: _fecha,
            nota: nota,
            monto: monto,
            motivoFecha: _motivo.text);
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
              AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
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
            if (_fechaCambio) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _motivo,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Motivo del cambio de fecha (opcional)',
                  hintText: 'Por qué se movió',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _monto,
              keyboardType: TextInputType.number,
              inputFormatters: [MilesInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Monto (opcional)',
                prefixText: '\$ ',
                hintText: 'Si este paso tiene un costo',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nota,
              maxLines: null,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Un apunte para este paso',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
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
      ),
    );
  }
}

// ───────────────── Registro de bitácora ─────────────────

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
    builder: (_) => _RegistroBitacora(projectId: projectId, esNota: esNota),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
              AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
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
                backgroundColor: AppColors.accent,
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
      ),
    );
  }
}

// ───────────────── Botón Avanzar (lógica compartida) ─────────────────

/// Acción del botón "Avanzar":
/// - Si hay próximo paso pendiente, lo completa (registra avance).
/// - Si NO hay pasos, NO completa nada: ofrece agregar un paso o registrar
///   un avance manual.
Future<void> avanzarProyecto(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required ProjectTask? proximo,
}) async {
  if (proximo != null) {
    await ref.read(proyectosAccionesProvider).completarTarea(proximo);
    return;
  }
  if (!context.mounted) return;
  await _mostrarAvanzarSinPasos(context, ref, projectId);
}

Future<void> _mostrarAvanzarSinPasos(
  BuildContext context,
  WidgetRef ref,
  String projectId,
) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: cs.surfaceContainerLow,
    builder: (sheetCtx) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Cómo quieres avanzar?',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Este proyecto aún no tiene pasos. Agrega el primero o deja '
              'registrado un avance.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(sheetCtx).pop();
                mostrarEditorTarea(context, ref,
                    projectId: projectId, tipoInicial: 'paso');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar próximo paso'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(sheetCtx).pop();
                mostrarRegistroBitacora(context, ref,
                    projectId: projectId, esNota: false);
              },
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.trending_up, size: 18),
              label: const Text('Registrar un avance'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ───────────────── Selector de meta (vincular proyecto) ─────────────────

class _SelectorMeta extends ConsumerWidget {
  const _SelectorMeta({required this.metaId, required this.onCambiar});
  final String? metaId;
  final ValueChanged<String?> onCambiar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final metas = ref.watch(metasVinculablesProvider).valueOrNull ?? const [];
    // Si la meta vinculada ya no existe, no forzamos un valor inválido.
    final valor = metas.any((m) => m.id == metaId) ? metaId : null;

    return DropdownButtonFormField<String?>(
      initialValue: valor,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Meta a la que pertenece',
        helperText: 'Al completar el proyecto, avanza esta meta',
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Sin meta')),
        for (final m in metas)
          DropdownMenuItem<String?>(
            value: m.id,
            child: Text('${m.emoji != null ? '${m.emoji} ' : ''}${m.label}',
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onCambiar,
      // Si no hay metas creadas, guía a crearlas en Finanzas.
      disabledHint: Text('Crea una meta en Finanzas primero',
          style:
              theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
    );
  }
}

// ───────────────── Selector de fecha (compartido) ─────────────────

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
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
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
