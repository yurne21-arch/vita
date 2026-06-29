import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/vita_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/profile_controller.dart';
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
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
          children: [
            const _BuenosDias(),
            const SizedBox(height: AppSpacing.lg),
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
                Expanded(child: _Entrenamiento()),
                SizedBox(width: _kGap),
                Expanded(child: _Menu()),
                SizedBox(width: _kGap),
                Expanded(child: _Habitos()),
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
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
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
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
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
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600, height: 1.15),
        ),
        const SizedBox(height: 2),
        Text(
          _fechaLarga(now),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    return VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Eyebrow('VERSÍCULO DEL DÍA'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '"Todo lo puedo en Cristo que me fortalece."',
            style: theme.textTheme.titleMedium?.copyWith(
                height: 1.4,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Filipenses 4:13',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    return VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('HOY IMPORTA'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tus tres prioridades del día.',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
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

class _EstadoGeneral extends StatelessWidget {
  const _EstadoGeneral();

  @override
  Widget build(BuildContext context) {
    return VitaCard(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Eyebrow('CÓMO ESTÁS HOY'),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Indicador(icon: Icons.monitor_weight_outlined, label: 'Peso'),
              _Indicador(icon: Icons.bolt_outlined, label: 'Energía'),
              _Indicador(icon: Icons.bedtime_outlined, label: 'Sueño'),
              _Indicador(icon: Icons.spa_outlined, label: 'Modo'),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          _HintLine('Toca para registrar cómo amaneciste.'),
        ],
      ),
    );
  }
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

class _Indicador extends StatelessWidget {
  const _Indicador({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 2),
          Text('—',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
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
