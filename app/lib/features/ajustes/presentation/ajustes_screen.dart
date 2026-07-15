import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/errores.dart';
import '../../../core/widgets/vita_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/profile_controller.dart';

/// Ajustes: quién eres y cómo salir.
///
/// Reemplaza el placeholder "Más". Es deliberadamente pequeña: solo lo que hoy
/// existe de verdad. Cuando haya más que configurar, crecerá.
class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final perfil = ref.watch(profileControllerProvider);
    final correo = ref
        .watch(supabaseServiceProvider)
        .client
        .auth
        .currentUser
        ?.email;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: const Text('Ajustes'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                VitaCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TU CUENTA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      perfil.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => ErrorEnTarjeta(
                          mensaje: mensajeDeError(e),
                          onReintentar: () =>
                              ref.invalidate(profileControllerProvider),
                        ),
                        data: (p) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p?.displayName ?? 'Sin nombre',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (correo != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                correo,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _CalendarioCard(
                  token: perfil.valueOrNull?.calendarToken,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => _confirmarSalir(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enlace de calendario suscribible: se pega en Google Calendar (o Apple) una
/// vez y los eventos de VITA aparecen ahí, con aviso y sonido en el teléfono.
class _CalendarioCard extends StatelessWidget {
  const _CalendarioCard({required this.token});
  final String? token;

  String? get _url => token == null
      ? null
      : '${Env.supabaseUrl}/functions/v1/calendar?token=$token';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = _url;
    return VitaCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  size: 20, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text('RECORDATORIOS EN TU CALENDARIO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Agrega este enlace a Google Calendar una vez. Tus eventos de VITA '
            'aparecerán ahí y tu teléfono te avisará con sonido a la hora.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          if (url == null)
            const Text('Preparando tu enlace…')
          else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: SelectableText(
                url,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enlace copiado.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar enlace'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Cómo agregarlo en Google Calendar:',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '1. Abre calendar.google.com en el computador.\n'
              '2. A la izquierda, junto a "Otros calendarios", toca + → '
              '"Desde una URL".\n'
              '3. Pega el enlace y toca "Añadir calendario".\n'
              'En tu teléfono aparecerá solo, y te avisará con sonido.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _confirmarSalir(BuildContext context, WidgetRef ref) async {
  final salir = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('Tendrás que volver a entrar con tu correo.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (salir != true || !context.mounted) return;
  await accionSegura(
    context,
    () => ref.read(authControllerProvider.notifier).signOut(),
  );
}
