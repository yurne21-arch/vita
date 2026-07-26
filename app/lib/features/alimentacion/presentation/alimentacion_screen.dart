import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/errores.dart';
import '../../../core/widgets/eyebrow.dart';
import '../../../core/widgets/vita_card.dart';
import '../domain/alimentacion.dart';
import '../domain/cocina_familiar.dart';
import '../domain/motor.dart';
import 'alimentacion_controller.dart';

class AlimentacionScreen extends ConsumerWidget {
  const AlimentacionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final plan = ref.watch(planSemanaProvider);
    final perfiles = ref.watch(perfilesNutricionalesProvider);
    final miNombre = perfiles.maybeWhen(
      data: (ps) => ps.isNotEmpty ? ps.first.nombre : 'Yurnelly',
      orElse: () => 'Yurnelly',
    );

    return DefaultTabController(
      length: 5,
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
              Tab(text: 'Menú de la semana'),
              Tab(text: 'Hoy cocinas'),
              Tab(text: 'Familia'),
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
              final nino = planNino(p, biblioteca);
              final perfilesLista = perfiles.asData?.value ?? const [];
              return TabBarView(
                children: [
                  _TabHoy(
                    plan: p,
                    biblioteca: biblioteca,
                    miNombre: miNombre,
                    nino: nino,
                  ),
                  _TabSemana(plan: p),
                  _TabCocina(plan: p),
                  _TabFamilia(
                    plan: p,
                    perfiles: perfilesLista,
                    nino: nino,
                    miNombre: miNombre,
                  ),
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

// ── HOY: abre como asistente, no como planificador ──────────────────────────

class _TabHoy extends StatelessWidget {
  const _TabHoy({
    required this.plan,
    required this.biblioteca,
    required this.miNombre,
    required this.nino,
  });
  final PlanSemana plan;
  final Biblioteca biblioteca;
  final String miNombre;
  final List<ComidaNino> nino;

  @override
  Widget build(BuildContext context) {
    final hoy = plan.diaDe(DateTime.now()) ?? plan.dias.first;
    final idxHoy = plan.dias.indexOf(hoy);
    final ninoHoy = (idxHoy >= 0 && idxHoy < nino.length) ? nino[idxHoy] : null;
    final t = Theme.of(context).textTheme;
    final hora = DateTime.now().hour;
    final saludo = hora < 12
        ? 'Buenos días'
        : (hora < 20 ? 'Buenas tardes' : 'Buenas noches');
    final emojiSaludo = hora < 12 ? '☀️' : (hora < 20 ? '🌤️' : '🌙');
    final estado = _estadoCocina(hoy);

    return _Pagina(children: [
      Text('$saludo, $miNombre $emojiSaludo', style: t.headlineSmall),
      const SizedBox(height: AppSpacing.xs),
      Text('Hoy ya tienes todo organizado.',
          style: t.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: AppSpacing.lg),

      // Tarjeta protagonista: la decisión del día, ya tomada.
      _TarjetaDecision(estado: estado),
      const SizedBox(height: AppSpacing.lg),

      Eyebrow('Tu ${hoy.nombre.toLowerCase()}'),
      const SizedBox(height: AppSpacing.sm),
      for (final comida in hoy.comidas) ...[
        _TarjetaComida(comida: comida, biblioteca: biblioteca, yo: miNombre),
        const SizedBox(height: AppSpacing.md),
      ],
      if (ninoHoy != null) ...[
        const SizedBox(height: AppSpacing.xs),
        _TarjetaNinoHoy(comida: ninoHoy),
        const SizedBox(height: AppSpacing.md),
      ],
      const _NotaProvisional(),
    ]);
  }

  // Heurística: domingo se cocina la tanda; miércoles, un mini-prep; el resto
  // de días no se cocina (se usa lo preparado).
  _EstadoCocina _estadoCocina(DiaPlan hoy) {
    final principal = hoy.comidas.firstWhere(
      (c) => c.momento == 'almuerzo' || c.momento == 'finde',
      orElse: () => hoy.comidas.first,
    );

    if (hoy.nombre == 'Domingo') {
      return const _EstadoCocina(
        cocina: true,
        titulo: 'Hoy es día de cocina',
        detalle: 'Preparas la tanda de la semana. Te guío paso a paso.',
        minutos: 90,
      );
    }
    if (hoy.nombre == 'Sábado') {
      return _EstadoCocina(
        cocina: true,
        titulo: 'Hoy cocinas algo especial',
        detalle:
            '${principal.ensamble.emoji ?? '🍽'} ${principal.ensamble.nombre}'
            '${principal.ensamble.descripcion != null ? ' — ${principal.ensamble.descripcion}' : ''}.',
        minutos: 45,
      );
    }
    if (hoy.nombre == 'Miércoles') {
      return const _EstadoCocina(
        cocina: true,
        titulo: 'Hoy, un mini-prep',
        detalle: 'Arroz fresco y cortar los frescos del día. ~25 minutos.',
        minutos: 25,
      );
    }
    // Día normal: no se cocina, se usa lo preparado.
    final usa = _proteinaPreparada(principal);
    final frescos = _frescosDelDia(principal);
    return _EstadoCocina(
      cocina: false,
      titulo: 'Hoy no necesitas cocinar',
      detalle: [
        if (usa != null) 'Usas $usa que dejaste listo.',
        if (frescos != null) 'Solo $frescos y servir.',
      ].join(' '),
      minutos: 8,
    );
  }

  String? _proteinaPreparada(ComidaPlan c) {
    for (final comp in c.ensamble.componentes) {
      final prep = biblioteca.preparacion(comp.preparationId);
      if (prep != null && prep.mealPrep) {
        final a = biblioteca.alimentoDe(comp);
        if (a != null) return 'el ${a.nombre.toLowerCase()} del domingo';
      }
    }
    return null;
  }

  String? _frescosDelDia(ComidaPlan c) {
    final nombres = <String>[];
    for (final comp in c.ensamble.componentes) {
      if (comp.rol == 'fresco' || comp.rol == 'verdura') {
        final a = biblioteca.alimentoDe(comp);
        if (a != null) nombres.add(a.nombre.toLowerCase());
      }
    }
    if (nombres.isEmpty) return null;
    final pocos = nombres.take(2).toList();
    return 'corta ${pocos.join(' y ')}';
  }
}

class _EstadoCocina {
  const _EstadoCocina({
    required this.cocina,
    required this.titulo,
    required this.detalle,
    required this.minutos,
  });
  final bool cocina;
  final String titulo;
  final String detalle;
  final int minutos;
}

class _TarjetaDecision extends StatelessWidget {
  const _TarjetaDecision({required this.estado});
  final _EstadoCocina estado;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final icono = estado.cocina ? '🍳' : '✅';
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icono, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(estado.titulo,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(estado.detalle,
                        style: t.bodyMedium?.copyWith(color: muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('~${estado.minutos} min',
                  style: t.labelLarge?.copyWith(
                      color: AppColors.accent, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Preparar para la familia',
                  style: t.bodySmall?.copyWith(color: muted)),
              const SizedBox(width: 6),
              const Text('👨‍👩‍👦', style: TextStyle(fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaComida extends StatelessWidget {
  const _TarjetaComida({
    required this.comida,
    required this.biblioteca,
    required this.yo,
  });
  final ComidaPlan comida;
  final Biblioteca biblioteca;
  final String yo;

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
    final e = comida.ensamble;
    final miPorcion = comida.porcionDe(yo);

    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_titulos[comida.momento] ?? comida.momento,
              style: t.labelSmall?.copyWith(color: muted, letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (e.emoji != null) ...[
                Text(e.emoji!, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.nombre, style: t.titleMedium),
                    if (e.descripcion != null) ...[
                      const SizedBox(height: 2),
                      Text(e.descripcion!,
                          style: t.bodySmall?.copyWith(color: muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (miPorcion != null)
            _DetallePersonas(comida: comida, biblioteca: biblioteca, yo: yo),
        ],
      ),
    );
  }
}

// Muestra la porción de ELLA; el resto de la familia queda detrás de un toque.
class _DetallePersonas extends StatelessWidget {
  const _DetallePersonas({
    required this.comida,
    required this.biblioteca,
    required this.yo,
  });
  final ComidaPlan comida;
  final Biblioteca biblioteca;
  final String yo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final otras = comida.porciones.where((p) => p.persona != yo).toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
        minTileHeight: 40,
        dense: true,
        title: Text('Cantidades y detalle',
            style: t.labelSmall?.copyWith(color: AppColors.accent)),
        children: [
          for (final p in [
            comida.porcionDe(yo)!,
            ...otras,
          ])
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.persona == yo ? 'Para ti' : 'Para ${p.persona}',
                      style:
                          t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(_ingredientes(p),
                      style: t.bodySmall?.copyWith(color: muted)),
                  Text(
                    '${p.macros.kcal.round()} kcal · P ${p.macros.prot.round()} · C ${p.macros.carb.round()} · G ${p.macros.grasa.round()}',
                    style: t.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _ingredientes(PorcionCalculada p) {
    final partes = <String>[];
    for (final comp in comida.ensamble.componentes) {
      final g = p.gramos[comp.id];
      if (g == null || g <= 0) continue;
      final a = biblioteca.alimentoDe(comp);
      if (a == null) continue;
      partes.add('${a.nombre} ${g.round()} ${a.unidad}');
    }
    return partes.join(' · ');
  }
}

// ── MENÚ DE LA SEMANA: como una carta, no un calendario ─────────────────────

class _TabSemana extends StatelessWidget {
  const _TabSemana({required this.plan});
  final PlanSemana plan;

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
              Text(dia.nombre.toUpperCase(),
                  style: t.labelSmall
                      ?.copyWith(color: AppColors.accent, letterSpacing: 1)),
              const SizedBox(height: AppSpacing.sm),
              for (final c in dia.comidas) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.ensamble.emoji ?? '•',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.ensamble.nombre, style: t.bodyLarge),
                          if (c.ensamble.descripcion != null)
                            Text(c.ensamble.descripcion!,
                                style: t.bodySmall?.copyWith(color: muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ]);
  }
}

// ── HOY COCINAS: pasos guiados (estilo instructivo) ─────────────────────────

class _TabCocina extends StatelessWidget {
  const _TabCocina({required this.plan});
  final PlanSemana plan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    // Construye los pasos a partir de las producciones y la conservación.
    final pasos = <String>[];
    for (final p in plan.producciones) {
      pasos.add('Cocinar ${p.base.nombre.toLowerCase()} '
          '(~${p.crudoG >= 1000 ? '${(p.crudoG / 1000).toStringAsFixed(1)} kg' : '${p.crudoG.round()} g'})'
          '${p.base.tiempoMin != null ? ' · ${p.base.tiempoMin} min' : ''}');
      if (p.terminaciones.length > 1) {
        pasos.add('Separar en: ${p.terminaciones.join(' y ')}');
      }
    }
    pasos.add('Guardar en refri lo de los primeros días (Lun–Mié)');
    pasos.add('Congelar el resto, con su fecha');

    return _Pagina(children: [
      const Eyebrow('Domingo'),
      const SizedBox(height: AppSpacing.xs),
      Text('Cocinas una vez, comes toda la semana', style: t.headlineSmall),
      const SizedBox(height: AppSpacing.xs),
      Text(
          '${plan.produccionesBase} preparaciones base. Sigue los pasos y listo.',
          style: t.bodyMedium?.copyWith(color: muted)),
      const SizedBox(height: AppSpacing.lg),
      VitaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < pasos.length; i++) ...[
              _Paso(numero: i + 1, texto: pasos[i]),
              if (i < pasos.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(height: 1),
                ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text('Conservación', style: t.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      for (final cons in plan.conservacion)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            '${cons.estado == 'refri' ? '🧊 Refri' : '❄️ Congelar'} · ${cons.preparacion} · hasta ${_fecha(cons.fechaMaxConsumo)}'
            '${cons.fechaDescongelar != null ? ' · sacar ${_fecha(cons.fechaDescongelar!)}' : ''}',
            style: t.bodySmall?.copyWith(color: muted),
          ),
        ),
    ]);
  }

  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.texto});
  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Text('$numero',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(texto, style: t.bodyLarge),
        )),
      ],
    );
  }
}

// ── COMPRAS: checklist por secciones, se marca al comprar ───────────────────

class _TabCompras extends StatefulWidget {
  const _TabCompras({required this.plan});
  final PlanSemana plan;

  @override
  State<_TabCompras> createState() => _TabComprasState();
}

class _TabComprasState extends State<_TabCompras> {
  final _comprados = <String>{};

  static const _seccion = {
    'proteina': ('🥩', 'Carnes y proteínas'),
    'carbohidrato': ('🍚', 'Despensa'),
    'verdura': ('🥦', 'Verduras'),
    'fresco': ('🥑', 'Frescos'),
    'fruta': ('🍓', 'Frutas'),
    'lacteo': ('🥛', 'Lácteos'),
    'grasa': ('🫒', 'Otros'),
  };

  @override
  Widget build(BuildContext context) {
    return _Pagina(children: [
      _bloque(context, 'Compra principal', widget.plan.compras.principal),
      const SizedBox(height: AppSpacing.md),
      _bloque(context, 'Reposición de frescos', widget.plan.compras.reposicion),
    ]);
  }

  Widget _bloque(BuildContext context, String titulo, List<ItemCompra> items) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    // Agrupa por sección.
    final porCat = <String, List<ItemCompra>>{};
    for (final it in items) {
      (porCat[it.categoria] ??= []).add(it);
    }

    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: t.titleMedium),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text('—', style: t.bodyMedium?.copyWith(color: muted)),
            ),
          for (final entry in _ordenadas(porCat)) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
                '${_seccion[entry.key]?.$1 ?? '•'}  ${_seccion[entry.key]?.$2 ?? entry.key}',
                style: t.labelMedium
                    ?.copyWith(color: AppColors.accent, letterSpacing: 0.3)),
            for (final it in entry.value) _fila(context, it),
          ],
        ],
      ),
    );
  }

  List<MapEntry<String, List<ItemCompra>>> _ordenadas(
      Map<String, List<ItemCompra>> m) {
    final orden = _seccion.keys.toList();
    final entradas = m.entries.toList()
      ..sort((a, b) => orden.indexOf(a.key).compareTo(orden.indexOf(b.key)));
    return entradas;
  }

  Widget _fila(BuildContext context, ItemCompra it) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final marcado = _comprados.contains(it.nombre);
    return InkWell(
      onTap: () => setState(() {
        marcado ? _comprados.remove(it.nombre) : _comprados.add(it.nombre);
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              marcado ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: marcado ? AppColors.accent : muted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                it.nombre,
                style: t.bodyMedium?.copyWith(
                  color: marcado ? muted : null,
                  decoration: marcado ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(_cant(it),
                style: t.bodySmall?.copyWith(
                    color: muted,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
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

// Tarjeta breve del niño en Hoy: qué darle y cómo servirlo.
class _TarjetaNinoHoy extends StatelessWidget {
  const _TarjetaNinoHoy({required this.comida});
  final ComidaNino comida;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👦', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.sm),
              Text('Para Juan Miguel',
                  style: t.labelMedium
                      ?.copyWith(color: AppColors.accent, letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('${comida.emoji} ${comida.nombre}', style: t.titleMedium),
          const SizedBox(height: 2),
          Text(comida.presentacion.first,
              style: t.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}

// ── FAMILIA (Cocina Familiar): la casa come de la misma olla ────────────────

class _TabFamilia extends StatelessWidget {
  const _TabFamilia({
    required this.plan,
    required this.perfiles,
    required this.nino,
    required this.miNombre,
  });
  final PlanSemana plan;
  final List<PerfilNutricional> perfiles;
  final List<ComidaNino> nino;
  final String miNombre;

  static const _objetivos = {
    'deficit': 'Bajar de peso',
    'mantencion': 'Mantención',
    'ganancia': 'Ganar peso',
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return _Pagina(children: [
      Text('Cocinas una vez para toda la casa', style: t.headlineSmall),
      const SizedBox(height: AppSpacing.xs),
      Text('La misma olla, la porción de cada quien.',
          style: t.bodyMedium?.copyWith(color: muted)),
      const SizedBox(height: AppSpacing.lg),

      // Los tres comensales, con su regla.
      VitaCard(
        child: Column(
          children: [
            for (final p in perfiles)
              _filaComensal(
                context,
                emoji: p.nombre == miNombre ? '👩' : '👨',
                nombre: p.nombre == miNombre ? 'Tú' : p.nombre,
                regla: _objetivos[p.objetivo] ?? p.objetivo,
              ),
            _filaComensal(
              context,
              emoji: '👦',
              nombre: perfilJuanMiguel.nombre,
              regla:
                  '${perfilJuanMiguel.edad} años · que coma y crezca contento',
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),

      // Alimentación infantil: su semana, con presentación (no gramos).
      Row(
        children: [
          const Text('👦', style: TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.sm),
          Text('Para Juan Miguel', style: t.titleMedium),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(perfilJuanMiguel.nota, style: t.bodySmall?.copyWith(color: muted)),
      const SizedBox(height: AppSpacing.md),
      for (var i = 0; i < plan.dias.length && i < nino.length; i++) ...[
        _TarjetaNinoDia(dia: plan.dias[i].nombre, comida: nino[i]),
        const SizedBox(height: AppSpacing.sm),
      ],
    ]);
  }

  Widget _filaComensal(BuildContext context,
      {required String emoji, required String nombre, required String regla}) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Text(nombre,
              style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Flexible(
            child: Text(regla,
                textAlign: TextAlign.right,
                style: t.bodySmall?.copyWith(color: muted)),
          ),
        ],
      ),
    );
  }
}

class _TarjetaNinoDia extends StatelessWidget {
  const _TarjetaNinoDia({required this.dia, required this.comida});
  final String dia;
  final ComidaNino comida;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(dia.toUpperCase(),
                  style: t.labelSmall
                      ?.copyWith(color: AppColors.accent, letterSpacing: 1)),
              const Spacer(),
              if (comida.usaProduccion)
                Text('aprovecha lo cocinado',
                    style: t.labelSmall?.copyWith(color: muted)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('${comida.emoji} ${comida.nombre}', style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final paso in comida.presentacion)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('· ', style: t.bodyMedium?.copyWith(color: muted)),
                  Expanded(
                      child: Text(paso,
                          style: t.bodyMedium?.copyWith(color: muted))),
                ],
              ),
            ),
        ],
      ),
    );
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
