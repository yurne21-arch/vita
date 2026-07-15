import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/errores.dart';
import '../domain/finanzas.dart';
import 'finanzas_controller.dart';

/// Abre el editor de movimiento (gasto o ingreso). Si [existente] no es null,
/// edita; si no, crea con el [tipoInicial] dado.
Future<void> mostrarEditorMovimiento(
  BuildContext context,
  WidgetRef ref, {
  Movimiento? existente,
  String tipoInicial = 'gasto',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _MovimientoEditor(existente: existente, tipoInicial: tipoInicial),
  );
}

class _MovimientoEditor extends ConsumerStatefulWidget {
  const _MovimientoEditor({this.existente, required this.tipoInicial});
  final Movimiento? existente;
  final String tipoInicial;

  @override
  ConsumerState<_MovimientoEditor> createState() => _MovimientoEditorState();
}

class _MovimientoEditorState extends ConsumerState<_MovimientoEditor> {
  late String _tipo;
  late String _ambito;
  String? _categoria;
  String _quien = 'Yurby';
  bool _compartido = false;
  late DateTime _fecha;
  late final TextEditingController _monto;
  late final TextEditingController _nota;
  bool _guardando = false;

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _tipo = e?.tipo ?? widget.tipoInicial;
    _ambito = e?.ambito ?? 'personal';
    _categoria = e?.categoria;
    _quien = e?.quien ?? 'Yurby';
    _compartido = e?.compartido ?? false;
    _fecha = e?.fecha ?? DateTime.now();
    _monto = TextEditingController(
        text: e != null ? e.monto.round().toString() : '');
    _nota = TextEditingController(text: e?.nota ?? '');
  }

  @override
  void dispose() {
    _monto.dispose();
    _nota.dispose();
    super.dispose();
  }

  List<String> get _categorias =>
      _tipo == 'gasto' ? kCategoriasGasto : kCategoriasIngreso;

  Future<void> _guardar() async {
    final monto = double.tryParse(_monto.text.trim().replaceAll('.', ''));
    if (monto == null || monto <= 0) {
      _aviso('Escribe un monto válido.');
      return;
    }
    if (_categoria == null) {
      _aviso('Elige una categoría.');
      return;
    }
    setState(() => _guardando = true);
    final acc = ref.read(finanzasAccionesProvider);
    try {
      if (_esEdicion) {
        await acc.editarMovimiento(
          widget.existente!.id,
          monto: monto,
          categoria: _categoria!,
          ambito: _ambito,
          fecha: _fecha,
          nota: _nota.text,
          quien: _quien,
          compartido: _compartido,
        );
      } else {
        await acc.crearMovimiento(
          tipo: _tipo,
          monto: monto,
          categoria: _categoria!,
          ambito: _ambito,
          fecha: _fecha,
          nota: _nota.text,
          quien: _quien,
          compartido: _compartido,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _aviso(mensajeDeError(e));
      }
    }
  }

  void _aviso(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  Future<void> _elegirFecha() async {
    final sel = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (sel != null) setState(() => _fecha = sel);
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
            Text(
              _esEdicion
                  ? 'Editar movimiento'
                  : (_tipo == 'gasto' ? 'Nuevo gasto' : 'Nuevo ingreso'),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!_esEdicion)
              _Segmento(
                opciones: const [('gasto', 'Gasto'), ('ingreso', 'Ingreso')],
                valor: _tipo,
                onChanged: (v) => setState(() {
                  _tipo = v;
                  _categoria = null; // las categorías cambian según tipo
                }),
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _monto,
              autofocus: !_esEdicion,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Categoría', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final c in _categorias)
                  ChoiceChip(
                    label: Text(c),
                    selected: _categoria == c,
                    onSelected: (_) => setState(() => _categoria = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Segmento(
              opciones: const [('personal', 'Personal'), ('casa', 'Casa')],
              valor: _ambito,
              onChanged: (v) => setState(() => _ambito = v),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Quién pagó', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            _Segmento(
              opciones: const [
                ('Yurby', 'Yurby'),
                ('Juan', 'Juan'),
                ('Ambos', 'Ambos'),
              ],
              valor: _quien,
              onChanged: (v) => setState(() => _quien = v),
            ),
            const SizedBox(height: AppSpacing.xs),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gasto compartido'),
              subtitle: const Text('Se reparte entre ambos (cuenta Tricount)'),
              value: _compartido,
              onChanged: (v) => setState(() => _compartido = v),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elegirFecha,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(_fechaCorta(_fecha)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nota,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
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
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editor de deuda (yo debo / me deben).
Future<void> mostrarEditorDeuda(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _DeudaEditor(),
  );
}

class _DeudaEditor extends ConsumerStatefulWidget {
  const _DeudaEditor();

  @override
  ConsumerState<_DeudaEditor> createState() => _DeudaEditorState();
}

class _DeudaEditorState extends ConsumerState<_DeudaEditor> {
  String _direccion = 'debo';
  DateTime _fecha = DateTime.now();
  final _persona = TextEditingController();
  final _monto = TextEditingController();
  final _desc = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _persona.dispose();
    _monto.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_monto.text.trim().replaceAll('.', ''));
    if (monto == null || monto <= 0) {
      _aviso('Escribe un monto válido.');
      return;
    }
    if (_persona.text.trim().isEmpty) {
      _aviso('¿Con quién es la deuda?');
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(finanzasAccionesProvider).crearDeuda(
            direccion: _direccion,
            persona: _persona.text,
            monto: monto,
            fecha: _fecha,
            descripcion: _desc.text,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _aviso(mensajeDeError(e));
      }
    }
  }

  void _aviso(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

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
            Text('Nueva deuda',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.lg),
            _Segmento(
              opciones: const [('debo', 'Yo debo'), ('me_deben', 'Me deben')],
              valor: _direccion,
              onChanged: (v) => setState(() => _direccion = v),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _persona,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _direccion == 'debo' ? 'A quién le debo' : 'Quién me debe',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _monto,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Monto', prefixText: '\$ '),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _desc,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(labelText: 'Concepto (opcional)'),
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
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editor de presupuesto para una categoría.
Future<void> mostrarEditorPresupuesto(
  BuildContext context,
  WidgetRef ref, {
  String? categoriaInicial,
  double? montoInicial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PresupuestoEditor(
      categoriaInicial: categoriaInicial,
      montoInicial: montoInicial,
    ),
  );
}

class _PresupuestoEditor extends ConsumerStatefulWidget {
  const _PresupuestoEditor({this.categoriaInicial, this.montoInicial});
  final String? categoriaInicial;
  final double? montoInicial;

  @override
  ConsumerState<_PresupuestoEditor> createState() => _PresupuestoEditorState();
}

class _PresupuestoEditorState extends ConsumerState<_PresupuestoEditor> {
  String? _categoria;
  late final TextEditingController _monto;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _categoria = widget.categoriaInicial;
    _monto = TextEditingController(
        text: widget.montoInicial != null
            ? widget.montoInicial!.round().toString()
            : '');
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_monto.text.trim().replaceAll('.', ''));
    if (monto == null || monto < 0) {
      _aviso('Escribe un monto válido.');
      return;
    }
    if (_categoria == null) {
      _aviso('Elige una categoría.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref
          .read(finanzasAccionesProvider)
          .fijarPresupuesto(_categoria!, monto);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _aviso(mensajeDeError(e));
      }
    }
  }

  void _aviso(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

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
            Text('Presupuesto mensual',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('Un tope que te acompaña, no que te juzga.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final c in kCategoriasGasto)
                  ChoiceChip(
                    label: Text(c),
                    selected: _categoria == c,
                    onSelected: (_) => setState(() => _categoria = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _monto,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Monto mensual', prefixText: '\$ '),
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
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmento tipo pill (dos o tres opciones). Reutilizado por los tres editores.
class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.opciones,
    required this.valor,
    required this.onChanged,
  });

  final List<(String, String)> opciones; // (valor, etiqueta)
  final String valor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        children: [
          for (final (v, label) in opciones)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: valor == v ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radius - 3),
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valor == v
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _fechaCorta(DateTime d) {
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic' //
  ];
  final hoy = DateTime.now();
  if (d.year == hoy.year && d.month == hoy.month && d.day == hoy.day) {
    return 'Hoy';
  }
  return '${d.day} ${meses[d.month - 1]}';
}
