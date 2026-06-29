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
import '../data/prioridades_repository.dart';
import 'habitos_controller.dart';
import 'prioridades_controller.dart';

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

class _Prioridades extends ConsumerWidget {
  const _Prioridades();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(prioridadesControllerProvider);
    final prioridades = async.valueOrNull ?? const <Prioridad>[];

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
          const SizedBox(height: AppSpacing.md),
          if (async.isLoading && prioridades.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (prioridades.isEmpty)
            _PrioridadesVacio(
              onAgregar: () => _dialogoPrioridad(context, ref),
            )
          else ...[
            for (var i = 0; i < prioridades.length; i++)
              _PrioridadRow(
                posicion: i + 1,
                prioridad: prioridades[i],
                puedeSubir: i > 0,
                puedeBajar: i < prioridades.length - 1,
                onToggle: () => ref
                    .read(prioridadesControllerProvider.notifier)
                    .alternar(prioridades[i]),
                onEditar: () => _dialogoPrioridad(context, ref,
                    existente: prioridades[i]),
                onEliminar: () => ref
                    .read(prioridadesControllerProvider.notifier)
                    .eliminar(prioridades[i].id),
                onSubir: () => ref
                    .read(prioridadesControllerProvider.notifier)
                    .mover(i, -1),
                onBajar: () => ref
                    .read(prioridadesControllerProvider.notifier)
                    .mover(i, 1),
              ),
            if (prioridades.length < 3)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: _AgregarPrioridad(
                  onTap: () => _dialogoPrioridad(context, ref),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PrioridadesVacio extends StatelessWidget {
  const _PrioridadesVacio({required this.onAgregar});
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aún no defines lo esencial de hoy.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AgregarPrioridad(onTap: onAgregar),
      ],
    );
  }
}

class _AgregarPrioridad extends StatelessWidget {
  const _AgregarPrioridad({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.olive,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Agregar prioridad'),
      ),
    );
  }
}

class _PrioridadRow extends StatelessWidget {
  const _PrioridadRow({
    required this.posicion,
    required this.prioridad,
    required this.puedeSubir,
    required this.puedeBajar,
    required this.onToggle,
    required this.onEditar,
    required this.onEliminar,
    required this.onSubir,
    required this.onBajar,
  });

  final int posicion; // 1, 2, 3 (posición visible)
  final Prioridad prioridad;
  final bool puedeSubir;
  final bool puedeBajar;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onSubir;
  final VoidCallback onBajar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = prioridad.completada;
    final vacio = prioridad.texto.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color:
                  done ? AppColors.olive : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 18,
            child: Text(
              '$posicion.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: GestureDetector(
              onTap: onEditar,
              behavior: HitTestBehavior.opaque,
              child: Text(
                vacio ? 'Prioridad sin texto' : prioridad.texto,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontStyle: vacio ? FontStyle.italic : null,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: (vacio || done)
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            tooltip: 'Opciones',
            onSelected: (op) {
              if (op == 'subir') {
                onSubir();
              } else if (op == 'bajar') {
                onBajar();
              } else if (op == 'editar') {
                onEditar();
              } else if (op == 'eliminar') {
                onEliminar();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'subir',
                enabled: puedeSubir,
                child: const Row(children: [
                  Icon(Icons.arrow_upward, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Mover arriba'),
                ]),
              ),
              PopupMenuItem<String>(
                value: 'bajar',
                enabled: puedeBajar,
                child: const Row(children: [
                  Icon(Icons.arrow_downward, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Mover abajo'),
                ]),
              ),
              const PopupMenuItem<String>(
                value: 'editar',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Editar'),
                ]),
              ),
              const PopupMenuItem<String>(
                value: 'eliminar',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Eliminar'),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _dialogoPrioridad(
  BuildContext context,
  WidgetRef ref, {
  Prioridad? existente,
}) async {
  final controller = TextEditingController(text: existente?.texto ?? '');
  final esEdicion = existente != null;
  final notifier = ref.read(prioridadesControllerProvider.notifier);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(esEdicion ? 'Editar prioridad' : 'Nueva prioridad'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: '¿Qué es lo esencial hoy?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (esEdicion)
            TextButton(
              onPressed: () {
                notifier.eliminar(existente.id);
                Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Eliminar'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              final txt = value.text.trim();
              return FilledButton(
                onPressed: txt.isEmpty
                    ? null
                    : () {
                        if (esEdicion) {
                          notifier.editarTexto(existente.id, txt);
                        } else {
                          notifier.agregar(txt);
                        }
                        Navigator.of(ctx).pop();
                      },
                child: Text(esEdicion ? 'Guardar' : 'Agregar'),
              );
            },
          ),
        ],
      );
    },
  );
  controller.dispose();
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
                _Metric(
                    label: 'Peso',
                    value: _fmtPesoCard(
                        estado?.pesoUltimo, estado?.pesoTendencia)),
                _Metric(label: 'Energía', value: _fmt15(estado?.energia)),
                _Metric(
                    label: 'Sueño',
                    value: _fmtSuenoCard(
                        estado?.suenoCalidad, estado?.suenoHoras)),
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

String _fmt15(int? v) => v == null ? '—' : '$v/5';

String _fmtPesoCard(double? p, double? t) {
  if (p == null) return '—';
  var s = '${_numEs(p)} kg';
  if (t != null && t.abs() >= 0.05) s += t > 0 ? '  ↑' : '  ↓';
  return s;
}

const _suenoPalabra = {1: 'Mal', 2: 'Regular', 3: 'Bien'};

String _fmtSuenoCard(int? calidad, double? horas) {
  if (calidad != null) return _suenoPalabra[calidad] ?? '—';
  if (horas != null) return '${_numEs(horas)} h';
  return '—';
}

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
  int? _energia;
  int? _animo;
  int? _sueno; // 1 mal, 2 regular, 3 bien
  late final TextEditingController _horas;
  late final TextEditingController _peso;
  bool _mostrarPeso = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final a = widget.actual;
    _energia = a?.energia;
    _animo = a?.animo;
    _sueno = a?.suenoCalidad;
    _horas = TextEditingController(
        text: a?.suenoHoras != null ? _numEs(a!.suenoHoras!) : '');
    _peso = TextEditingController();
    // El peso solo se sugiere si aún no se registró esta semana.
    _mostrarPeso = a != null && !a.pesoEstaSemana;
  }

  @override
  void dispose() {
    _horas.dispose();
    _peso.dispose();
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
      final ctrl = ref.read(estadoControllerProvider.notifier);
      await ctrl.registrarDiario(
        energia: _energia,
        animo: _animo,
        suenoCalidad: _sueno,
        suenoHoras: _parse(_horas.text),
      );
      final peso = _parse(_peso.text);
      if (peso != null) await ctrl.registrarPeso(peso);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo guardar. Intenta de nuevo.')),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Cómo estás hoy?',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('Registra solo cómo te sientes hoy.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),

            _CampoLabel('Energía del día'),
            const SizedBox(height: AppSpacing.sm),
            _Escala(
              value: _energia,
              onChanged: (v) => setState(() => _energia = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            _CampoLabel('Ánimo del día'),
            const SizedBox(height: AppSpacing.sm),
            _Escala(
              value: _animo,
              onChanged: (v) => setState(() => _animo = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            _CampoLabel('Sueño'),
            const SizedBox(height: AppSpacing.sm),
            _SuenoSelector(
              value: _sueno,
              onChanged: (v) => setState(() => _sueno = v),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _horas,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Horas de sueño (opcional)',
                suffixText: 'h',
                border: OutlineInputBorder(),
              ),
            ),

            if (_mostrarPeso) ...[
              const SizedBox(height: AppSpacing.lg),
              _CampoLabel('Pesaje semanal · opcional'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _peso,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso',
                  suffixText: 'kg',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _mostrarPeso = true),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Registrar peso'),
                ),
              ),
            ],

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

class _CampoLabel extends StatelessWidget {
  const _CampoLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w600));
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

/// Selector de cualidad de sueño: Bien (3) / Regular (2) / Mal (1).
class _SuenoSelector extends StatelessWidget {
  const _SuenoSelector({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  static const _opciones = [
    (3, 'Bien'),
    (2, 'Regular'),
    (1, 'Mal'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < _opciones.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(
                  value == _opciones[i].$1 ? null : _opciones[i].$1),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == _opciones[i].$1
                      ? AppColors.olive
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Text(
                  _opciones[i].$2,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value == _opciones[i].$1
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
