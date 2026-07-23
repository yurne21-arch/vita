import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/moneda.dart';
import '../../../core/widgets/errores.dart';
import '../../../core/widgets/eyebrow.dart';
import '../../../core/widgets/vita_card.dart';
import '../domain/mi_mes.dart';
import 'mi_mes_controller.dart';

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre' //
];

String _tituloMes(DateTime m) => '${_meses[m.month - 1]} ${m.year}';

class MiMesScreen extends ConsumerWidget {
  const MiMesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final balance = ref.watch(balanceMesProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Mi Mes'),
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final ancho = c.maxWidth;
            final pad = ancho >= 1000 ? 32.0 : (ancho >= 700 ? 24.0 : 16.0);
            final dosColumnas = ancho >= 900;
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(balanceMesProvider);
                ref.invalidate(reflexionMesProvider);
                await ref.read(balanceMesProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          pad, AppSpacing.lg, pad, AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SelectorMes(),
                          const SizedBox(height: AppSpacing.lg),
                          balance.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(AppSpacing.xxl),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => VitaCard(
                              child: ErrorEnTarjeta(
                                mensaje: '$e',
                                onReintentar: () =>
                                    ref.invalidate(balanceMesProvider),
                              ),
                            ),
                            data: (b) => _Contenido(
                              balance: b,
                              dosColumnas: dosColumnas,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ───────────────── Selector de mes ─────────────────

class _SelectorMes extends ConsumerWidget {
  const _SelectorMes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mes = ref.watch(mesSeleccionadoProvider);
    final ahora = DateTime.now();
    final esMesActual = mes.year == ahora.year && mes.month == ahora.month;

    void mover(int delta) {
      final nuevo = DateTime(mes.year, mes.month + delta, 1);
      // No dejamos ir al futuro más allá del mes actual.
      if (nuevo.isAfter(DateTime(ahora.year, ahora.month, 1))) return;
      ref.read(mesSeleccionadoProvider.notifier).state = nuevo;
    }

    return Row(
      children: [
        IconButton(
          onPressed: () => mover(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Mes anterior',
        ),
        Expanded(
          child: Column(
            children: [
              Text(_tituloMes(mes),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(esMesActual ? 'En curso' : 'Cerrado',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton(
          onPressed: esMesActual ? null : () => mover(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Mes siguiente',
        ),
      ],
    );
  }
}

// ───────────────── Contenido ─────────────────

class _Contenido extends StatelessWidget {
  const _Contenido({required this.balance, required this.dosColumnas});
  final BalanceMes balance;
  final bool dosColumnas;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (!balance.proyectos.vacio) _CardProyectos(balance.proyectos),
      if (!balance.salud.vacio) _CardSalud(balance.salud),
      if (balance.habitos.isNotEmpty) _CardHabitos(balance.habitos),
      if (!balance.finanzas.vacio) _CardFinanzas(balance.finanzas),
      if (!balance.agenda.vacio) _CardAgenda(balance.agenda),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (balance.vacio)
          const _EspejoVacio()
        else ...[
          const Eyebrow('EL ESPEJO DEL MES'),
          const SizedBox(height: AppSpacing.sm),
          if (dosColumnas)
            _Rejilla(cards: cards)
          else
            for (final w in cards) ...[
              w,
              const SizedBox(height: AppSpacing.md),
            ],
        ],
        const SizedBox(height: AppSpacing.lg),
        const Eyebrow('TU REFLEXIÓN'),
        const SizedBox(height: AppSpacing.sm),
        _ReflexionCard(key: ValueKey(balance.mes)),
      ],
    );
  }
}

/// Rejilla de 2 columnas para pantallas anchas (sin dependencias).
class _Rejilla extends StatelessWidget {
  const _Rejilla({required this.cards});
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const esp = AppSpacing.md;
      final celda = (c.maxWidth - esp) / 2;
      return Wrap(
        spacing: esp,
        runSpacing: esp,
        children: [
          for (final w in cards) SizedBox(width: celda, child: w),
        ],
      );
    });
  }
}

// ───────────────── Tarjetas por área ─────────────────

class _CardArea extends StatelessWidget {
  const _CardArea({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.child,
  });
  final IconData icono;
  final Color color;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(titulo,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _CardProyectos extends StatelessWidget {
  const _CardProyectos(this.r);
  final ResumenProyectosMes r;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return _CardArea(
      icono: Icons.flag_outlined,
      color: AppColors.accent,
      titulo: 'Proyectos y trabajo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LineaDato(
              texto: r.pasosCompletados == 1
                  ? '1 paso completado'
                  : '${r.pasosCompletados} pasos completados'),
          if (r.hitosLogrados > 0)
            _LineaDato(
                texto: r.hitosLogrados == 1
                    ? '1 hito logrado'
                    : '${r.hitosLogrados} hitos logrados'),
          if (r.pendientes > 0)
            _LineaDato(texto: '${r.pendientes} por hacer', tenue: true),
          if (r.avances.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final a in r.avances.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('· $a',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
              ),
            if (r.avances.length > 4)
              Text('y ${r.avances.length - 4} más',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _CardSalud extends StatelessWidget {
  const _CardSalud(this.r);
  final ResumenSaludMes r;

  static String _escala(double v) {
    if (v < 2) return 'baja';
    if (v < 3) return 'regular';
    if (v < 4) return 'buena';
    return 'alta';
  }

  @override
  Widget build(BuildContext context) {
    return _CardArea(
      icono: Icons.favorite_outline,
      color: AppColors.success,
      titulo: 'Salud',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.energiaProm != null)
            _LineaDato(
                texto:
                    'Energía ${_escala(r.energiaProm!)} (${r.energiaProm!.toStringAsFixed(1)})'),
          if (r.animoProm != null)
            _LineaDato(
                texto:
                    'Ánimo ${_escala(r.animoProm!)} (${r.animoProm!.toStringAsFixed(1)})'),
          if (r.suenoHorasProm != null)
            _LineaDato(
                texto:
                    'Dormiste ${r.suenoHorasProm!.toStringAsFixed(1)} h en promedio'),
          if (r.pesoFin != null)
            _LineaDato(
              texto: r.pesoDelta != null && r.pesoDelta!.abs() >= 0.1
                  ? 'Peso ${r.pesoFin!.toStringAsFixed(1)} kg (${r.pesoDelta! > 0 ? '+' : ''}${r.pesoDelta!.toStringAsFixed(1)} este mes)'
                  : 'Peso ${r.pesoFin!.toStringAsFixed(1)} kg',
            ),
          if (r.diasRegistrados > 0)
            _LineaDato(
                texto: '${r.diasRegistrados} días con registro', tenue: true),
        ],
      ),
    );
  }
}

class _CardHabitos extends StatelessWidget {
  const _CardHabitos(this.habitos);
  final List<HabitoMes> habitos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return _CardArea(
      icono: Icons.check_circle_outline,
      color: AppColors.info,
      titulo: 'Hábitos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final h in habitos)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (h.emoji != null) ...[
                    Text(h.emoji!, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(h.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                      h.diasCumplidos == 1
                          ? '1 día'
                          : '${h.diasCumplidos} días',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CardFinanzas extends StatelessWidget {
  const _CardFinanzas(this.r);
  final ResumenFinanzasMes r;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final positivo = r.balance >= 0;
    final mayor = r.mayorGasto;
    return _CardArea(
      icono: Icons.account_balance_wallet_outlined,
      color: AppColors.warning,
      titulo: 'Finanzas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LineaDato(texto: 'Ingresos ${formatoMoneda(r.ingresos)}'),
          _LineaDato(texto: 'Gastos ${formatoMoneda(r.gastos)}'),
          const SizedBox(height: 4),
          Text(
            positivo
                ? 'Te quedó a favor ${formatoMoneda(r.balance)}'
                : 'Gastaste ${formatoMoneda(r.balance.abs())} de más',
            style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: positivo ? AppColors.success : AppColors.danger),
          ),
          if (mayor != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Donde más gastaste: ${mayor.key}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
          if (r.cerrado)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 15, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text('Mes cerrado',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CardAgenda extends StatelessWidget {
  const _CardAgenda(this.r);
  final ResumenAgendaMes r;

  @override
  Widget build(BuildContext context) {
    return _CardArea(
      icono: Icons.calendar_today_outlined,
      color: AppColors.accentSoft,
      titulo: 'Agenda',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LineaDato(
              texto: r.realizados == 1
                  ? '1 evento realizado'
                  : '${r.realizados} eventos realizados'),
          _LineaDato(
              texto:
                  r.total == 1 ? '1 en la agenda' : '${r.total} en la agenda',
              tenue: true),
        ],
      ),
    );
  }
}

class _LineaDato extends StatelessWidget {
  const _LineaDato({required this.texto, this.tenue = false});
  final String texto;
  final bool tenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(texto,
          style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35, color: tenue ? cs.onSurfaceVariant : cs.onSurface)),
    );
  }
}

// ───────────────── Reflexión (editable) ─────────────────

class _ReflexionCard extends ConsumerStatefulWidget {
  const _ReflexionCard({super.key});
  @override
  ConsumerState<_ReflexionCard> createState() => _ReflexionCardState();
}

class _ReflexionCardState extends ConsumerState<_ReflexionCard> {
  final _bien = TextEditingController();
  final _mejorar = TextEditingController();
  final _foco = TextEditingController();
  bool _cargado = false;
  bool _guardando = false;

  @override
  void dispose() {
    _bien.dispose();
    _mejorar.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await ref.read(miMesAccionesProvider).guardarReflexion(
            salioBien: _bien.text,
            aMejorar: _mejorar.text,
            foco: _foco.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflexión guardada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final reflexionAsync = ref.watch(reflexionMesProvider);

    // Precarga los campos una sola vez cuando llegan los datos del mes.
    reflexionAsync.whenData((r) {
      if (!_cargado) {
        _bien.text = r?.salioBien ?? '';
        _mejorar.text = r?.aMejorar ?? '';
        _foco.text = r?.foco ?? '';
        _cargado = true;
      }
    });

    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              'Esto lo escribes tú. La app te muestra los hechos; el balance '
              'lo pones tú.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: AppSpacing.md),
          _CampoReflexion(
            controller: _bien,
            etiqueta: 'Lo que salió bien',
            hint: 'De lo que estás orgullosa este mes',
            icono: Icons.sentiment_satisfied_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          _CampoReflexion(
            controller: _mejorar,
            etiqueta: 'Lo que quiero mejorar',
            hint: 'Sin culpa: solo lo que ajustarías',
            icono: Icons.tune,
          ),
          const SizedBox(height: AppSpacing.md),
          _CampoReflexion(
            controller: _foco,
            etiqueta: 'Mi foco del próximo mes',
            hint: 'Una o dos cosas, no diez',
            icono: Icons.center_focus_strong_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Guardar reflexión'),
          ),
        ],
      ),
    );
  }
}

class _CampoReflexion extends StatelessWidget {
  const _CampoReflexion({
    required this.controller,
    required this.etiqueta,
    required this.hint,
    required this.icono,
  });
  final TextEditingController controller;
  final String etiqueta;
  final String hint;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 16, color: AppColors.accentSoft),
            const SizedBox(width: 6),
            Text(etiqueta,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ───────────────── vacíos / utilitarios ─────────────────

class _EspejoVacio extends StatelessWidget {
  const _EspejoVacio();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return VitaCard(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_outlined,
                color: AppColors.accentSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Este mes está tranquilo',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Aún no hay nada registrado en este mes. A medida que uses VITA, '
            'aquí verás cómo avanzaste.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// El eyebrow ahora vive en core/widgets/eyebrow.dart.
