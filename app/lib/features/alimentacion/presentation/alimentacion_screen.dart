import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/errores.dart';
import '../../../core/widgets/vita_card.dart';
import '../domain/cocina_familiar.dart';
import '../domain/motor.dart';
import 'alimentacion_controller.dart';

/// Tokens del módulo, derivados del sistema de diseño compartido (identidad
/// clara de VITA). Un solo lugar que ajustar si migra el tema global.
class _Tok {
  const _Tok();
  final Color bg = AppColors.lightBg;
  final Color bg2 = AppColors.lightPanel;
  final Color panel = AppColors.lightPanel;
  final Color surface = AppColors.lightSurface;
  final Color ink = AppColors.lightInk;
  final Color ink2 = const Color(0xFF5F574A);
  final Color muted = AppColors.lightMuted;
  final Color hair = AppColors.lightHairline;
  final Color hairSoft = const Color(0xFFF0E8D6);
  final Color accent = AppColors.accent;
  final Color accentDeep = AppColors.accentDeep;
  final Color accentSoft = AppColors.accentSoft;
  final Color accentWash = const Color(0xFFEEF3ED);
  final Color success = AppColors.success;
  final Color warning = AppColors.warning;
  final Color info = AppColors.info;
  final Color amber = AppColors.warning;
}

const _t = _Tok();

class AlimentacionScreen extends ConsumerWidget {
  const AlimentacionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planSemanaProvider);
    final perfiles = ref.watch(perfilesNutricionalesProvider);
    final nombre = perfiles.maybeWhen(
      data: (p) => p.isNotEmpty ? p.first.nombre : 'Yurby',
      orElse: () => 'Yurby',
    );

    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          scrolledUnderElevation: 0,
          titleSpacing: 24,
          title: const Text('Comida'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: cs.onSurface,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: _t.accent,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: _t.hair,
            tabs: const [
              Tab(text: 'Hoy'),
              Tab(text: 'Menú'),
              Tab(text: 'Cocina de la semana'),
              Tab(text: 'Compras'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: plan.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
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
              final personas = perfiles.asData?.value.length ?? 2;
              return TabBarView(
                children: [
                  _Hoy(
                      plan: p,
                      biblioteca: biblioteca,
                      nombre: nombre,
                      personas: personas + 1),
                  _Menu(plan: p, biblioteca: biblioteca),
                  _Cocina(plan: p, nino: nino),
                  _Compras(plan: p),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Envoltura scrollable centrada.
class _Page extends StatelessWidget {
  const _Page({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 64),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Primitivos ──────────────────────────────────────────────────────────────

Widget _kicker(String s, {Color? color}) => Text(s.toUpperCase(),
    style: TextStyle(
        color: color ?? _t.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5));

Widget _pill(String text, IconData? icon, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: fg.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5)
        ],
        Text(text,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );

Widget _tip(String rich) {
  // "**bold** normal" → primer par de ** marca lo destacado.
  final parts = rich.split('**');
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(Icons.auto_awesome, size: 15, color: _t.accent)),
    const SizedBox(width: 10),
    Expanded(
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: _t.ink2, fontSize: 14, height: 1.45),
          children: [
            for (var i = 0; i < parts.length; i++)
              TextSpan(
                  text: parts[i],
                  style: i.isOdd
                      ? TextStyle(color: _t.ink, fontWeight: FontWeight.w600)
                      : null),
          ],
        ),
      ),
    ),
  ]);
}

// ── HOY: ¿qué hago ahora? ────────────────────────────────────────────────────

class _Hoy extends StatelessWidget {
  const _Hoy(
      {required this.plan,
      required this.biblioteca,
      required this.nombre,
      required this.personas});
  final PlanSemana plan;
  final Biblioteca biblioteca;
  final String nombre;
  final int personas;

  ComidaPlan? _por(DiaPlan d, String m) {
    for (final c in d.comidas) {
      if (c.momento == m) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hoy = plan.diaDe(DateTime.now()) ?? plan.dias.first;
    final hora = DateTime.now().hour;
    final desayuno = _por(hoy, 'desayuno');
    final almuerzo = _por(hoy, 'almuerzo') ?? _por(hoy, 'finde');
    final merienda = _por(hoy, 'merienda');

    // "Ahora" según la hora — VITA decide la acción, no la usuaria.
    final String ahora;
    if (hora < 10 && desayuno != null) {
      ahora = 'Prepara tu ${desayuno.ensamble.nombre.toLowerCase()}';
    } else if (hora < 15 && almuerzo != null) {
      ahora = 'Lleva tu recipiente';
    } else if (merienda != null && hora < 18) {
      ahora = 'Merienda: ${merienda.ensamble.nombre.toLowerCase()}';
    } else {
      ahora = 'Nada pendiente. Disfruta.';
    }

    // Tip de conservación (anticipación real, desde el plan).
    final cong = plan.conservacion
        .where((c) => c.estado == 'congelado' && c.fechaDescongelar != null)
        .toList();
    final tip = cong.isNotEmpty
        ? '**Deja ${cong.first.preparacion.toLowerCase()} para mañana.** Se descongela mejor y conserva la textura.'
        : '**Esta semana cocinas una sola vez.** Todo lo demás ya está listo.';

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (desayuno != null) ...[
          Row(children: [
            Icon(Icons.check, size: 15, color: _t.success),
            const SizedBox(width: 8),
            Text('Desayuno · ${desayuno.ensamble.nombre}',
                style: TextStyle(color: _t.muted, fontSize: 13)),
          ]),
          const SizedBox(height: 26),
        ],
        _kicker('Ahora', color: _t.accent),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(
            child: Text(ahora,
                style: TextStyle(
                    color: _t.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.4)),
          ),
          const SizedBox(width: 16),
          _FilledBtn('Hecho', primary: true, onTap: () {}),
        ]),
        const SizedBox(height: 26),
        if (almuerzo != null) ...[
          _kicker('Luego'),
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(
                width: 52,
                child: Text('13:00',
                    style: TextStyle(
                        color: _t.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
            Expanded(
                child: Text(almuerzo.ensamble.nombre,
                    style: TextStyle(
                        color: _t.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600))),
            _pill('Listo', Icons.kitchen, _t.info),
            const SizedBox(width: 12),
            _GhostBtn('Ver', onTap: () => _verDetalle(context, almuerzo)),
          ]),
          const SizedBox(height: 26),
        ],
        if (merienda != null) ...[
          _kicker('Más tarde'),
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(
                width: 52,
                child: Text('15:45',
                    style: TextStyle(
                        color: _t.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
            Expanded(
                child: Text(merienda.ensamble.nombre,
                    style: TextStyle(
                        color: _t.ink2,
                        fontSize: 15,
                        fontWeight: FontWeight.w500))),
          ]),
          const SizedBox(height: 26),
        ],
        _tip(tip),
        const SizedBox(height: 26),
        InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Row(children: [
              Icon(Icons.shopping_cart_outlined, size: 15, color: _t.ink2),
              const SizedBox(width: 10),
              Text('Compra quincenal en 3 días',
                  style: TextStyle(color: _t.ink2, fontSize: 14)),
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: _t.muted),
            ]),
          ),
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kicker('Preparado para tu familia', color: _t.accent),
        const SizedBox(height: 8),
        Text('$personas recipientes listos',
            style: TextStyle(
                color: _t.ink, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(children: [
          for (var i = 0; i < personas; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: _t.accentWash,
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.inventory_2_outlined,
                    size: 15, color: _t.accentDeep),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        _GhostBtn('Ver detalle',
            onTap: () =>
                almuerzo == null ? null : _verDetalle(context, almuerzo)),
        Container(
            height: 1,
            color: _t.hair,
            margin: const EdgeInsets.symmetric(vertical: 26)),
        Row(children: [
          Icon(Icons.check, size: 15, color: _t.success),
          const SizedBox(width: 9),
          Text('Tu objetivo del día está cubierto',
              style: TextStyle(color: _t.muted, fontSize: 13.5)),
        ]),
      ],
    );

    return _Page(
      child: LayoutBuilder(builder: (context, c) {
        final twoCol = c.maxWidth >= 900;
        // Comida va directo a la comida: el saludo del día vive en Mi Vida.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (twoCol)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 60, child: left),
                const SizedBox(width: 56),
                Expanded(flex: 33, child: right),
              ])
            else ...[
              left,
              const SizedBox(height: 34),
              right,
            ],
          ],
        );
      }),
    );
  }

  void _verDetalle(BuildContext context, ComidaPlan comida) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _t.panel,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kicker('Detalle familiar', color: _t.accent),
              const SizedBox(height: 8),
              Text(comida.ensamble.nombre,
                  style: TextStyle(
                      color: _t.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              for (final p in comida.porciones)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.persona,
                            style: TextStyle(
                                color: _t.ink,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(_ingredientes(comida, p),
                            style: TextStyle(color: _t.muted, fontSize: 13)),
                      ]),
                ),
            ]),
      ),
    );
  }

  String _ingredientes(ComidaPlan comida, PorcionCalculada p) {
    final out = <String>[];
    for (final comp in comida.ensamble.componentes) {
      final g = p.gramos[comp.id];
      if (g == null || g <= 0) continue;
      final a = biblioteca.alimentoDe(comp);
      if (a != null) out.add('${a.nombre} ${g.round()} ${a.unidad}');
    }
    return out.join(' · ');
  }
}

// ── MENÚ: ¿qué comeré esta semana? ──────────────────────────────────────────

class _Menu extends StatelessWidget {
  const _Menu({required this.plan, required this.biblioteca});
  final PlanSemana plan;
  final Biblioteca biblioteca;

  ComidaPlan? _por(DiaPlan d, String m) {
    for (final c in d.comidas) {
      if (c.momento == m) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hoy = plan.diaDe(DateTime.now()) ?? plan.dias.first;
    final idx = plan.dias.indexOf(hoy);
    final manana = idx + 1 < plan.dias.length ? plan.dias[idx + 1] : null;
    final finde = plan.dias
        .where((d) => d.comidas.any((c) => c.momento == 'finde'))
        .toList();

    return _Page(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tu semana',
            style: TextStyle(
                color: _t.ink,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5)),
        const SizedBox(height: 18),
        _tip('**Te sobra arroz** — lo usamos el jueves.'),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 800;
          final cards = [
            Expanded(flex: wide ? 3 : 1, child: _diaCard(hoy, esHoy: true)),
            if (manana != null) ...[
              SizedBox(width: wide ? 22 : 0, height: wide ? 0 : 16),
              Expanded(flex: wide ? 2 : 1, child: _diaCard(manana)),
            ],
          ];
          return wide
              ? IntrinsicHeight(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cards))
              : Column(children: [
                  _diaCard(hoy, esHoy: true),
                  if (manana != null) ...[
                    const SizedBox(height: 16),
                    _diaCard(manana)
                  ],
                ]);
        }),
        const SizedBox(height: 26),
        if (finde.isNotEmpty) _weekend(finde),
      ]),
    );
  }

  Widget _diaCard(DiaPlan d, {bool esHoy = false}) {
    final des = _por(d, 'desayuno');
    final alm = _por(d, 'almuerzo') ?? _por(d, 'finde');
    final mer = _por(d, 'merienda');
    Widget line(String k, String v, {Widget? trailing}) => Container(
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: _t.hair))),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k.toUpperCase(),
                style: TextStyle(
                    color: _t.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .7)),
            const SizedBox(height: 2),
            Row(children: [
              Expanded(
                  child:
                      Text(v, style: TextStyle(color: _t.ink, fontSize: 16))),
              if (trailing != null) trailing,
            ]),
          ]),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      decoration: BoxDecoration(
        color: _t.panel,
        borderRadius: BorderRadius.circular(22),
        border: esHoy ? Border.all(color: _t.accentSoft) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${esHoy ? 'Hoy · ' : 'Mañana · '}${d.nombre}'.toUpperCase(),
              style: TextStyle(
                  color: esHoy ? _t.accent : _t.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
          const Spacer(),
          if (esHoy) _pill('Por servir', null, _t.amber),
        ]),
        const SizedBox(height: 14),
        if (des != null) line('Desayuno', des.ensamble.nombre),
        if (alm != null) line('Almuerzo', alm.ensamble.nombre),
        if (mer != null) line('Merienda', mer.ensamble.nombre),
      ]),
    );
  }

  Widget _weekend(List<DiaPlan> finde) {
    Widget dia(DiaPlan d) {
      final alm = _por(d, 'finde') ?? _por(d, 'almuerzo');
      final comps = <String>[];
      if (alm != null) {
        for (final comp in alm.ensamble.componentes) {
          final a = biblioteca.alimentoDe(comp);
          if (a != null && comps.length < 4) comps.add(a.nombre);
        }
      }
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.nombre.toUpperCase(),
                style: TextStyle(
                    color: _t.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5)),
            const SizedBox(height: 5),
            Text(alm?.ensamble.nombre ?? '—',
                style: TextStyle(
                    color: _t.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.3)),
            const SizedBox(height: 12),
            if (alm?.ensamble.descripcion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(alm!.ensamble.descripcion!,
                    style: TextStyle(color: _t.ink2, fontSize: 14)),
              ),
            for (final cName in comps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(Icons.restaurant, size: 15, color: _t.amber),
                  const SizedBox(width: 11),
                  Text(cName, style: TextStyle(color: _t.ink2, fontSize: 14.5)),
                ]),
              ),
          ]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: _t.panel,
        border: Border.all(color: _t.amber.withValues(alpha: .22)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
          child: Row(children: [
            Icon(Icons.wb_sunny_outlined, size: 18, color: _t.amber),
            const SizedBox(width: 10),
            _kicker('Fin de semana familiar', color: _t.amber),
          ]),
        ),
        Container(height: 1, color: _t.hairSoft),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < finde.length && i < 2; i++) ...[
              if (i > 0) Container(width: 1, color: _t.hairSoft),
              dia(finde[i]),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── COCINA: ¿cómo dejo lista la semana? ─────────────────────────────────────

class _Cocina extends StatefulWidget {
  const _Cocina({required this.plan, required this.nino});
  final PlanSemana plan;
  final List<ComidaNino> nino;

  @override
  State<_Cocina> createState() => _CocinaState();
}

class _CocinaState extends State<_Cocina> {
  bool _lista = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final refri = plan.conservacion.where((c) => c.estado == 'refri').length;
    final cong = plan.conservacion.where((c) => c.estado == 'congelado').length;
    final recipientes = plan.dias
        .take(5)
        .expand((d) => d.comidas)
        .expand((c) => c.porciones)
        .length;

    final fases = <_Fase>[
      _Fase(Icons.local_fire_department_outlined, 'Cocinar proteínas', '25 min',
          ['Pollo al horno · 25 min', 'Carne para boloñesa'],
          done: true),
      _Fase(Icons.ramen_dining_outlined, 'Preparar bases', 'arroz · salsa', [
        'Arroz 18 min · en paralelo',
        'Separa la porción del niño antes de la salsa'
      ]),
      _Fase(Icons.grass, 'Cortar verduras', '',
          ['Ensaladas de la semana · lo que dura']),
      _Fase(Icons.inventory_2_outlined, 'Armar recipientes', '$recipientes',
          ['Porcionar y etiquetar · persona y día']),
      _Fase(Icons.ac_unit, 'Guardar', '$refri · $cong',
          ['$refri al refri · $cong al congelador con fecha']),
    ];

    return _Page(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Esto es lo que cocinas esta semana',
                style: TextStyle(
                    color: _t.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5)),
          ),
          const SizedBox(width: 12),
          _lista
              ? _pill('Cocinada', Icons.check, _t.success)
              : _pill('Por cocinar', null, _t.warning),
        ]),
        const SizedBox(height: 8),
        _tip(
            'Una sola sesión y comes toda la semana. Ahorras **2 horas** reutilizando el pollo.'),
        const SizedBox(height: 22),
        Row(children: [
          _tile('1 h 25', 'activo'),
          const SizedBox(width: 32),
          _tile('$recipientes', 'recipientes'),
          const SizedBox(width: 32),
          _tile('$refri · $cong', 'refri · congelador'),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _lista ? 1.0 : 1 / fases.length,
                minHeight: 7,
                backgroundColor: _t.muted.withValues(alpha: .18),
                valueColor: AlwaysStoppedAnimation(_t.accent),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(_lista ? 'Cocinada' : '1 de ${fases.length}',
              style: TextStyle(
                  color: _t.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        for (final f in fases) _PhaseTile(fase: f),
        const SizedBox(height: 24),
        if (!_lista)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => setState(() => _lista = true),
              child: const Text('Marcar semana como cocinada'),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 26),
            decoration: BoxDecoration(
                color: _t.accentWash, borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              Text('Semana lista.',
                  style: TextStyle(
                      color: _t.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('Ahora solo disfruta. Nos vemos el domingo.',
                  style: TextStyle(color: _t.muted, fontSize: 14)),
            ]),
          ),
      ]),
    );
  }

  Widget _tile(String n, String t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n,
              style: TextStyle(
                  color: _t.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4)),
          const SizedBox(height: 1),
          Text(t, style: TextStyle(color: _t.muted, fontSize: 12.5)),
        ],
      );
}

class _Fase {
  _Fase(this.icon, this.name, this.meta, this.subs, {this.done = false});
  final IconData icon;
  final String name;
  final String meta;
  final List<String> subs;
  final bool done;
}

class _PhaseTile extends StatefulWidget {
  const _PhaseTile({required this.fase});
  final _Fase fase;
  @override
  State<_PhaseTile> createState() => _PhaseTileState();
}

class _PhaseTileState extends State<_PhaseTile> {
  bool _open = false;
  @override
  void initState() {
    super.initState();
    _open = widget.fase.done;
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fase;
    return Container(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: _t.hair))),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: f.done ? _t.accent : _t.accentWash,
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(f.icon,
                    size: 18,
                    color: f.done ? const Color(0xFF141219) : _t.accent),
              ),
              const SizedBox(width: 16),
              Text(f.name,
                  style: TextStyle(
                      color: _t.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (f.meta.isNotEmpty)
                Text(f.meta, style: TextStyle(color: _t.muted, fontSize: 13)),
              const SizedBox(width: 12),
              AnimatedRotation(
                turns: _open ? .25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.chevron_right, size: 18, color: _t.muted),
              ),
            ]),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(60, 0, 4, 18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final s in f.subs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(f.done ? Icons.check : Icons.circle,
                            size: f.done ? 15 : 6,
                            color: f.done ? _t.success : _t.muted),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(s,
                                style:
                                    TextStyle(color: _t.ink2, fontSize: 14))),
                      ]),
                ),
            ]),
          ),
          crossFadeState:
              _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ]),
    );
  }
}

// ── COMPRAS: ¿qué compro primero? ───────────────────────────────────────────

class _Compras extends StatefulWidget {
  const _Compras({required this.plan});
  final PlanSemana plan;
  @override
  State<_Compras> createState() => _ComprasState();
}

class _ComprasState extends State<_Compras> {
  // estado por ítem: 0 falta · 1 en carro · 2 comprado
  final _estado = <String, int>{};
  // Día elegido para la compra (lo cambia la usuaria).
  String _diaElegido = 'Mié 29';

  static const _cat = {
    'proteina': (Icons.restaurant, 'Carnes y proteínas'),
    'carbohidrato': (Icons.inventory_2_outlined, 'Despensa'),
    'verdura': (Icons.grass, 'Frutas y verduras'),
    'fresco': (Icons.grass, 'Frutas y verduras'),
    'fruta': (Icons.grass, 'Frutas y verduras'),
    'lacteo': (Icons.water_drop_outlined, 'Lácteos'),
    'grasa': (Icons.local_dining, 'Otros'),
    'despensa': (Icons.inventory_2_outlined, 'Despensa'),
  };

  String _fmt(ItemCompra it) {
    if (it.unidad == 'unidad') return '${it.cantidad.round()} u';
    if (it.unidad == 'ml') {
      return it.cantidad >= 1000
          ? '${(it.cantidad / 1000).toStringAsFixed(1)} L'
          : '${it.cantidad.round()} ml';
    }
    return it.cantidad >= 1000
        ? '${(it.cantidad / 1000).toStringAsFixed(1)} kg'
        : '${it.cantidad.round()} g';
  }

  @override
  Widget build(BuildContext context) {
    // Agrupa por título de categoría legible.
    final grupos = <String, ({IconData icon, List<ItemCompra> items})>{};
    for (final it in [
      ...widget.plan.compras.principal,
      ...widget.plan.compras.reposicion
    ]) {
      final meta = _cat[it.categoria] ?? (Icons.local_dining, 'Otros');
      grupos.putIfAbsent(meta.$2, () => (icon: meta.$1, items: []));
      grupos[meta.$2]!.items.add(it);
    }

    return _Page(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Compras',
            style: TextStyle(
                color: _t.ink,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5)),
        const SizedBox(height: 5),
        Text('Compra quincenal · 3 – 16 de agosto · para tu familia',
            style: TextStyle(color: _t.muted, fontSize: 14.5)),
        const SizedBox(height: 22),
        _band(),
        const SizedBox(height: 22),
        _despensa(),
        const SizedBox(height: 20),
        _route(),
        const SizedBox(height: 16),
        _legend(),
        const SizedBox(height: 20),
        for (final e in grupos.entries)
          _grupo(e.key, e.value.icon, e.value.items),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 26),
          decoration: BoxDecoration(
              color: _t.accentWash, borderRadius: BorderRadius.circular(22)),
          child: Column(children: [
            Text('Al terminar, no pensarás en comida por 15 días.',
                style: TextStyle(
                    color: _t.ink, fontSize: 17, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text('VITA se encarga del resto.',
                style: TextStyle(color: _t.muted, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }

  Widget _band() {
    Widget chip(String s) {
      final sel = _diaElegido == s;
      return Padding(
        padding: const EdgeInsets.only(right: 7),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _diaElegido = s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
                color: sel ? _t.accent : _t.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: sel ? _t.accent : _t.hair)),
            child: Text(s,
                style: TextStyle(
                    color: sel ? Colors.white : _t.ink2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    return Wrap(
        spacing: 40,
        runSpacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kicker('Día elegido'),
            const SizedBox(height: 6),
            Wrap(runSpacing: 7, children: [
              chip('Lun 27'),
              chip('Mar 28'),
              chip('Mié 29'),
              chip('Jue 30'),
              chip('Vie 31'),
            ]),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kicker('Presupuesto'),
            const SizedBox(height: 6),
            Text('\$85.400',
                style: TextStyle(
                    color: _t.ink, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          SizedBox(
            width: 240,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _kicker('En el supermercado'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                        value: .43,
                        minHeight: 7,
                        backgroundColor: _t.muted.withValues(alpha: .18),
                        valueColor: AlwaysStoppedAnimation(_t.accent)),
                  ),
                ),
                const SizedBox(width: 12),
                Text('18/42',
                    style: TextStyle(
                        color: _t.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ]);
  }

  Widget _despensa() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: _t.bg2, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Icon(Icons.inventory_2_outlined, size: 18, color: _t.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(TextSpan(
                style: TextStyle(color: _t.ink2, fontSize: 14),
                children: [
                  const TextSpan(
                      text: 'Ya tienes en casa: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const TextSpan(text: 'arroz, pollo, queso, huevos, leche. '),
                  TextSpan(
                      text: 'VITA lo usa primero.',
                      style: TextStyle(color: _t.muted)),
                ])),
          ),
        ]),
      );

  Widget _route() {
    Widget r(String s, {bool on = false, bool done = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: on ? _t.accent : _t.panel,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? _t.accent : _t.hairSoft)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (done) ...[
              Icon(Icons.check, size: 15, color: _t.success),
              const SizedBox(width: 8)
            ],
            Text(s,
                style: TextStyle(
                    color: on
                        ? const Color(0xFF141219)
                        : (done ? _t.success : _t.muted),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        );
    Widget arw() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.chevron_right, size: 15, color: _t.muted));
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      r('Carnes', done: true),
      arw(),
      r('Verduras', on: true),
      arw(),
      r('Lácteos'),
      arw(),
      r('Despensa'),
    ]);
  }

  Widget _legend() => Row(children: [
        _leg(Border.all(color: _t.muted, width: 1.8), 'Falta'),
        const SizedBox(width: 18),
        _leg(BoxDecoration(color: _t.amber, shape: BoxShape.circle), 'En carro',
            box: true),
        const SizedBox(width: 18),
        _leg(BoxDecoration(color: _t.success, shape: BoxShape.circle),
            'Comprado',
            box: true),
      ]);

  Widget _leg(dynamic deco, String s, {bool box = false}) => Row(children: [
        Container(
            width: 11,
            height: 11,
            decoration: box
                ? deco as BoxDecoration
                : BoxDecoration(
                    border: deco as Border, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(s, style: TextStyle(color: _t.muted, fontSize: 12.5)),
      ]);

  Widget _grupo(String titulo, IconData icon, List<ItemCompra> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: _t.accent),
          const SizedBox(width: 10),
          Text(titulo,
              style: TextStyle(
                  color: _t.ink, fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
          return Wrap(
            children: [
              for (final it in items)
                SizedBox(width: c.maxWidth / cols - 16, child: _item(it)),
            ],
          );
        }),
      ]),
    );
  }

  Widget _item(ItemCompra it) {
    final st = _estado['${it.categoria}/${it.nombre}'] ?? 0;
    final done = st == 2;
    return InkWell(
      onTap: () => setState(
          () => _estado['${it.categoria}/${it.nombre}'] = (st + 1) % 3),
      child: Container(
        decoration:
            BoxDecoration(border: Border(top: BorderSide(color: _t.hairSoft))),
        padding: const EdgeInsets.symmetric(vertical: 9),
        margin: const EdgeInsets.only(right: 16),
        child: Row(children: [
          _stateDot(st),
          const SizedBox(width: 12),
          Expanded(
            child: Text(it.nombre,
                style: TextStyle(
                    color: done ? _t.muted : _t.ink,
                    fontSize: 14,
                    decoration: done ? TextDecoration.lineThrough : null)),
          ),
          Text(_fmt(it),
              style: TextStyle(
                  color: _t.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _stateDot(int st) {
    if (st == 1) {
      return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: _t.amber, shape: BoxShape.circle),
          child: Center(
              child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle))));
    }
    if (st == 2) {
      return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: _t.success, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 12, color: Colors.white));
    }
    return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _t.muted, width: 1.8)));
  }
}

// ── botones (del sistema de diseño compartido) ──────────────────────────────

class _FilledBtn extends StatelessWidget {
  const _FilledBtn(this.label, {this.primary = false, required this.onTap});
  final String label;
  final bool primary;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return primary
        ? FilledButton(onPressed: onTap, child: Text(label))
        : OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn(this.label, {required this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _t.accentDeep,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const Icon(Icons.chevron_right, size: 16),
      ]),
    );
  }
}
