import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/vita_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/habitos_repository.dart';
import 'habitos_controller.dart';

/// ESQUELETO PREMIUM DE MI VIDA
/// El centro de VITA: una narración vertical del día en 11 tarjetas, en orden
/// fijo. Estados vacíos cálidos y contenido temporal donde aún no hay datos.
/// Los hábitos son la tarjeta 10, no el centro.
class MiVidaScreen extends ConsumerWidget {
  const MiVidaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VITA'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: const [
            _BuenosDias(),
            SizedBox(height: AppSpacing.xl),
            _Versiculo(),
            SizedBox(height: AppSpacing.md),
            _Reflexion(),
            SizedBox(height: AppSpacing.md),
            _EstadoGeneral(),
            SizedBox(height: AppSpacing.md),
            _Prioridades(),
            SizedBox(height: AppSpacing.md),
            _Agenda(),
            SizedBox(height: AppSpacing.md),
            _ProyectoPrincipal(),
            SizedBox(height: AppSpacing.md),
            _Entrenamiento(),
            SizedBox(height: AppSpacing.md),
            _Menu(),
            SizedBox(height: AppSpacing.md),
            _Habitos(),
            SizedBox(height: AppSpacing.md),
            _CierreDelDia(),
          ],
        ),
      ),
    );
  }
}

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
          style: theme.textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w700, height: 1.1),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _fechaLarga(now),
          style: theme.textTheme.titleMedium
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('VERSÍCULO DEL DÍA'),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Todo lo puedo en Cristo que me fortalece.',
            style: theme.textTheme.titleLarge
                ?.copyWith(height: 1.35, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Filipenses 4:13',
            style: theme.textTheme.bodyMedium
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('REFLEXIÓN'),
          const SizedBox(height: AppSpacing.md),
          Text(
            'La fortaleza no está en hacerlo todo hoy, sino en dar un paso '
            'con calma. Hoy basta con lo que sí puedes.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '¿Cuál es el único paso que importa hoy?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Eyebrow('CÓMO ESTÁS HOY'),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Indicador(icon: Icons.monitor_weight_outlined, label: 'Peso'),
              _Indicador(icon: Icons.bolt_outlined, label: 'Energía'),
              _Indicador(icon: Icons.bedtime_outlined, label: 'Sueño'),
              _Indicador(icon: Icons.spa_outlined, label: 'Modo'),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _HintLine('Toca para registrar cómo amaneciste.'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('HOY IMPORTA'),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aquí verás tus tres prioridades del día.',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'VITA elegirá lo esencial de toda tu vida y te dirá por qué. '
            'Por ahora, este espacio te espera tranquilo.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
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

class _Agenda extends StatelessWidget {
  const _Agenda();

  @override
  Widget build(BuildContext context) {
    return const VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('TU DÍA'),
          SizedBox(height: AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('PROYECTO DEL MES'),
          SizedBox(height: AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('MOVIMIENTO DE HOY'),
          SizedBox(height: AppSpacing.md),
          _EmptyHint(
            icon: Icons.fitness_center_outlined,
            title: 'Aún no tienes un programa.',
            subtitle: 'Tu entrenamiento del día aparecerá aquí cuando empieces tu ciclo.',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('TU MENÚ'),
          SizedBox(height: AppSpacing.md),
          _EmptyHint(
            icon: Icons.restaurant_outlined,
            title: 'Aún no tienes menú de la semana.',
            subtitle: 'Cuando lo generes, verás aquí qué comer hoy.',
            action: 'Generar menú',
          ),
        ],
      ),
    );
  }
}

/// Tarjeta 10 — Hábitos. REAL: reutiliza el controlador existente.
/// Ya no es el centro: es una tarjeta más, aquí abajo.
class _Habitos extends ConsumerWidget {
  const _Habitos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habitosAsync = ref.watch(habitosControllerProvider);

    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('HÁBITOS'),
          const SizedBox(height: AppSpacing.md),
          habitosAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              'No se pudieron cargar tus hábitos.',
              style: theme.textTheme.bodyMedium,
            ),
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
                  Text(
                    '$hechos de ${habitos.length} hoy',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('CIERRE DEL DÍA'),
          const SizedBox(height: AppSpacing.md),
          Text(
            '¿Cómo estuvo tu día?',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
            child: Text(
              'Lo mejor de hoy fue…',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Disponible esta noche. Sin prisa, sin culpa.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ---------- Piezas reutilizables (estética premium) ----------

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
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
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
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xs),
          Text('—',
              style: theme.textTheme.titleMedium
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
    return Text(
      text,
      style: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
              size: 18, color: theme.colorScheme.outlineVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
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
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, height: 1.5),
        ),
        if (action != null) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              action!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.olive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
            Text(habito.emoji ?? '•', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                habito.nombre,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              color: done
                  ? AppColors.olive
                  : theme.colorScheme.onSurfaceVariant,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- util ----------

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
