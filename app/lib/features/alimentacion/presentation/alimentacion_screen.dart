import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/errores.dart';
import '../../../core/widgets/eyebrow.dart';
import '../../../core/widgets/vita_card.dart';
import '../domain/motor.dart';
import 'alimentacion_controller.dart';

class AlimentacionScreen extends ConsumerWidget {
  const AlimentacionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final plan = ref.watch(planSemanaProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text('Alimentación'),
          backgroundColor: cs.surface,
          scrolledUnderElevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Hoy'),
              Tab(text: 'Semana'),
              Tab(text: 'Producción'),
              Tab(text: 'Compras'),
            ],
          ),
        ),
        body: SafeArea(
          child: plan.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: VitaCard(
                child: ErrorEnTarjeta(
                  mensaje: '$e',
                  onReintentar: () => ref.invalidate(planSemanaProvider),
                ),
              ),
            ),
            data: (p) {
              final biblioteca = ref.watch(bibliotecaProvider);
              return TabBarView(
                children: [
                  _TabHoy(plan: p, biblioteca: biblioteca),
                  _TabSemana(plan: p),
                  _TabProduccion(plan: p),
                  _TabCompras(plan: p),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// Envoltura scrollable centrada y responsive, común a las pestañas.
class _Pagina extends StatelessWidget {
  const _Pagina({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final pad = c.maxWidth >= 700 ? 24.0 : 16.0;
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(pad, AppSpacing.lg, pad, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ── HOY ────────────────────────────────────────────────────────────────────

class _TabHoy extends StatelessWidget {
  const _TabHoy({required this.plan, required this.biblioteca});
  final PlanSemana plan;
  final Biblioteca biblioteca;

  @override
  Widget build(BuildContext context) {
    final hoy = plan.diaDe(DateTime.now()) ?? plan.dias.first;
    return _Pagina(children: [
      Eyebrow(hoy.nombre),
      const SizedBox(height: AppSpacing.xs),
      Text('Tu día', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.lg),
      for (final comida in hoy.comidas) ...[
        _TarjetaComida(comida: comida, biblioteca: biblioteca),
        const SizedBox(height: AppSpacing.md),
      ],
      const _NotaProvisional(),
    ]);
  }
}

class _TarjetaComida extends StatelessWidget {
  const _TarjetaComida({required this.comida, required this.biblioteca});
  final ComidaPlan comida;
  final Biblioteca biblioteca;

  static const _titulos = {
    'desayuno': 'Desayuno',
    'almuerzo': 'Almuerzo',
    'merienda': 'Merienda',
    'finde': 'Almuerzo',
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(_titulos[comida.momento] ?? comida.momento),
          const SizedBox(height: AppSpacing.xs),
          Text(comida.ensamble.nombre, style: t.titleMedium),
          if (comida.alternativa != null) ...[
            const SizedBox(height: 2),
            Text('o ${comida.alternativa!.nombre}',
                style: t.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: AppSpacing.sm),
          for (final por in comida.porciones)
            _PorcionResumen(
                comida: comida, porcion: por, biblioteca: biblioteca),
        ],
      ),
    );
  }
}

class _PorcionResumen extends StatelessWidget {
  const _PorcionResumen({
    required this.comida,
    required this.porcion,
    required this.biblioteca,
  });
  final ComidaPlan comida;
  final PorcionCalculada porcion;
  final Biblioteca biblioteca;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final partes = <String>[];
    for (final comp in comida.ensamble.componentes) {
      final g = porcion.gramos[comp.id];
      if (g == null || g <= 0) continue;
      final a = biblioteca.alimentoDe(comp);
      if (a == null) continue;
      partes.add('${a.nombre} ${g.round()} ${a.unidad}');
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(porcion.persona,
              style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(partes.join(' · '), style: t.bodyMedium?.copyWith(color: muted)),
          // Detalle auditable (macros ocultos por defecto).
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
              minTileHeight: 36,
              dense: true,
              title: Text('Ver detalle',
                  style: t.labelSmall?.copyWith(color: AppColors.accent)),
              children: [
                _lineaMacros(context, porcion),
                if (porcion.ajuste != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text('Ajuste: ${porcion.ajuste}',
                        style: t.bodySmall?.copyWith(color: muted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineaMacros(BuildContext context, PorcionCalculada p) {
    final m = p.macros;
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Text(
      '${m.kcal.round()} kcal · P ${m.prot.round()} · C ${m.carb.round()} · G ${m.grasa.round()} · Fibra ${m.fibra.round()}',
      style: t.bodySmall?.copyWith(color: muted),
    );
  }
}

// ── SEMANA ─────────────────────────────────────────────────────────────────

class _TabSemana extends StatelessWidget {
  const _TabSemana({required this.plan});
  final PlanSemana plan;

  static const _titulos = {
    'desayuno': 'Desayuno',
    'almuerzo': 'Almuerzo',
    'merienda': 'Merienda',
    'finde': 'Almuerzo',
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return _Pagina(children: [
      for (final dia in plan.dias) ...[
        VitaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dia.nombre, style: t.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final c in dia.comidas)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(_titulos[c.momento] ?? c.momento,
                            style: t.bodySmall?.copyWith(color: muted)),
                      ),
                      Expanded(
                          child: Text(c.ensamble.nombre, style: t.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ]);
  }
}

// ── PRODUCCIÓN ─────────────────────────────────────────────────────────────

class _TabProduccion extends StatelessWidget {
  const _TabProduccion({required this.plan});
  final PlanSemana plan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return _Pagina(children: [
      const Eyebrow('Domingo'),
      const SizedBox(height: AppSpacing.xs),
      Text('${plan.produccionesBase} producciones base',
          style: t.headlineSmall),
      const SizedBox(height: AppSpacing.xs),
      Text(
          'Se cuecen una vez y de ahí salen las comidas de la semana. Las terminaciones no suman una producción nueva.',
          style: t.bodyMedium?.copyWith(color: muted)),
      const SizedBox(height: AppSpacing.lg),
      for (final prod in plan.producciones) ...[
        VitaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prod.base.nombre, style: t.titleMedium),
              const SizedBox(height: 2),
              Text(
                  'Comprar ~${_kg(prod.crudoG)} · rinde ~${_kg(prod.cocidoG)} cocido',
                  style: t.bodyMedium?.copyWith(color: muted)),
              if (prod.terminaciones.length > 1) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('Terminaciones: ${prod.terminaciones.join(' · ')}',
                    style: t.bodySmall?.copyWith(color: muted)),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      const SizedBox(height: AppSpacing.sm),
      Text('Refrigeración y congelación', style: t.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      for (final cons in plan.conservacion)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            '${cons.estado == 'refri' ? '🧊 Refri' : '❄️ Congelar'} · ${cons.preparacion} · hasta ${_fecha(cons.fechaMaxConsumo)}'
            '${cons.fechaDescongelar != null ? ' · descongelar ${_fecha(cons.fechaDescongelar!)}' : ''}',
            style: t.bodySmall?.copyWith(color: muted),
          ),
        ),
    ]);
  }

  String _kg(double g) =>
      g >= 1000 ? '${(g / 1000).toStringAsFixed(1)} kg' : '${g.round()} g';
  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

// ── COMPRAS ────────────────────────────────────────────────────────────────

class _TabCompras extends StatelessWidget {
  const _TabCompras({required this.plan});
  final PlanSemana plan;

  @override
  Widget build(BuildContext context) {
    return _Pagina(children: [
      _ListaCompra(titulo: 'Compra principal', items: plan.compras.principal),
      const SizedBox(height: AppSpacing.md),
      _ListaCompra(
          titulo: 'Reposición de frescos', items: plan.compras.reposicion),
    ]);
  }
}

class _ListaCompra extends StatelessWidget {
  const _ListaCompra({required this.titulo, required this.items});
  final String titulo;
  final List<ItemCompra> items;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            Text('—', style: t.bodyMedium?.copyWith(color: muted))
          else
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(it.nombre, style: t.bodyMedium)),
                    Text(_cant(it),
                        style: t.bodyMedium?.copyWith(
                            color: muted,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ])),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _cant(ItemCompra it) {
    if (it.unidad == 'unidad') return '${it.cantidad.round()} u';
    if (it.cantidad >= 1000) {
      return '${(it.cantidad / 1000).toStringAsFixed(1)} kg';
    }
    return '${it.cantidad.round()} ${it.unidad}';
  }
}

class _NotaProvisional extends StatelessWidget {
  const _NotaProvisional();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        'Las cantidades y calorías son provisionales hasta calcular tu perfil real.',
        style: t.bodySmall?.copyWith(color: muted),
      ),
    );
  }
}
