import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// Activar recordatorios: un solo botón. Al tocarlo desde el teléfono, se abre
/// el Calendario y pregunta si quiere suscribirse; al aceptar, los eventos de
/// VITA le avisan con sonido. El enlace `webcal://` es lo que iPhone/Android
/// entienden como "suscribirse a un calendario".
class _CalendarioCard extends StatelessWidget {
  const _CalendarioCard({required this.token});
  final String? token;

  // host sin el https:// para armar el enlace webcal://
  String get _host =>
      Env.supabaseUrl.replaceFirst('https://', '').replaceFirst('http://', '');

  String? get _urlHttps => token == null
      ? null
      : '${Env.supabaseUrl}/functions/v1/calendar?token=$token';

  String? get _urlWebcal =>
      token == null ? null : 'webcal://$_host/functions/v1/calendar?token=$token';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final webcal = _urlWebcal;
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
              Text('RECORDATORIOS EN TU TELÉFONO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tu teléfono te avisará con sonido a la hora de cada evento. '
            'Toca el botón y, cuando el teléfono pregunte, di que sí. '
            'Se hace una sola vez.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          if (webcal == null)
            const Text('Preparando…')
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _activar(context, webcal),
                icon: const Icon(Icons.event_available),
                label: const Text('Activar recordatorios'),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          // Respaldo discreto por si el botón no abre el calendario en algún
          // dispositivo: copiar el enlace.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _urlHttps == null
                  ? null
                  : () async {
                      await Clipboard.setData(
                          ClipboardData(text: _urlHttps!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enlace copiado.')),
                        );
                      }
                    },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar el enlace'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _activar(BuildContext context, String webcal) async {
    final ok = await launchUrl(Uri.parse(webcal),
        mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Abre VITA desde tu teléfono para activarlo, o usa "Copiar el enlace".'),
        ),
      );
    }
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
