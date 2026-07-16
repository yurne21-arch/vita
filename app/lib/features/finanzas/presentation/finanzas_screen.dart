import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/moneda.dart';
import '../../../core/widgets/errores.dart';
import '../../../core/widgets/vita_card.dart';
import '../data/finanzas_repository.dart';
import '../domain/finanzas.dart';
import 'finanzas_controller.dart';
import 'finanzas_editores.dart';

enum _Seccion { movimientos, presupuesto, tarjetas, creditos, metas, deudas }

const _labels = {
  _Seccion.movimientos: 'Movimientos',
  _Seccion.presupuesto: 'Presupuesto',
  _Seccion.tarjetas: 'Tarjetas',
  _Seccion.creditos: 'Créditos',
  _Seccion.metas: 'Metas',
  _Seccion.deudas: 'Cuentas entre personas',
};

class FinanzasScreen extends ConsumerStatefulWidget {
  const FinanzasScreen({super.key});

  @override
  ConsumerState<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends ConsumerState<FinanzasScreen> {
  _Seccion _seccion = _Seccion.movimientos;

  @override
  void initState() {
    super.initState();
    // Abrir en el último mes con datos (los movimientos importados son de meses
    // pasados; abrir en el mes actual mostraría una pantalla vacía).
    Future.microtask(() async {
      try {
        final ult =
            await ref.read(finanzasRepositoryProvider).ultimoMesConDatos();
        if (ult != null && mounted) {
          ref.read(mesFinanzasProvider.notifier).state = ult;
        }
      } catch (_) {/* si falla, se queda en el mes actual */}
    });
  }

  void _cambiarMes(int delta) {
    final actual = ref.read(mesFinanzasProvider);
    ref.read(mesFinanzasProvider.notifier).state =
        DateTime(actual.year, actual.month + delta, 1);
  }

  bool get _puedeAgregar => true; // todas las secciones permiten agregar

  void _agregar() {
    switch (_seccion) {
      case _Seccion.movimientos:
        _menuMovimiento();
      case _Seccion.presupuesto:
        mostrarEditorPresupuesto(context, ref);
      case _Seccion.tarjetas:
        mostrarEditorTarjeta(context, ref);
      case _Seccion.creditos:
        mostrarEditorCredito(context, ref);
      case _Seccion.metas:
        mostrarEditorMeta(context, ref);
      case _Seccion.deudas:
        mostrarEditorDeuda(context, ref);
    }
  }

  void _menuMovimiento() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.south_west, color: AppColors.danger),
              title: const Text('Registrar gasto'),
              onTap: () {
                Navigator.of(context).pop();
                mostrarEditorMovimiento(context, ref, tipoInicial: 'gasto');
              },
            ),
            ListTile(
              leading: const Icon(Icons.north_east, color: AppColors.success),
              title: const Text('Registrar ingreso'),
              onTap: () {
                Navigator.of(context).pop();
                mostrarEditorMovimiento(context, ref, tipoInicial: 'ingreso');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mes = ref.watch(mesFinanzasProvider);
    final mostrarMes =
        _seccion == _Seccion.movimientos || _seccion == _Seccion.presupuesto;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: const Text('Finanzas'),
      ),
      floatingActionButton: _puedeAgregar
          ? FloatingActionButton(
              onPressed: _agregar,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              children: [
                if (mostrarMes) ...[
                  _SelectorMes(mes: mes, onCambiar: _cambiarMes),
                  const SizedBox(height: AppSpacing.md),
                  const _ResumenCard(),
                  const SizedBox(height: AppSpacing.md),
                ],
                _SelectorSeccion(
                  seccion: _seccion,
                  onChanged: (s) => setState(() => _seccion = s),
                ),
                const SizedBox(height: AppSpacing.md),
                switch (_seccion) {
                  _Seccion.movimientos => const _Movimientos(),
                  _Seccion.presupuesto => const _Presupuestos(),
                  _Seccion.tarjetas => const _Tarjetas(),
                  _Seccion.creditos => const _Creditos(),
                  _Seccion.metas => const _Metas(),
                  _Seccion.deudas => const _Deudas(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Selector de mes ──────────────────────────────────────────────

class _SelectorMes extends StatelessWidget {
  const _SelectorMes({required this.mes, required this.onCambiar});
  final DateTime mes;
  final ValueChanged<int> onCambiar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => onCambiar(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Mes anterior',
        ),
        Text('${_mesNombre(mes.month)} ${mes.year}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: () => onCambiar(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Mes siguiente',
        ),
      ],
    );
  }
}

// ── Resumen del mes ──────────────────────────────────────────────

class _ResumenCard extends ConsumerWidget {
  const _ResumenCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(resumenMesProvider);
    final r = async.valueOrNull ?? ResumenMes.vacio;

    if (async.hasError && async.valueOrNull == null) {
      return VitaCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorEnTarjeta(
          mensaje: mensajeDeError(async.error!),
          onReintentar: () => ref.invalidate(resumenMesProvider),
        ),
      );
    }

    final balancePos = r.balance >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BALANCE DEL MES',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              )),
          const SizedBox(height: AppSpacing.xs),
          Text(formatoMoneda(r.balance),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color:
                    balancePos ? theme.colorScheme.onSurface : AppColors.danger,
              )),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: 'Ingresos',
                    valor: formatoMoneda(r.ingresos),
                    color: AppColors.success),
              ),
              Expanded(
                child: _MiniStat(
                    label: 'Gastos',
                    valor: formatoMoneda(r.gastos),
                    color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.valor, required this.color});
  final String label;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(valor,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ── Selector de sección (chips horizontales) ─────────────────────

class _SelectorSeccion extends StatelessWidget {
  const _SelectorSeccion({required this.seccion, required this.onChanged});
  final _Seccion seccion;
  final ValueChanged<_Seccion> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final s in _Seccion.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(_labels[s]!),
                selected: seccion == s,
                onSelected: (_) => onChanged(s),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tricount: reparto compartido ─────────────────────────────────

class _TricountCard extends ConsumerWidget {
  const _TricountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final b = ref.watch(balanceCompartidoProvider).valueOrNull;
    if (b == null || b.total == 0) {
      return const _Vacio(
        icon: Icons.groups_outlined,
        titulo: 'Sin gastos compartidos.',
        subtitulo:
            'Marca un gasto como compartido y verás aquí quién le debe a quién.',
      );
    }
    final texto = b.equilibrado
        ? 'Están a mano.'
        : b.juanLeDebeAYurby
            ? 'Juan le debe a Yurby'
            : 'Yurby le debe a Juan';
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPARTO COMPARTIDO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  )),
              const SizedBox(height: AppSpacing.xs),
              Text(texto,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (!b.equilibrado)
                Text(formatoMoneda(b.montoAjuste),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.accent)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                        label: 'Puso Yurby',
                        valor: formatoMoneda(b.puestoPorYurby),
                        color: theme.colorScheme.onSurface),
                  ),
                  Expanded(
                    child: _MiniStat(
                        label: 'Puso Juan',
                        valor: formatoMoneda(b.puestoPorJuan),
                        color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'El total compartido se reparte por igual. La diferencia es lo que '
          'falta para quedar a mano.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Movimientos ──────────────────────────────────────────────────

class _Movimientos extends ConsumerWidget {
  const _Movimientos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(movimientosProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VitaCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorEnTarjeta(
          mensaje: mensajeDeError(e),
          onReintentar: () => ref.invalidate(movimientosProvider),
        ),
      ),
      data: (movs) {
        if (movs.isEmpty) {
          return const _Vacio(
            icon: Icons.receipt_long_outlined,
            titulo: 'Sin movimientos este mes.',
            subtitulo: 'Toca + para registrar un gasto o ingreso.',
          );
        }
        return VitaCard(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < movs.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _MovimientoRow(movimiento: movs[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MovimientoRow extends ConsumerWidget {
  const _MovimientoRow({required this.movimiento});
  final Movimiento movimiento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final m = movimiento;
    final color = m.esGasto ? AppColors.danger : AppColors.success;
    final detalle = [
      if (m.quien != null) m.quien,
      if (m.compartido) 'compartido',
      if (m.nota != null) m.nota,
      _fechaCorta(m.fecha),
    ].join(' · ');
    return InkWell(
      onTap: () => mostrarEditorMovimiento(context, ref, existente: m),
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(m.esGasto ? Icons.south_west : Icons.north_east,
                  size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.categoria,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('${m.esGasto ? '-' : '+'}${formatoMoneda(m.monto)}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: color)),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              tooltip: 'Opciones',
              onSelected: (op) {
                if (op == 'editar') {
                  mostrarEditorMovimiento(context, ref, existente: m);
                } else if (op == 'eliminar') {
                  accionSegura(
                    context,
                    () => ref
                        .read(finanzasAccionesProvider)
                        .eliminarMovimiento(m.id),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Presupuestos ─────────────────────────────────────────────────

class _Presupuestos extends ConsumerWidget {
  const _Presupuestos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presAsync = ref.watch(presupuestosProvider);
    final resumen =
        ref.watch(resumenMesProvider).valueOrNull ?? ResumenMes.vacio;

    return presAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VitaCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorEnTarjeta(
          mensaje: mensajeDeError(e),
          onReintentar: () => ref.invalidate(presupuestosProvider),
        ),
      ),
      data: (presupuestos) {
        if (presupuestos.isEmpty) {
          return const _Vacio(
            icon: Icons.savings_outlined,
            titulo: 'Sin presupuestos.',
            subtitulo:
                'Fija un tope mensual por categoría. Te acompaña, no te juzga.',
          );
        }
        return Column(
          children: [
            for (final p in presupuestos)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PresupuestoRow(
                  presupuesto: p,
                  gastado: resumen.porCategoria[p.categoria] ?? 0,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PresupuestoRow extends ConsumerWidget {
  const _PresupuestoRow({required this.presupuesto, required this.gastado});
  final Presupuesto presupuesto;
  final double gastado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = presupuesto;
    final fraccion =
        p.montoMensual <= 0 ? 0.0 : (gastado / p.montoMensual).clamp(0.0, 1.0);
    final excedido = gastado > p.montoMensual;
    return VitaCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.categoria,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(
                '${formatoMoneda(gastado)} / ${formatoMoneda(p.montoMensual)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: excedido
                      ? AppColors.danger
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                tooltip: 'Opciones',
                onSelected: (op) {
                  if (op == 'editar') {
                    mostrarEditorPresupuesto(context, ref,
                        categoriaInicial: p.categoria,
                        montoInicial: p.montoMensual);
                  } else if (op == 'eliminar') {
                    accionSegura(
                      context,
                      () => ref
                          .read(finanzasAccionesProvider)
                          .eliminarPresupuesto(p.id),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraccion,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: excedido ? AppColors.danger : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjetas ─────────────────────────────────────────────────────

class _Tarjetas extends ConsumerWidget {
  const _Tarjetas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(tarjetasProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VitaCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorEnTarjeta(
          mensaje: mensajeDeError(e),
          onReintentar: () => ref.invalidate(tarjetasProvider),
        ),
      ),
      data: (tarjetas) {
        if (tarjetas.isEmpty) {
          return const _Vacio(
            icon: Icons.credit_card_outlined,
            titulo: 'Sin tarjetas.',
            subtitulo: 'Aquí verás el cupo y la deuda de tus tarjetas.',
          );
        }
        return Column(
          children: [
            for (final t in tarjetas)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: VitaCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(t.nombre,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          Text('Cuota ${formatoMoneda(t.cuotaMes)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          _MenuEditarEliminar(
                            onEditar: () =>
                                mostrarEditorTarjeta(context, ref, existente: t),
                            onEliminar: () => accionSegura(
                              context,
                              () => ref
                                  .read(finanzasAccionesProvider)
                                  .eliminarTarjeta(t.id),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: t.usoFraccion,
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: t.usoFraccion > 0.8
                              ? AppColors.danger
                              : AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Deuda ${formatoMoneda(t.saldoDeuda)} · '
                        'Disponible ${formatoMoneda(t.disponible)} de ${formatoMoneda(t.cupo)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Créditos ─────────────────────────────────────────────────────

class _Creditos extends ConsumerWidget {
  const _Creditos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(creditosProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VitaCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorEnTarjeta(
          mensaje: mensajeDeError(e),
          onReintentar: () => ref.invalidate(creditosProvider),
        ),
      ),
      data: (creditos) {
        if (creditos.isEmpty) {
          return const _Vacio(
            icon: Icons.account_balance_outlined,
            titulo: 'Sin créditos.',
            subtitulo: 'Tus créditos y su avance aparecerán aquí.',
          );
        }
        final cuotaTotal =
            creditos.where((c) => !c.saldada).fold<double>(0, (a, c) => a + c.cuotaMensual);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('Cuotas del mes: ${formatoMoneda(cuotaTotal)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            for (final c in creditos)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: VitaCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.nombre,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          Text('Cuota ${formatoMoneda(c.cuotaMensual)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          _MenuEditarEliminar(
                            onEditar: () =>
                                mostrarEditorCredito(context, ref, existente: c),
                            onEliminar: () => accionSegura(
                              context,
                              () => ref
                                  .read(finanzasAccionesProvider)
                                  .eliminarCredito(c.id),
                            ),
                          ),
                        ],
                      ),
                      if (c.progreso != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (c.progreso! / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Total ${formatoMoneda(c.montoTotal)}'
                        '${c.fin != null ? ' · hasta ${c.fin}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Metas ────────────────────────────────────────────────────────

class _Metas extends ConsumerWidget {
  const _Metas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(metasProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VitaCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorEnTarjeta(
          mensaje: mensajeDeError(e),
          onReintentar: () => ref.invalidate(metasProvider),
        ),
      ),
      data: (metas) {
        if (metas.isEmpty) {
          return const _Vacio(
            icon: Icons.flag_outlined,
            titulo: 'Sin metas.',
            subtitulo: 'Tus sueños con monto aparecerán aquí.',
          );
        }
        return Column(
          children: [
            for (final m in metas)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: VitaCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${m.emoji ?? '🎯'}  ',
                              style: const TextStyle(fontSize: 18)),
                          Expanded(
                            child: Text(m.label,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          Text(formatoMoneda(m.metaMonto),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          _MenuEditarEliminar(
                            onEditar: () =>
                                mostrarEditorMeta(context, ref, existente: m),
                            onEliminar: () => accionSegura(
                              context,
                              () => ref
                                  .read(finanzasAccionesProvider)
                                  .eliminarMeta(m.id),
                            ),
                          ),
                        ],
                      ),
                      if (m.ahorrado > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: m.fraccion,
                            minHeight: 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Cuentas entre personas (Tricount) ────────────────────────────

class _Deudas extends ConsumerWidget {
  const _Deudas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(deudasProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TricountCard(),
        const SizedBox(height: AppSpacing.lg),
        Text('Otras cuentas',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => VitaCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ErrorEnTarjeta(
              mensaje: mensajeDeError(e),
              onReintentar: () => ref.invalidate(deudasProvider),
            ),
          ),
          data: (deudas) {
            if (deudas.isEmpty) {
              return const _Vacio(
                icon: Icons.handshake_outlined,
                titulo: 'Sin cuentas puntuales.',
                subtitulo: 'Anota una deuda suelta con + (yo debo / me deben).',
              );
            }
            return Column(children: [for (final d in deudas) _DeudaRow(deuda: d)]);
          },
        ),
      ],
    );
  }
}

class _DeudaRow extends ConsumerWidget {
  const _DeudaRow({required this.deuda});
  final Deuda deuda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final d = deuda;
    final color = d.yoDebo ? AppColors.danger : AppColors.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: VitaCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            IconButton(
              tooltip: d.saldada ? 'Marcar pendiente' : 'Marcar saldada',
              visualDensity: VisualDensity.compact,
              onPressed: () => accionSegura(
                context,
                () => ref
                    .read(finanzasAccionesProvider)
                    .marcarDeuda(d.id, saldada: !d.saldada),
              ),
              icon: Icon(
                d.saldada ? Icons.check_circle : Icons.circle_outlined,
                color: d.saldada ? AppColors.success : color,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.yoDebo ? 'Le debo a ${d.persona}' : '${d.persona} me debe',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: d.saldada ? TextDecoration.lineThrough : null,
                      color: d.saldada ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  if (d.descripcion != null)
                    Text(d.descripcion!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Text(formatoMoneda(d.monto),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: d.saldada ? theme.colorScheme.onSurfaceVariant : color,
                )),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              tooltip: 'Opciones',
              onSelected: (op) {
                if (op == 'editar') {
                  mostrarEditorDeuda(context, ref, existente: d);
                } else if (op == 'eliminar') {
                  accionSegura(
                    context,
                    () =>
                        ref.read(finanzasAccionesProvider).eliminarDeuda(d.id),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Piezas ───────────────────────────────────────────────────────

/// Menú de tres puntos con Editar / Eliminar, reutilizado por tarjetas,
/// créditos y metas.
class _MenuEditarEliminar extends StatelessWidget {
  const _MenuEditarEliminar({required this.onEditar, required this.onEliminar});
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert,
          size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
      tooltip: 'Opciones',
      onSelected: (op) => op == 'editar' ? onEditar() : onEliminar(),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'editar', child: Text('Editar')),
        PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio(
      {required this.icon, required this.titulo, required this.subtitulo});
  final IconData icon;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VitaCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(titulo,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitulo,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
        ],
      ),
    );
  }
}

String _mesNombre(int m) {
  const meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre' //
  ];
  return meses[m - 1];
}

String _fechaCorta(DateTime d) {
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic' //
  ];
  return '${d.day} ${meses[d.month - 1]}';
}
