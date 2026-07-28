import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/errores.dart';
import '../../../core/widgets/vita_card.dart';
import '../domain/alimentacion.dart';
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
              final personas = perfiles.asData?.value.length ?? 2;
              return TabBarView(
                children: [
                  _Hoy(
                      plan: p,
                      biblioteca: biblioteca,
                      nombre: nombre,
                      personas: personas + 1),
                  _Menu(plan: p, biblioteca: biblioteca),
                  _Cocina(plan: p),
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

class _Hoy extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final hoy = plan.diaDe(DateTime.now()) ?? plan.dias.first;
    final hora = DateTime.now().hour;
    final desayuno = _por(hoy, 'desayuno');
    final almuerzo = _por(hoy, 'almuerzo') ?? _por(hoy, 'finde');
    final merienda = _por(hoy, 'merienda');

    // Estado real (congruente con Menú y Mi Vida): qué comió y si ya cocinó.
    final estados = ref.watch(estadosComidaProvider).valueOrNull ??
        const <String, EstadoComida>{};
    final cocinada =
        ref.watch(cocinaSesionProvider).valueOrNull?.cocinada ?? false;
    String estadoDe(String momento) =>
        estados[EstadoComida.claveDe(hoy.fecha, momento)]?.estado ?? 'planeado';
    Future<void> marcarComido(ComidaPlan c) async {
      final actual = estadoDe(c.momento);
      await ref.read(alimentacionRepositoryProvider).guardarEstadoComida(
            fecha: hoy.fecha,
            momento: c.momento,
            assemblyId: c.ensamble.id,
            estado: actual == 'comido' ? 'planeado' : 'comido',
            nombre: c.ensamble.nombre,
          );
      ref.invalidate(estadosComidaProvider);
    }

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
          InkWell(
            onTap: () => marcarComido(desayuno),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                _hoyDot(estadoDe('desayuno')),
                const SizedBox(width: 8),
                Text('Desayuno · ${desayuno.ensamble.nombre}',
                    style: TextStyle(
                        color: _t.muted,
                        fontSize: 13,
                        decoration: estadoDe('desayuno') == 'no_comido'
                            ? TextDecoration.lineThrough
                            : null)),
                const SizedBox(width: 8),
                Text(
                    estadoDe('desayuno') == 'comido'
                        ? 'comido'
                        : 'toca si ya comiste',
                    style: TextStyle(
                        color: _t.muted.withValues(alpha: .7), fontSize: 11)),
              ]),
            ),
          ),
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
            cocinada
                ? _pill('Cocinado', Icons.kitchen, _t.info)
                : _pill('Por cocinar', null, _t.warning),
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
          onTap: () => DefaultTabController.of(context).animateTo(3),
          child: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Row(children: [
              Icon(Icons.shopping_cart_outlined, size: 15, color: _t.ink2),
              const SizedBox(width: 10),
              Text('Ver tu lista de compra',
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
        Text(
            cocinada
                ? '$personas recipientes listos'
                : 'Cocina la semana cuando puedas',
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

  Widget _hoyDot(String estado) {
    if (estado == 'comido') {
      return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: _t.success, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 11, color: Colors.white));
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: estado == 'no_comido' ? _t.muted : _t.accent, width: 1.6)),
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
              _kicker('Receta', color: _t.accent),
              const SizedBox(height: 8),
              Text(comida.ensamble.nombre,
                  style: TextStyle(
                      color: _t.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        recetaCompleta(comida.ensamble, biblioteca),
                        const SizedBox(height: 18),
                        _kicker('Tu porción'),
                        const SizedBox(height: 6),
                        for (final p in comida.porciones)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.persona,
                                      style: TextStyle(
                                          color: _t.ink,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  Text(_ingredientes(comida, p),
                                      style: TextStyle(
                                          color: _t.muted,
                                          fontSize: 13,
                                          height: 1.4)),
                                ]),
                          ),
                      ]),
                ),
              ),
            ]),
      ),
    );
  }

  /// Porción por persona en referencia VISUAL (taza, palma, puño), no gramos.
  String _ingredientes(ComidaPlan comida, PorcionCalculada p) {
    final out = <String>[];
    for (final comp in comida.ensamble.componentes) {
      final g = p.gramos[comp.id];
      if (g == null || g <= 0) continue;
      final a = biblioteca.alimentoDe(comp);
      if (a == null) continue;
      final visual = porcionVisual(a, g);
      out.add(visual.isEmpty ? a.nombre : '${a.nombre}: $visual');
    }
    return out.join('   ·   ');
  }
}

// ── MENÚ: ¿qué comeré esta semana? ──────────────────────────────────────────

class _Menu extends ConsumerWidget {
  const _Menu({required this.plan, required this.biblioteca});
  final PlanSemana plan;
  final Biblioteca biblioteca;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoy = plan.diaDe(DateTime.now()) ?? plan.dias.first;
    final estados = ref.watch(estadosComidaProvider).valueOrNull ?? const {};

    return _Page(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Tu semana',
                style: TextStyle(
                    color: _t.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5)),
          ),
          TextButton.icon(
            onPressed: () => mostrarHistorial(context, biblioteca),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Historial'),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Toca una comida para ver cómo prepararla, marcarla o cambiarla.',
            style: TextStyle(color: _t.muted, fontSize: 14)),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 620 ? 2 : 1);
          const gap = 16.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final d in plan.dias)
                SizedBox(
                  width: cols == 1 ? c.maxWidth : w,
                  child: _diaCard(d, estados,
                      esHoy: identical(d, hoy),
                      esFinde: d.comidas.any((x) => x.momento == 'finde')),
                ),
            ],
          );
        }),
      ]),
    );
  }

  Widget _diaCard(DiaPlan d, Map<String, EstadoComida> estados,
      {bool esHoy = false, bool esFinde = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: _t.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: esHoy
                ? _t.accentSoft
                : (esFinde ? _t.amber.withValues(alpha: .35) : _t.hair)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(d.nombre.toUpperCase(),
              style: TextStyle(
                  color: esHoy ? _t.accentDeep : _t.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const Spacer(),
          if (esHoy)
            _pill('Hoy', null, _t.accent)
          else if (esFinde)
            _pill('Especial', null, _t.amber),
        ]),
        const SizedBox(height: 4),
        for (final c in d.comidas)
          _ComidaTile(
            fecha: d.fecha,
            comida: c,
            biblioteca: biblioteca,
            estado: estados[EstadoComida.claveDe(d.fecha, c.momento)],
          ),
      ]),
    );
  }
}

/// Una comida en el menú: desplegable con la preparación, y botones para
/// marcar (comí / no comí) y cambiarla por otra de la biblioteca. Guarda todo.
class _ComidaTile extends ConsumerStatefulWidget {
  const _ComidaTile({
    required this.fecha,
    required this.comida,
    required this.biblioteca,
    this.estado,
  });
  final DateTime fecha;
  final ComidaPlan comida;
  final Biblioteca biblioteca;
  final EstadoComida? estado;

  @override
  ConsumerState<_ComidaTile> createState() => _ComidaTileState();
}

class _ComidaTileState extends ConsumerState<_ComidaTile> {
  bool _open = false;

  static const _label = {
    'desayuno': 'Desayuno',
    'almuerzo': 'Almuerzo',
    'merienda': 'Merienda',
    'finde': 'Almuerzo',
  };

  Ensamble get _ensamble =>
      widget.biblioteca.ensamble(widget.estado?.assemblyId) ??
      widget.comida.ensamble;

  Future<void> _guardar(
      {String? assemblyId, String? estado, String? comidaLibre}) async {
    final repo = ref.read(alimentacionRepositoryProvider);
    await repo.guardarEstadoComida(
      fecha: widget.fecha,
      momento: widget.comida.momento,
      assemblyId: assemblyId ?? widget.estado?.assemblyId ?? _ensamble.id,
      estado: estado ?? widget.estado?.estado ?? 'planeado',
      comidaLibre: comidaLibre,
      nombre: _ensamble.nombre,
    );
    ref.invalidate(estadosComidaProvider);
    ref.invalidate(historialComidasProvider);
  }

  /// "Comí otra cosa": registra en texto libre lo que sí comió. Queda en el
  /// historial para que después se agregue al recetario.
  Future<void> _comiOtraCosa() async {
    final ctrl = TextEditingController(text: widget.estado?.comidaLibre ?? '');
    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Qué comiste?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              hintText: 'Ej: Ensalada con atún y aguacate'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (texto != null && texto.isNotEmpty) {
      await _guardar(estado: 'comido', comidaLibre: texto);
    }
  }

  Future<void> _cambiar() async {
    final opciones = widget.biblioteca.porMomento(widget.comida.momento);
    final elegido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _t.panel,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(shrinkWrap: true, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: _kicker('Cambiar por')),
        for (final e in opciones)
          ListTile(
            title: Text(e.nombre, style: TextStyle(color: _t.ink)),
            subtitle: e.descripcion == null
                ? null
                : Text(e.descripcion!, style: TextStyle(color: _t.muted)),
            onTap: () => Navigator.pop(context, e.id),
          ),
      ]),
    );
    if (elegido != null) {
      await _guardar(assemblyId: elegido, estado: 'planeado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _ensamble;
    final st = widget.estado?.estado ?? 'planeado';
    return Container(
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: _t.hair))),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          (_label[widget.comida.momento] ??
                                  widget.comida.momento)
                              .toUpperCase(),
                          style: TextStyle(
                              color: _t.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6)),
                      const SizedBox(height: 2),
                      Text(e.nombre,
                          style: TextStyle(
                              color: st == 'no_comido' ||
                                      widget.estado?.comidaLibre != null
                                  ? _t.muted
                                  : _t.ink,
                              fontSize: 15,
                              decoration: st == 'no_comido' ||
                                      widget.estado?.comidaLibre != null
                                  ? TextDecoration.lineThrough
                                  : null)),
                      if (widget.estado?.comidaLibre != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('Comiste: ${widget.estado!.comidaLibre}',
                              style: TextStyle(
                                  color: _t.accentDeep,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
              ),
              if (st == 'comido')
                _pill('Comí', Icons.check, _t.success)
              else if (st == 'no_comido')
                _pill('No comí', null, _t.muted),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _open ? .25 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.chevron_right, size: 18, color: _t.muted),
              ),
            ]),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _receta(e),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _btn('Comí', Icons.check, () => _guardar(estado: 'comido')),
                _btn('No comí', Icons.close,
                    () => _guardar(estado: 'no_comido')),
                _btn('Comí otra cosa', Icons.edit_outlined, _comiOtraCosa),
                _btn('Cambiar', Icons.swap_horiz, _cambiar),
              ]),
            ]),
          ),
      ]),
    );
  }

  Widget _btn(String label, IconData icon, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact, foregroundColor: _t.ink),
      );

  Widget _receta(Ensamble e) => recetaCompleta(e, widget.biblioteca);
}

/// La receta completa de un plato: qué es, calificación, tiempo, etiquetas,
/// ingredientes con porción VISUAL (taza, palma, puño — sin balanza) y pasos
/// numerados. Es el recetario que la usuaria pidió: que de verdad explique.
Widget recetaCompleta(Ensamble e, Biblioteca biblioteca) {
  final ingredientes = <String>[];
  for (final comp in e.componentes) {
    final a = biblioteca.alimentoDe(comp);
    if (a == null) continue;
    final gr = a.unidad == 'ml' ? 200.0 : (_gPorRol[comp.rol] ?? 100.0);
    final visual = porcionVisual(a, gr);
    ingredientes.add(visual.isEmpty ? a.nombre : '${a.nombre} · $visual');
  }

  // Pasos reales del recetario; si no hay, arma desde las preparaciones.
  var pasos = e.pasos;
  if (pasos.isEmpty) {
    final autom = <String>[];
    for (final comp in e.componentes) {
      final prep = biblioteca.preparacion(comp.preparationId);
      if (prep != null) {
        autom.add(prep.tiempoMin != null
            ? '${prep.nombre} (${prep.tiempoMin} min)'
            : prep.nombre);
      }
    }
    if (autom.isNotEmpty) pasos = [...autom, 'Sirve y arma el plato.'];
  }

  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (e.queEs != null) ...[
      Text(e.queEs!,
          style: TextStyle(color: _t.ink2, fontSize: 13.5, height: 1.45)),
      const SizedBox(height: 10),
    ],
    Wrap(spacing: 8, runSpacing: 6, children: [
      if (e.calificacion != null)
        _metaChip(Icons.star, _estrellas(e.calificacion!)),
      if (e.tiempoMin != null) _metaChip(Icons.schedule, '${e.tiempoMin} min'),
      for (final tag in e.etiquetas) _tagChip(tag),
    ]),
    if (ingredientes.isNotEmpty) ...[
      const SizedBox(height: 12),
      _kicker('Ingredientes'),
      const SizedBox(height: 6),
      for (final ing in ingredientes)
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.circle, size: 5, color: _t.accent),
            ),
            const SizedBox(width: 9),
            Expanded(
                child: Text(ing,
                    style: TextStyle(
                        color: _t.ink2, fontSize: 13.5, height: 1.35))),
          ]),
        ),
    ],
    if (pasos.isNotEmpty) ...[
      const SizedBox(height: 12),
      _kicker('Preparación'),
      const SizedBox(height: 6),
      for (var i = 0; i < pasos.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: _t.accentWash, shape: BoxShape.circle),
              child: Text('${i + 1}',
                  style: TextStyle(
                      color: _t.accentDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(pasos[i],
                    style: TextStyle(
                        color: _t.ink2, fontSize: 13.5, height: 1.4))),
          ]),
        ),
    ],
  ]);
}

/// Gramos orientativos por rol, para traducir a porción visual en la receta.
const _gPorRol = <String, double>{
  'proteina': 120.0,
  'base': 180.0,
  'verdura': 80.0,
  'fresco': 60.0,
  'fruta': 120.0,
  'lacteo': 30.0,
  'aliño': 10.0,
};

String _estrellas(double n) {
  final llenas = n.round().clamp(0, 5);
  return '${'★' * llenas}${'☆' * (5 - llenas)}  ${n.toStringAsFixed(1)}';
}

Widget _metaChip(IconData icon, String texto) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: _t.bg2, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: _t.accent),
        const SizedBox(width: 5),
        Text(texto,
            style: TextStyle(
                color: _t.ink2, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );

Widget _tagChip(String tag) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: _t.accentWash, borderRadius: BorderRadius.circular(999)),
      child: Text(tag,
          style: TextStyle(
              color: _t.accentDeep, fontSize: 12, fontWeight: FontWeight.w600)),
    );

/// Muestra el historial de comidas (lo que sí comió / no comió / comió otra
/// cosa) de los últimos 30 días. Es lo vivido, no lo planeado.
void mostrarHistorial(BuildContext context, Biblioteca biblioteca) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _t.panel,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => Consumer(builder: (context, ref, _) {
      final async = ref.watch(historialComidasProvider);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        maxChildSize: .92,
        builder: (context, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child:
                    Text(mensajeDeError(e), style: TextStyle(color: _t.muted))),
            data: (lista) => ListView(controller: scroll, children: [
              const SizedBox(height: 4),
              _kicker('Historial · últimos 30 días'),
              const SizedBox(height: 12),
              if (lista.isEmpty)
                Text(
                    'Aún no hay comidas registradas. Marca comí, no comí o "comí otra cosa" y aquí queda el historial.',
                    style:
                        TextStyle(color: _t.muted, fontSize: 14, height: 1.4))
              else
                for (final e in lista) _filaHistorial(e, biblioteca),
            ]),
          ),
        ),
      );
    }),
  );
}

Widget _filaHistorial(EstadoComida e, Biblioteca biblioteca) {
  const label = {
    'desayuno': 'Desayuno',
    'almuerzo': 'Almuerzo',
    'merienda': 'Merienda',
    'finde': 'Especial',
  };
  final nombre =
      e.comidaLibre ?? biblioteca.ensamble(e.assemblyId)?.nombre ?? 'Comida';
  final noComido = e.estado == 'no_comido';
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(noComido ? Icons.close : Icons.check,
          size: 16, color: noComido ? _t.muted : _t.success),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_fechaDia(e.fecha)} · ${label[e.momento] ?? e.momento}',
              style: TextStyle(
                  color: _t.muted, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(noComido ? 'No comí lo planeado' : nombre,
              style: TextStyle(
                  color: noComido ? _t.muted : _t.ink,
                  fontSize: 14.5,
                  decoration: noComido ? TextDecoration.lineThrough : null)),
          if (e.comidaLibre != null)
            Text('comí otra cosa',
                style: TextStyle(
                    color: _t.accentDeep,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600)),
        ]),
      ),
    ]),
  );
}

// ── COCINA: ¿cómo dejo lista la semana? ─────────────────────────────────────

/// COCINA DE LA SEMANA — una guía real de meal prep, no una decoración.
/// Los pasos salen del plan de verdad: las producciones base que calculó el
/// motor (qué cocer y cuánto), cómo porcionar y cómo conservar (con fechas).
/// Al final se marca cuándo se cocinó, y eso queda guardado.
class _Cocina extends ConsumerWidget {
  const _Cocina({required this.plan});
  final PlanSemana plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(cocinaSesionProvider).valueOrNull;
    final cocinada = sesion?.cocinada ?? false;

    // Métricas reales del plan.
    final tiempoTotal =
        plan.producciones.fold<int>(0, (s, p) => s + (p.base.tiempoMin ?? 0));
    final recipientes = plan.dias
        .take(5)
        .expand((d) => d.comidas)
        .expand((c) => c.porciones)
        .length;
    final refri = plan.conservacion.where((c) => c.estado == 'refri').toList();
    final cong =
        plan.conservacion.where((c) => c.estado == 'congelado').toList();

    final pasos = _pasosDe(recipientes, refri, cong);

    Future<void> marcar(DateTime cuando) async {
      try {
        await ref
            .read(alimentacionRepositoryProvider)
            .marcarCocinada(plan.inicio, cocinadaAt: cuando);
        ref.invalidate(cocinaSesionProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cocina marcada · ${_fechaDia(cuando)}')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }

    Future<void> elegirFecha() async {
      final hoy = DateTime.now();
      final elegida = await showDatePicker(
        context: context,
        initialDate: sesion?.cocinadaAt ?? hoy,
        firstDate: plan.inicio.subtract(const Duration(days: 2)),
        lastDate: hoy,
        helpText: '¿Qué día cocinaste?',
      );
      if (elegida != null) await marcar(elegida);
    }

    Future<void> deshacer() async {
      try {
        await ref
            .read(alimentacionRepositoryProvider)
            .desmarcarCocinada(plan.inicio);
        ref.invalidate(cocinaSesionProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }

    return _Page(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Cocina de la semana',
                style: TextStyle(
                    color: _t.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5)),
          ),
          const SizedBox(width: 12),
          cocinada
              ? _pill('Cocinada', Icons.check, _t.success)
              : _pill('Por cocinar', null, _t.warning),
        ]),
        const SizedBox(height: 8),
        _tip(
            '**Cocinas una vez y comes toda la semana.** Sigue los pasos en orden; al final marca qué día cocinaste.'),
        const SizedBox(height: 22),
        Row(children: [
          _tile(_duracion(tiempoTotal), 'en la cocina'),
          const SizedBox(width: 32),
          _tile('$recipientes', 'recipientes'),
          const SizedBox(width: 32),
          _tile('${refri.length} · ${cong.length}', 'refri · congelador'),
        ]),
        const SizedBox(height: 24),
        _kicker('Los pasos'),
        const SizedBox(height: 4),
        for (var i = 0; i < pasos.length; i++)
          _PasoTile(numero: i + 1, paso: pasos[i], hecho: cocinada),
        const SizedBox(height: 24),
        if (!cocinada) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => marcar(DateTime.now()),
              child: const Text('Marqué que cociné hoy'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: elegirFecha,
              child: const Text('Cociné otro día'),
            ),
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
                color: _t.accentWash, borderRadius: BorderRadius.circular(22)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cocinaste el ${_fechaDia(sesion!.cocinadaAt!)}.',
                  style: TextStyle(
                      color: _t.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Ya está todo listo. Disfruta la semana.',
                  style: TextStyle(color: _t.muted, fontSize: 14)),
              const SizedBox(height: 8),
              Row(children: [
                TextButton(
                    onPressed: elegirFecha, child: const Text('Cambiar fecha')),
                TextButton(onPressed: deshacer, child: const Text('Deshacer')),
              ]),
            ]),
          ),
      ]),
    );
  }

  /// Construye los pasos reales: primero cada producción base (qué cocer y
  /// cuánto), luego porcionar, luego guardar con sus fechas de conservación.
  List<_Paso> _pasosDe(
      int recipientes, List<Conservacion> refri, List<Conservacion> cong) {
    final pasos = <_Paso>[];

    for (final p in plan.producciones) {
      final lineas = <String>[
        'Cuece ${_g(p.crudoG)} en crudo (rinde ~${_g(p.cocidoG)} cocido).',
        if (p.terminaciones.isNotEmpty)
          'Con esto salen: ${p.terminaciones.join(', ')}.',
        if (p.base.congelable) 'Se puede congelar una parte.',
        if (p.base.notas != null && p.base.notas!.isNotEmpty) p.base.notas!,
      ];
      pasos.add(_Paso(
        icon: Icons.local_fire_department_outlined,
        titulo: p.base.nombre,
        meta: p.base.tiempoMin != null ? '${p.base.tiempoMin} min' : '',
        lineas: lineas,
      ));
    }

    if (recipientes > 0) {
      pasos.add(_Paso(
        icon: Icons.inventory_2_outlined,
        titulo: 'Porciona en recipientes',
        meta: '$recipientes',
        lineas: const [
          'Reparte en los recipientes y etiqueta cada uno con la persona y el día.',
          'Deja aparte lo que come Juan Miguel: sus porciones son distintas.',
        ],
      ));
    }

    final guardar = <String>[
      for (final c in refri)
        '${c.preparacion} → refrigerador. Consúmelo antes del ${_fechaDia(c.fechaMaxConsumo)}.',
      for (final c in cong)
        '${c.preparacion} → congelador.${c.fechaDescongelar != null ? ' Baja al refri el ${_fechaDia(c.fechaDescongelar!)}.' : ''}',
    ];
    if (guardar.isNotEmpty) {
      pasos.add(_Paso(
        icon: Icons.ac_unit,
        titulo: 'Guarda y conserva',
        meta: '${refri.length} · ${cong.length}',
        lineas: guardar,
      ));
    }

    return pasos;
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

/// Un paso concreto de la sesión de cocción.
class _Paso {
  _Paso(
      {required this.icon,
      required this.titulo,
      required this.meta,
      required this.lineas});
  final IconData icon;
  final String titulo;
  final String meta;
  final List<String> lineas;
}

class _PasoTile extends StatefulWidget {
  const _PasoTile(
      {required this.numero, required this.paso, required this.hecho});
  final int numero;
  final _Paso paso;
  final bool hecho;

  @override
  State<_PasoTile> createState() => _PasoTileState();
}

class _PasoTileState extends State<_PasoTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.paso;
    final hecho = widget.hecho;
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: hecho ? _t.success : _t.accentWash,
                    borderRadius: BorderRadius.circular(13)),
                child: hecho
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text('${widget.numero}',
                        style: TextStyle(
                            color: _t.accentDeep,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(p.titulo,
                    style: TextStyle(
                        color: _t.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
              ),
              if (p.meta.isNotEmpty)
                Text(p.meta, style: TextStyle(color: _t.muted, fontSize: 13)),
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
              for (final s in p.lineas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 6, color: _t.muted),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(s,
                                style: TextStyle(
                                    color: _t.ink2,
                                    fontSize: 14,
                                    height: 1.4))),
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

// Formato de gramos (entero) y de fecha corta en español, locales del módulo.
String _g(double gramos) => '${gramos.round()} g';

String _duracion(int minutos) {
  if (minutos <= 0) return '—';
  if (minutos < 60) return '$minutos min';
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return m == 0 ? '$h h' : '$h h $m';
}

const _mesesCorto = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

String _fechaDia(DateTime d) => '${d.day} ${_mesesCorto[d.month - 1]}';

// ── COMPRAS: la lista y los viajes al súper ─────────────────────────────────

class _Compras extends ConsumerStatefulWidget {
  const _Compras({required this.plan});
  final PlanSemana plan;
  @override
  ConsumerState<_Compras> createState() => _ComprasState();
}

class _ComprasState extends ConsumerState<_Compras> {
  // Categoría filtrada en la lista (null = todas).
  String? _filtroCat;

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

  String _fmtItem(CompraItem it) {
    final c = it.cantidad ?? 0;
    if (it.unidad == 'unidad') return '${c.round()} u';
    if (it.unidad == 'ml') {
      return c >= 1000
          ? '${(c / 1000).toStringAsFixed(1)} L'
          : '${c.round()} ml';
    }
    return c >= 1000 ? '${(c / 1000).toStringAsFixed(1)} kg' : '${c.round()} g';
  }

  Future<void> _marcar(CompraItem it) async {
    final nuevo = it.estado == 'comprado' ? 'falta' : 'comprado';
    try {
      await ref
          .read(alimentacionRepositoryProvider)
          .actualizarEstadoItem(it.id, nuevo);
      ref.invalidate(listaComprasProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Page(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Compras',
            style: TextStyle(
                color: _t.ink,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5)),
        const SizedBox(height: 5),
        Text('Marca lo que ya compraste y registra el gasto en Finanzas.',
            style: TextStyle(color: _t.muted, fontSize: 14.5)),
        const SizedBox(height: 20),
        _misCompras(),
        const SizedBox(height: 22),
        _laLista(),
      ]),
    );
  }

  /// La lista de compra persistida: progreso real, lo que falta y el checklist
  /// por categoría. Tildar un ítem lo resta de lo que falta y queda guardado.
  Widget _laLista() {
    final listaAsync = ref.watch(listaComprasProvider);
    return listaAsync.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => VitaCard(
        child: ErrorEnTarjeta(
          mensaje: mensajeDeError(e),
          onReintentar: () => ref.invalidate(listaComprasProvider),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Text('Tu plan no necesita compras esta semana.',
              style: TextStyle(color: _t.muted, fontSize: 14));
        }
        final total = items.length;
        final comprados = items.where((it) => it.estado == 'comprado').length;
        final faltan = total - comprados;

        // Agrupa por categoría legible.
        final grupos = <String, ({IconData icon, List<CompraItem> items})>{};
        for (final it in items) {
          final meta = _cat[it.categoria] ?? (Icons.local_dining, 'Otros');
          grupos.putIfAbsent(meta.$2, () => (icon: meta.$1, items: []));
          grupos[meta.$2]!.items.add(it);
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _kicker('Tu lista · quincena'),
            const Spacer(),
            faltan == 0
                ? _pill('Todo comprado', Icons.check, _t.success)
                : _pill('Faltan $faltan', null, _t.warning),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                    value: total == 0 ? 0 : comprados / total,
                    minHeight: 7,
                    backgroundColor: _t.muted.withValues(alpha: .18),
                    valueColor: AlwaysStoppedAnimation(_t.accent)),
              ),
            ),
            const SizedBox(width: 12),
            Text('$comprados/$total',
                style: TextStyle(
                    color: _t.ink, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 18),
          _filtros(grupos.keys.toList()),
          const SizedBox(height: 8),
          for (final e in grupos.entries)
            if (_filtroCat == null || _filtroCat == e.key)
              _grupo(e.key, e.value.icon, e.value.items),
        ]);
      },
    );
  }

  String _plata(double? n) =>
      '\$${(n ?? 0).round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';

  Widget _misCompras() {
    final compras = ref.watch(comprasProvider);
    return VitaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _kicker('Tus compras'),
          const Spacer(),
          TextButton.icon(
            onPressed: _agregarCompra,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar compra'),
          ),
        ]),
        compras.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text(mensajeDeError(e),
              style: TextStyle(color: _t.muted, fontSize: 13)),
          data: (list) => list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Text(
                      'Aún no registras compras. Puedes registrar varias (uno o varios supermercados, en distintos días); cada una se guarda en Finanzas como Alimentación.',
                      style: TextStyle(color: _t.muted, fontSize: 13.5)),
                )
              : Column(
                  children: [
                    for (final c in list)
                      Container(
                        decoration: BoxDecoration(
                            border:
                                Border(top: BorderSide(color: _t.hairSoft))),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(children: [
                          Icon(Icons.storefront_outlined,
                              size: 18, color: _t.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      c.supermercado?.isNotEmpty == true
                                          ? c.supermercado!
                                          : 'Compra',
                                      style: TextStyle(
                                          color: _t.ink,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      '${c.fecha.day}/${c.fecha.month}/${c.fecha.year}',
                                      style: TextStyle(
                                          color: _t.muted, fontSize: 12.5)),
                                ]),
                          ),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_plata(c.monto),
                                    style: TextStyle(
                                        color: _t.ink,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700)),
                                if (c.comprada)
                                  Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check,
                                            size: 12, color: _t.success),
                                        const SizedBox(width: 3),
                                        Text('En Finanzas',
                                            style: TextStyle(
                                                color: _t.success,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600)),
                                      ]),
                              ]),
                        ]),
                      ),
                  ],
                ),
        ),
      ]),
    );
  }

  Future<void> _agregarCompra() async {
    final superCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    var fecha = DateTime.now();
    final repo = ref.read(alimentacionRepositoryProvider);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Registrar compra'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: superCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Supermercado')),
            const SizedBox(height: 12),
            TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Monto', prefixText: '\$ ')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child:
                      Text('Día: ${fecha.day}/${fecha.month}/${fecha.year}')),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: fecha,
                    firstDate: DateTime(fecha.year - 1),
                    lastDate: DateTime(fecha.year + 1),
                  );
                  if (d != null) setD(() => fecha = d);
                },
                child: const Text('Cambiar'),
              ),
            ]),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final monto = double.tryParse(
                    montoCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
                if (monto == null || monto <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Ingresa el monto de la compra.')));
                  return;
                }
                try {
                  final c = await repo.crearCompra(
                    tipo: 'reposicion',
                    supermercado: superCtrl.text.trim().isEmpty
                        ? null
                        : superCtrl.text.trim(),
                    fecha: fecha,
                    monto: monto,
                  );
                  await repo.registrarEnFinanzas(c);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ref.invalidate(comprasProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Compra registrada en Finanzas')));
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(mensajeDeError(e))));
                  }
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtros(List<String> cats) {
    Widget chip(String label, String? cat) {
      final sel = _filtroCat == cat;
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _filtroCat = cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: sel ? _t.accent : _t.panel,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: sel ? _t.accent : _t.hairSoft)),
            child: Text(label,
                style: TextStyle(
                    color: sel ? Colors.white : _t.ink2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    return Wrap(children: [
      chip('Todo', null),
      for (final c in cats) chip(c, c),
    ]);
  }

  Widget _grupo(String titulo, IconData icon, List<CompraItem> items) {
    // Pendientes arriba, comprados abajo (sin reordenar entre sí).
    final ordenados = [
      ...items.where((it) => it.estado != 'comprado'),
      ...items.where((it) => it.estado == 'comprado'),
    ];
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
              for (final it in ordenados)
                SizedBox(width: c.maxWidth / cols - 16, child: _itemRow(it)),
            ],
          );
        }),
      ]),
    );
  }

  Widget _itemRow(CompraItem it) {
    final done = it.estado == 'comprado';
    return InkWell(
      onTap: () => _marcar(it),
      child: Container(
        decoration:
            BoxDecoration(border: Border(top: BorderSide(color: _t.hairSoft))),
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.only(right: 16),
        child: Row(children: [
          _checkDot(done),
          const SizedBox(width: 12),
          Expanded(
            child: Text(it.nombre,
                style: TextStyle(
                    color: done ? _t.muted : _t.ink,
                    fontSize: 14,
                    decoration: done ? TextDecoration.lineThrough : null)),
          ),
          Text(_fmtItem(it),
              style: TextStyle(
                  color: _t.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _checkDot(bool done) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
            color: done ? _t.success : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
                color: done ? _t.success : _t.muted, width: done ? 0 : 1.8)),
        child: done
            ? const Icon(Icons.check, size: 13, color: Colors.white)
            : null,
      );
}

// ── botones (del sistema de diseño compartido) ──────────────────────────────

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
