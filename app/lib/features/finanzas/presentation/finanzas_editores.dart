import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/moneda.dart';
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
  String? categoriaInicial,
  String? loanIdInicial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MovimientoEditor(
      existente: existente,
      tipoInicial: tipoInicial,
      categoriaInicial: categoriaInicial,
      loanIdInicial: loanIdInicial,
    ),
  );
}

class _MovimientoEditor extends ConsumerStatefulWidget {
  const _MovimientoEditor({
    this.existente,
    required this.tipoInicial,
    this.categoriaInicial,
    this.loanIdInicial,
  });
  final Movimiento? existente;
  final String tipoInicial;
  final String? categoriaInicial;
  final String? loanIdInicial;

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

  // Medio de pago: 'efectivo' | 'cuenta:<id>' | 'tarjeta:<id>'
  String _medio = 'efectivo';
  String? _loanId; // crédito a pagar (si categoría = Pago Deuda)

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _tipo = e?.tipo ?? widget.tipoInicial;
    _ambito = e?.ambito ?? 'personal';
    _categoria = e?.categoria ?? widget.categoriaInicial;
    _quien = e?.quien ?? 'Yurby';
    _compartido = e?.compartido ?? false;
    _fecha = e?.fecha ?? DateTime.now();
    _loanId = e?.loanId ?? widget.loanIdInicial;
    if (e?.cuentaId != null) {
      _medio = 'cuenta:${e!.cuentaId}';
    } else if (e?.tarjetaId != null) {
      _medio = 'tarjeta:${e!.tarjetaId}';
    }
    _monto = TextEditingController(
        text: e != null ? milesConPuntos(e.monto.round()) : '');
    _nota = TextEditingController(text: e?.nota ?? '');
  }

  String? get _cuentaId =>
      _medio.startsWith('cuenta:') ? _medio.substring(7) : null;
  String? get _tarjetaId =>
      _medio.startsWith('tarjeta:') ? _medio.substring(8) : null;

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
      final esPagoDeuda = _categoria == 'Pago Deuda';
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
          cuentaId: _cuentaId,
          tarjetaId: _tarjetaId,
          loanId: esPagoDeuda ? _loanId : null,
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
          cuentaId: _cuentaId,
          tarjetaId: _tarjetaId,
          loanId: esPagoDeuda ? _loanId : null,
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

  void _aviso(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
              inputFormatters: [MilesInputFormatter()],
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
            // Si es "Pago Deuda": elegir a qué crédito va (para que se registre
            // la cuota automáticamente).
            if (_categoria == 'Pago Deuda') ...[
              const SizedBox(height: AppSpacing.md),
              _SelectorCredito(
                valor: _loanId,
                onChanged: (v) => setState(() => _loanId = v),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // Medio de pago: ajusta el saldo de la cuenta/tarjeta al guardar.
            _SelectorMedio(
              valor: _medio,
              onChanged: (v, quienSugerido, compartidoSugerido) => setState(() {
                _medio = v;
                if (quienSugerido != null) _quien = quienSugerido;
                if (compartidoSugerido != null)
                  _compartido = compartidoSugerido;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            _Segmento(
              opciones: const [('personal', 'Personal'), ('casa', 'Casa')],
              valor: _ambito,
              onChanged: (v) => setState(() => _ambito = v),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Quién puso la plata', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            _Segmento(
              // Siempre paga una persona. Que sea "de ambos" lo maneja el
              // interruptor "Gasto compartido" de abajo.
              opciones: const [
                ('Yurby', 'Yurby'),
                ('Juan', 'Juan'),
              ],
              valor: _quien == 'Ambos' ? 'Yurby' : _quien,
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

/// Selector de medio de pago (efectivo / cuentas / tarjetas). Al elegir una
/// tarjeta de crédito sugiere quién pagó (su titular) y "compartido"; al elegir
/// una cuenta sugiere su titular. Ajusta el saldo al guardar.
class _SelectorMedio extends ConsumerWidget {
  const _SelectorMedio({required this.valor, required this.onChanged});
  final String valor;
  // (medioKey, quienSugerido, compartidoSugerido)
  final void Function(String, String?, bool?) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentas = ref.watch(cuentasProvider).valueOrNull ?? const <Cuenta>[];
    final tarjetas =
        ref.watch(tarjetasProvider).valueOrNull ?? const <Tarjeta>[];
    return DropdownButtonFormField<String>(
      initialValue: valor,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Pagado con'),
      items: [
        const DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
        for (final c in cuentas)
          DropdownMenuItem(value: 'cuenta:${c.id}', child: Text(c.nombre)),
        for (final t in tarjetas)
          DropdownMenuItem(value: 'tarjeta:${t.id}', child: Text(t.nombre)),
      ],
      onChanged: (v) {
        if (v == null) return;
        if (v.startsWith('tarjeta:')) {
          final t = tarjetas.firstWhere((x) => 'tarjeta:${x.id}' == v);
          // Tarjeta de crédito: la puso su titular y suele ser gasto de casa.
          onChanged(v, t.titular, true);
        } else if (v.startsWith('cuenta:')) {
          final c = cuentas.firstWhere((x) => 'cuenta:${x.id}' == v);
          onChanged(v, c.titular, null);
        } else {
          onChanged(v, null, null);
        }
      },
    );
  }
}

/// Selector del crédito a pagar (para movimientos categoría "Pago Deuda").
class _SelectorCredito extends ConsumerWidget {
  const _SelectorCredito({required this.valor, required this.onChanged});
  final String? valor;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditos =
        ref.watch(creditosProvider).valueOrNull ?? const <Credito>[];
    return DropdownButtonFormField<String>(
      initialValue: valor,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '¿Qué crédito pagas?'),
      items: [
        for (final c in creditos)
          DropdownMenuItem(value: c.id, child: Text(c.nombre)),
      ],
      onChanged: onChanged,
    );
  }
}

/// Editor de deuda (yo debo / me deben). Crea o edita.
Future<void> mostrarEditorDeuda(
  BuildContext context,
  WidgetRef ref, {
  Deuda? existente,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DeudaEditor(existente: existente),
  );
}

class _DeudaEditor extends ConsumerStatefulWidget {
  const _DeudaEditor({this.existente});
  final Deuda? existente;

  @override
  ConsumerState<_DeudaEditor> createState() => _DeudaEditorState();
}

class _DeudaEditorState extends ConsumerState<_DeudaEditor> {
  late String _direccion;
  DateTime _fecha = DateTime.now();
  late final TextEditingController _persona;
  late final TextEditingController _monto;
  late final TextEditingController _desc;
  bool _guardando = false;

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _direccion = e?.direccion ?? 'debo';
    _fecha = e?.fecha ?? DateTime.now();
    _persona = TextEditingController(text: e?.persona ?? '');
    _monto = TextEditingController(
        text: e != null ? milesConPuntos(e.monto.round()) : '');
    _desc = TextEditingController(text: e?.descripcion ?? '');
  }

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
      final acc = ref.read(finanzasAccionesProvider);
      if (_esEdicion) {
        await acc.editarDeuda(
          widget.existente!.id,
          direccion: _direccion,
          persona: _persona.text,
          monto: monto,
          descripcion: _desc.text,
        );
      } else {
        await acc.crearDeuda(
          direccion: _direccion,
          persona: _persona.text,
          monto: monto,
          fecha: _fecha,
          descripcion: _desc.text,
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

  void _aviso(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
            Text(_esEdicion ? 'Editar deuda' : 'Nueva deuda',
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
                labelText:
                    _direccion == 'debo' ? 'A quién le debo' : 'Quién me debe',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _monto,
              keyboardType: TextInputType.number,
              inputFormatters: [MilesInputFormatter()],
              decoration:
                  const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
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
            ? milesConPuntos(widget.montoInicial!.round())
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

  void _aviso(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
              inputFormatters: [MilesInputFormatter()],
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

// ═══════════════════════════════════════════════════════════════
// TARJETA DE CRÉDITO
// ═══════════════════════════════════════════════════════════════

Future<void> mostrarEditorTarjeta(
  BuildContext context,
  WidgetRef ref, {
  Tarjeta? existente,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TarjetaEditor(existente: existente),
  );
}

class _TarjetaEditor extends ConsumerStatefulWidget {
  const _TarjetaEditor({this.existente});
  final Tarjeta? existente;
  @override
  ConsumerState<_TarjetaEditor> createState() => _TarjetaEditorState();
}

class _TarjetaEditorState extends ConsumerState<_TarjetaEditor> {
  late final TextEditingController _nombre;
  late final TextEditingController _cupo;
  late final TextEditingController _saldo;
  late final TextEditingController _cuota;
  String _titular = 'Yurby';
  bool _guardando = false;

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existente;
    _nombre = TextEditingController(text: t?.nombre ?? '');
    _cupo = TextEditingController(text: _num(t?.cupo));
    _saldo = TextEditingController(text: _num(t?.saldoDeuda));
    _cuota = TextEditingController(text: _num(t?.cuotaMes));
    _titular = t?.titular ?? 'Yurby';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _cupo.dispose();
    _saldo.dispose();
    _cuota.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty) {
      _snack(context, 'Ponle un nombre a la tarjeta.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(finanzasAccionesProvider).guardarTarjeta(
            id: widget.existente?.id,
            nombre: _nombre.text,
            titular: _titular,
            cupo: _monto(_cupo),
            saldoDeuda: _monto(_saldo),
            cuotaMes: _monto(_cuota),
            diaCierre: widget.existente?.diaCierre,
            diaPago: widget.existente?.diaPago,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _snack(context, mensajeDeError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HojaEditor(
      titulo: _esEdicion ? 'Editar tarjeta' : 'Nueva tarjeta',
      guardando: _guardando,
      onGuardar: _guardar,
      campos: [
        _campoTexto(_nombre, 'Nombre (ej. Falabella)'),
        const SizedBox(height: AppSpacing.md),
        _Segmento(
          opciones: const [('Yurby', 'Yurby'), ('Juan', 'Juan')],
          valor: _titular,
          onChanged: (v) => setState(() => _titular = v),
        ),
        const SizedBox(height: AppSpacing.md),
        _campoMonto(_cupo, 'Cupo total'),
        const SizedBox(height: AppSpacing.md),
        _campoMonto(_saldo, 'Deuda actual'),
        const SizedBox(height: AppSpacing.md),
        _campoMonto(_cuota, 'Cuota del mes'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CRÉDITO / DEUDA ESTRUCTURADA
// ═══════════════════════════════════════════════════════════════

Future<void> mostrarEditorCredito(
  BuildContext context,
  WidgetRef ref, {
  Credito? existente,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CreditoEditor(existente: existente),
  );
}

class _CreditoEditor extends ConsumerStatefulWidget {
  const _CreditoEditor({this.existente});
  final Credito? existente;
  @override
  ConsumerState<_CreditoEditor> createState() => _CreditoEditorState();
}

class _CreditoEditorState extends ConsumerState<_CreditoEditor> {
  late final TextEditingController _nombre;
  late final TextEditingController _cuota;
  late final TextEditingController _total;
  late final TextEditingController _fin;
  double _progreso = 0;
  bool _guardando = false;

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existente;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _cuota = TextEditingController(text: _num(c?.cuotaMensual));
    _total = TextEditingController(text: _num(c?.montoTotal));
    _fin = TextEditingController(text: c?.fin ?? '');
    _progreso = (c?.progreso ?? 0).toDouble();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _cuota.dispose();
    _total.dispose();
    _fin.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty) {
      _snack(context, 'Ponle un nombre al crédito.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(finanzasAccionesProvider).guardarCredito(
            id: widget.existente?.id,
            nombre: _nombre.text,
            cuotaMensual: _monto(_cuota),
            montoTotal: _monto(_total),
            fin: _fin.text,
            progreso: _progreso.round(),
            saldada: _progreso >= 100,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _snack(context, mensajeDeError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _HojaEditor(
      titulo: _esEdicion ? 'Editar crédito' : 'Nuevo crédito',
      guardando: _guardando,
      onGuardar: _guardar,
      campos: [
        _campoTexto(_nombre, 'Nombre (ej. Hipoteca casa)'),
        const SizedBox(height: AppSpacing.md),
        _campoMonto(_cuota, 'Cuota mensual'),
        const SizedBox(height: AppSpacing.md),
        _campoMonto(_total, 'Monto total'),
        const SizedBox(height: AppSpacing.md),
        _campoTexto(_fin, 'Hasta (ej. Abr 2030)'),
        const SizedBox(height: AppSpacing.md),
        Text('Avance: ${_progreso.round()}%',
            style: theme.textTheme.labelLarge),
        Slider(
          value: _progreso,
          max: 100,
          divisions: 100,
          label: '${_progreso.round()}%',
          onChanged: (v) => setState(() => _progreso = v),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// META DE AHORRO
// ═══════════════════════════════════════════════════════════════

Future<void> mostrarEditorMeta(
  BuildContext context,
  WidgetRef ref, {
  Meta? existente,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MetaEditor(existente: existente),
  );
}

class _MetaEditor extends ConsumerStatefulWidget {
  const _MetaEditor({this.existente});
  final Meta? existente;
  @override
  ConsumerState<_MetaEditor> createState() => _MetaEditorState();
}

class _MetaEditorState extends ConsumerState<_MetaEditor> {
  late final TextEditingController _label;
  late final TextEditingController _emoji;
  late final TextEditingController _meta;
  late final TextEditingController _ahorrado;
  bool _guardando = false;

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existente;
    _label = TextEditingController(text: m?.label ?? '');
    _emoji = TextEditingController(text: m?.emoji ?? '');
    _meta = TextEditingController(text: _num(m?.metaMonto));
    _ahorrado = TextEditingController(text: _num(m?.ahorrado));
  }

  @override
  void dispose() {
    _label.dispose();
    _emoji.dispose();
    _meta.dispose();
    _ahorrado.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_label.text.trim().isEmpty) {
      _snack(context, 'Ponle un nombre a la meta.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(finanzasAccionesProvider).guardarMeta(
            id: widget.existente?.id,
            label: _label.text,
            emoji: _emoji.text,
            metaMonto: _monto(_meta),
            ahorrado: _monto(_ahorrado),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _snack(context, mensajeDeError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HojaEditor(
      titulo: _esEdicion ? 'Editar meta' : 'Nueva meta',
      guardando: _guardando,
      onGuardar: _guardar,
      campos: [
        Row(
          children: [
            SizedBox(
              width: 72,
              child: _campoTexto(_emoji, '🎯'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _campoTexto(_label, 'Nombre (ej. Viaje)')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _campoMonto(_meta, 'Monto a juntar'),
        const SizedBox(height: AppSpacing.md),
        _campoMonto(_ahorrado, 'Ya ahorrado'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUENTA (saldo)
// ═══════════════════════════════════════════════════════════════

Future<void> mostrarEditorCuenta(
  BuildContext context,
  WidgetRef ref, {
  Cuenta? existente,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CuentaEditor(existente: existente),
  );
}

class _CuentaEditor extends ConsumerStatefulWidget {
  const _CuentaEditor({this.existente});
  final Cuenta? existente;
  @override
  ConsumerState<_CuentaEditor> createState() => _CuentaEditorState();
}

class _CuentaEditorState extends ConsumerState<_CuentaEditor> {
  late final TextEditingController _nombre;
  late final TextEditingController _saldo;
  String _titular = 'Yurby';
  bool _guardando = false;

  bool get _esEdicion => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existente;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _saldo = TextEditingController(text: _num(c?.saldo));
    _titular = c?.titular ?? 'Yurby';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _saldo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty) {
      _snack(context, 'Ponle un nombre a la cuenta.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(finanzasAccionesProvider).guardarCuenta(
            id: widget.existente?.id,
            nombre: _nombre.text,
            titular: _titular,
            saldo: _monto(_saldo),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _snack(context, mensajeDeError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HojaEditor(
      titulo: _esEdicion ? 'Editar cuenta' : 'Nueva cuenta',
      guardando: _guardando,
      onGuardar: _guardar,
      campos: [
        _campoTexto(_nombre, 'Nombre (ej. Débito Yurby)'),
        const SizedBox(height: AppSpacing.md),
        _Segmento(
          opciones: const [
            ('Yurby', 'Yurby'),
            ('Juan', 'Juan'),
            ('Ambos', 'Ambos'),
          ],
          valor: _titular,
          onChanged: (v) => setState(() => _titular = v),
        ),
        const SizedBox(height: AppSpacing.md),
        _campoMonto(_saldo, 'Saldo actual'),
      ],
    );
  }
}

/// Diálogo simple de monto + fecha (para pagos de crédito y abonos a metas).
Future<({double monto, DateTime fecha})?> pedirMontoYFecha(
  BuildContext context, {
  required String titulo,
  String etiquetaMonto = 'Monto',
}) async {
  final monto = TextEditingController();
  var fecha = DateTime.now();
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monto,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [MilesInputFormatter()],
              decoration:
                  InputDecoration(labelText: etiquetaMonto, prefixText: '\$ '),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text('${fecha.day}/${fecha.month}/${fecha.year}'),
                onPressed: () async {
                  final sel = await showDatePicker(
                    context: ctx,
                    initialDate: fecha,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (sel != null) setState(() => fecha = sel);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Guardar')),
        ],
      ),
    ),
  );
  final valor = double.tryParse(monto.text.trim().replaceAll('.', ''));
  monto.dispose();
  if (r != true || valor == null || valor <= 0) return null;
  return (monto: valor, fecha: fecha);
}

/// Diálogo para pagar una tarjeta: de qué cuenta sale, cuánto y cuándo.
Future<({String cuentaId, double monto, DateTime fecha})?> pedirPagoTarjeta(
  BuildContext context,
  WidgetRef ref, {
  required Tarjeta tarjeta,
}) async {
  final cuentas = ref.read(cuentasProvider).valueOrNull ?? const <Cuenta>[];
  if (cuentas.isEmpty) {
    _snack(context, 'Primero crea una cuenta (en Resumen → Saldos).');
    return null;
  }
  final monto = TextEditingController(
      text:
          tarjeta.cuotaMes > 0 ? milesConPuntos(tarjeta.cuotaMes.round()) : '');
  String cuentaId = cuentas.first.id;
  var fecha = DateTime.now();
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Pagar ${tarjeta.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: cuentaId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Desde qué cuenta'),
              items: [
                for (final c in cuentas)
                  DropdownMenuItem(value: c.id, child: Text(c.nombre)),
              ],
              onChanged: (v) => setState(() => cuentaId = v ?? cuentaId),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: monto,
              keyboardType: TextInputType.number,
              inputFormatters: [MilesInputFormatter()],
              decoration:
                  const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text('${fecha.day}/${fecha.month}/${fecha.year}'),
                onPressed: () async {
                  final sel = await showDatePicker(
                    context: ctx,
                    initialDate: fecha,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (sel != null) setState(() => fecha = sel);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Registrar pago')),
        ],
      ),
    ),
  );
  final valor = double.tryParse(monto.text.trim().replaceAll('.', ''));
  monto.dispose();
  if (r != true || valor == null || valor <= 0) return null;
  return (cuentaId: cuentaId, monto: valor, fecha: fecha);
}

// ── Piezas compartidas de los editores ──────────────────────────

String _num(double? v) =>
    (v == null || v == 0) ? '' : milesConPuntos(v.round());
double _monto(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll('.', '')) ?? 0;

void _snack(BuildContext context, String m) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

Widget _campoTexto(TextEditingController c, String label) => TextField(
      controller: c,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label),
    );

Widget _campoMonto(TextEditingController c, String label) => TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [MilesInputFormatter()],
      decoration: InputDecoration(labelText: label, prefixText: '\$ '),
    );

/// Hoja inferior estándar para los editores de finanzas (título + campos +
/// botón Guardar), para no repetir el andamiaje en cada uno.
class _HojaEditor extends StatelessWidget {
  const _HojaEditor({
    required this.titulo,
    required this.campos,
    required this.guardando,
    required this.onGuardar,
  });
  final String titulo;
  final List<Widget> campos;
  final bool guardando;
  final VoidCallback onGuardar;

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
            Text(titulo,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.lg),
            ...campos,
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: guardando ? null : onGuardar,
                child: guardando
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

/// Segmento tipo pill (dos o tres opciones). Reutilizado por los editores.
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
