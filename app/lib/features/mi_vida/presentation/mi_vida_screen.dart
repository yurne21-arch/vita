import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/vita_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../salud/data/estado_repository.dart';
import '../../salud/presentation/estado_controller.dart';
import '../data/habitos_repository.dart';
import 'habitos_controller.dart';

const EdgeInsets _kCardPad = EdgeInsets.fromLTRB(20, 18, 20, 18);
const double _kGap = 12;
const double _kDesktopMax = 1280;

// Puntos de quiebre: escritorio ≥1000, tablet 640–1000, móvil <640.
const double _kBpDesktop = 1000;
const double _kBpTablet = 640;

/// MI VIDA — escritorio editorial responsive. Tres composiciones reales:
/// 12 columnas (desktop), 2 columnas (tablet), 1 columna (móvil).
/// Orden: Saludo → Versículo+Reflexión → Hoy importa → Estado → Agenda →
/// Proyecto → Entrenamiento → Menú → Hábitos → Cierre. Dios arriba.
class MiVidaScreen extends ConsumerWidget {
  const MiVidaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: const Text('VITA'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            if (w >= _kBpDesktop) return const _DesktopLayout();
            if (w >= _kBpTablet) return const _TabletLayout();
            return const _MobileLayout();
          },
        ),
      ),
    );
  }
}

// ============================ LAYOUTS ============================

/// Escritorio: grid editorial de 12 columnas, centrado y limitado para no
/// estirarse al infinito, pero aprovechando el ancho.
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kDesktopMax),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
          children: [
            const _BuenosDias(),
            const SizedBox(height: AppSpacing.xl),
            // Dios arriba: Versículo amplio (8) + Reflexión (4), igualados.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Expanded(flex: 8, child: _Versiculo()),
                  SizedBox(width: _kGap),
                  Expanded(flex: 4, child: _Reflexion()),
                ],
              ),
            ),
            const SizedBox(height: _kGap),
            const _Prioridades(), // protagonista, ancho completo
            const SizedBox(height: _kGap),
            const _EstadoGeneral(), // compacta, ancho completo
            const SizedBox(height: _kGap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Expanded(child: _Agenda()),
                  SizedBox(width: _kGap),
                  Expanded(child: _ProyectoPrincipal()),
                ],
              ),
            ),
            const SizedBox(height: _kGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(flex: 3, child: _Entrenamiento()),
                SizedBox(width: _kGap),
                Expanded(flex: 3, child: _Menu()),
                SizedBox(width: _kGap),
                Expanded(flex: 4, child: _Habitos()),
              ],
            ),
            const SizedBox(height: _kGap),
            const _CierreDelDia(), // franja final discreta
          ],
        ),
      ),
    );
  }
}

/// Tablet: dos columnas. Mantiene el orden; pares donde tiene sentido.
class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const _BuenosDias(),
        const SizedBox(height: AppSpacing.lg),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(child: _Versiculo()),
              SizedBox(width: _kGap),
              Expanded(child: _Reflexion()),
            ],
          ),
        ),
        const SizedBox(height: _kGap),
        const _Prioridades(),
        const SizedBox(height: _kGap),
        const _EstadoGeneral(),
        const SizedBox(height: _kGap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(child: _Agenda()),
              SizedBox(width: _kGap),
              Expanded(child: _ProyectoPrincipal()),
            ],
          ),
        ),
        const SizedBox(height: _kGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(child: _Entrenamiento()),
            SizedBox(width: _kGap),
            Expanded(child: _Menu()),
          ],
        ),
        const SizedBox(height: _kGap),
        const _Habitos(),
        const SizedBox(height: _kGap),
        const _CierreDelDia(),
      ],
    );
  }
}

/// Móvil: una sola columna, orden exacto.
class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
      children: const [
        _BuenosDias(),
        SizedBox(height: AppSpacing.md),
        _Versiculo(),
        SizedBox(height: _kGap),
        _Reflexion(),
        SizedBox(height: _kGap),
        _Prioridades(),
        SizedBox(height: _kGap),
        _EstadoGeneral(),
        SizedBox(height: _kGap),
        _Agenda(),
        SizedBox(height: _kGap),
        _ProyectoPrincipal(),
        SizedBox(height: _kGap),
        _Entrenamiento(),
        SizedBox(height: _kGap),
        _Menu(),
        SizedBox(height: _kGap),
        _Habitos(),
        SizedBox(height: _kGap),
        _CierreDelDia(),
      ],
    );
  }
}

// ============================ TARJETAS ============================

class _BuenosDias extends ConsumerWidget {
  const _BuenosDias();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(profileControllerProvider).maybeWhen(
          data: (p) => p?.displayName ?? 'Yurby',
          orElse: () => 'Yurby',
        );
    final now = DateTime.now();
    final saludo = now.hour < 12
        ? 'Buenos días'
        : now.hour < 20
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$saludo, $name.',
          style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -0.3),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_fechaLarga(now)} · Tu día ya está preparado.',
          style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class _Versiculo extends StatelessWidget {
  const _Versiculo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Eyebrow('VERSÍCULO DEL DÍA'),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"Todo lo puedo en Cristo que me fortalece."',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Filipenses 4:13',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Reflexion extends StatelessWidget {
  const _Reflexion();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Eyebrow('REFLEXIÓN'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Un paso con calma. Hoy basta con lo que sí puedes.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '¿Cuál es el único paso que importa hoy?',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Prioridades extends StatelessWidget {
  const _Prioridades();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: _kCardPad,
      decoration: BoxDecoration(
        color: const Color(0x146B7A4F),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0x336B7A4F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('HOY IMPORTA'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tus tres prioridades del día.',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'VITA elegirá lo esencial y te dirá por qué.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          _PrioridadFantasma(),
          _PrioridadFantasma(),
          _PrioridadFantasma(),
        ],
      ),
    );
  }
}

class _EstadoGeneral extends ConsumerWidget {
  const _EstadoGeneral();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoControllerProvider).valueOrNull;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _abrirRegistroEstado(context, ref, estado),
      child: VitaCard(
        padding: _kCardPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _Eyebrow('CÓMO ESTÁS HOY'),
                Icon(Icons.add, size: 18, color: AppColors.olive),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _Metric(label: 'Peso', value: _fmtPeso(estado?.peso)),
                _Metric(label: 'Energía', value: _fmt15(estado?.energia)),
                _Metric(label: 'Sueño', value: _fmtSueno(estado?.sueno)),
                _Metric(label: 'Ánimo', value: _fmt15(estado?.animo)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _numEs(double v) {
  final s = (v == v.roundToDouble())
      ? v.toInt().toString()
      : v.toStringAsFixed(1);
  return s.replaceAll('.', ',');
}

String _fmtPeso(double? v) => v == null ? '—' : '${_numEs(v)} kg';
String _fmtSueno(double? v) => v == null ? '—' : '${_numEs(v)} h';
String _fmt15(int? v) => v == null ? '—' : '$v/5';

Future<void> _abrirRegistroEstado(
    BuildContext context, WidgetRef ref, EstadoHoy? actual) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RegistrarEstadoSheet(actual: actual),
  );
}

class _Agenda extends StatelessWidget {
  const _Agenda();

  @override
  Widget build(BuildContext context) {
    return const VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('TU DÍA'),
          SizedBox(height: AppSpacing.sm),
          _EmptyHint(
            icon: Icons.event_available_outlined,
            title: 'Sin eventos para hoy.',
            subtitle: 'Cuando agendes algo, tu día aparecerá aquí, en orden.',
          ),
        ],
      ),
    );
  }
}

class _ProyectoPrincipal extends StatelessWidget {
  const _ProyectoPrincipal();

  @override
  Widget build(BuildContext context) {
    return const VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('PROYECTO DEL MES'),
          SizedBox(height: AppSpacing.sm),
          _EmptyHint(
            icon: Icons.flag_outlined,
            title: 'Aún no eliges tu proyecto del mes.',
            subtitle: 'Cuando lo hagas, verás aquí solo el siguiente paso.',
            action: 'Elegir proyecto',
          ),
        ],
      ),
    );
  }
}

class _Entrenamiento extends StatelessWidget {
  const _Entrenamiento();

  @override
  Widget build(BuildContext context) {
    return const VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('MOVIMIENTO DE HOY'),
          SizedBox(height: AppSpacing.sm),
          _EmptyHint(
            icon: Icons.fitness_center_outlined,
            title: 'Aún no tienes un programa.',
            subtitle: 'Tu entrenamiento aparecerá aquí cuando empieces.',
            action: 'Crear programa',
          ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu();

  @override
  Widget build(BuildContext context) {
    return const VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('TU MENÚ'),
          SizedBox(height: AppSpacing.sm),
          _EmptyHint(
            icon: Icons.restaurant_outlined,
            title: 'Aún no tienes menú.',
            subtitle: 'Cuando lo generes, verás aquí qué comer hoy.',
            action: 'Generar menú',
          ),
        ],
      ),
    );
  }
}

/// Tarjeta secundaria — Hábitos (real, reutiliza el controlador existente).
class _Habitos extends ConsumerWidget {
  const _Habitos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habitosAsync = ref.watch(habitosControllerProvider);

    return VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('HÁBITOS'),
          const SizedBox(height: AppSpacing.sm),
          habitosAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('No se pudieron cargar tus hábitos.',
                style: theme.textTheme.bodyMedium),
            data: (habitos) {
              if (habitos.isEmpty) {
                return const _EmptyHint(
                  icon: Icons.check_circle_outline,
                  title: 'Aún no tienes hábitos.',
                  subtitle: 'Empieza con pocos; menos es más.',
                );
              }
              final hechos = habitos.where((h) => h.hecho).length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('$hechos de ${habitos.length} hoy',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  for (final h in habitos)
                    _HabitoRow(
                      habito: h,
                      onTap: () => ref
                          .read(habitosControllerProvider.notifier)
                          .alternar(h),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CierreDelDia extends StatelessWidget {
  const _CierreDelDia();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('CIERRE DEL DÍA'),
          const SizedBox(height: AppSpacing.sm),
          Text('¿Cómo estuvo tu día?',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
            child: Text('Lo mejor de hoy fue…',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Disponible esta noche. Sin prisa, sin culpa.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ============================ PIEZAS ============================

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.olive,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vacio = value == '—';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: vacio ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}


class _PrioridadFantasma extends StatelessWidget {
  const _PrioridadFantasma();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.radio_button_unchecked,
              size: 16, color: theme.colorScheme.outlineVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
        if (action != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(action!,
              style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.olive, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}

class _HabitoRow extends StatelessWidget {
  const _HabitoRow({required this.habito, required this.onTap});
  final Habito habito;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = habito.hecho;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Text(habito.emoji ?? '•', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                habito.nombre,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              color:
                  done ? AppColors.olive : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================ util ============================

String _fechaLarga(DateTime d) {
  const dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
  ];
  const meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
  final dia = dias[d.weekday - 1];
  final mes = meses[d.month - 1];
  final capit = dia[0].toUpperCase() + dia.substring(1);
  return '$capit ${d.day} de $mes';
}


// ============================ REGISTRO ESTADO ============================

class _RegistrarEstadoSheet extends ConsumerStatefulWidget {
  const _RegistrarEstadoSheet({this.actual});
  final EstadoHoy? actual;

  @override
  ConsumerState<_RegistrarEstadoSheet> createState() =>
      _RegistrarEstadoSheetState();
}

class _RegistrarEstadoSheetState
    extends ConsumerState<_RegistrarEstadoSheet> {
  late final TextEditingController _peso;
  late final TextEditingController _sueno;
  int? _energia;
  int? _animo;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.actual;
    _peso = TextEditingController(
        text: a?.peso != null ? _numEs(a!.peso!) : '');
    _sueno = TextEditingController(
        text: a?.sueno != null ? _numEs(a!.sueno!) : '');
    _energia = a?.energia;
    _animo = a?.animo;
  }

  @override
  void dispose() {
    _peso.dispose();
    _sueno.dispose();
    super.dispose();
  }

  double? _parse(String t) {
    final limpio = t.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;
    return double.tryParse(limpio);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await ref.read(estadoControllerProvider.notifier).registrar(
            peso: _parse(_peso.text),
            energia: _energia,
            sueno: _parse(_sueno.text),
            animo: _animo,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo estás hoy?',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Registra lo que quieras. No tienes que llenar todo.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _peso,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso',
                    suffixText: 'kg',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _sueno,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Sueño',
                    suffixText: 'h',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Energía',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          _Escala(
            value: _energia,
            onChanged: (v) => setState(() => _energia = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Ánimo',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          _Escala(
            value: _animo,
            onChanged: (v) => setState(() => _animo = v),
          ),
          const SizedBox(height: AppSpacing.xl),
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
    );
  }
}

/// Selector 1–5 (energía / ánimo). Pulsar de nuevo el mismo número lo limpia.
class _Escala extends StatelessWidget {
  const _Escala({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(value == i ? null : i),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == i
                      ? AppColors.olive
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Text(
                  '$i',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value == i
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
