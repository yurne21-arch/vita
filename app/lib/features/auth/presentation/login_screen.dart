import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Traduce los errores de Supabase Auth a algo que se pueda leer.
/// Nadie debería ver un `AuthApiException(statusCode: 400)` en su pantalla.
String _mensajeAuth(Object error) {
  final t = error.toString().toLowerCase();
  if (t.contains('invalid login credentials')) {
    return 'Correo o contraseña incorrectos.';
  }
  if (t.contains('user already registered') ||
      t.contains('already been registered')) {
    return 'Ya existe una cuenta con ese correo. Inicia sesión.';
  }
  if (t.contains('password should be at least')) {
    return 'La contraseña necesita al menos 6 caracteres.';
  }
  if (t.contains('unable to validate email') ||
      t.contains('invalid email')) {
    return 'Ese correo no parece válido.';
  }
  if (t.contains('email not confirmed')) {
    return 'Confirma tu correo antes de entrar.';
  }
  if (t.contains('signups not allowed') || t.contains('signup is disabled')) {
    return 'El registro está cerrado.';
  }
  if (t.contains('socket') ||
      t.contains('failed host lookup') ||
      t.contains('clientexception') ||
      t.contains('network')) {
    return 'Sin conexión. Revisa tu internet.';
  }
  return 'No pudimos entrar. Inténtalo de nuevo.';
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Valida antes de llamar al servidor, para poder decir qué falta.
  String? _validar() {
    if (_email.text.trim().isEmpty) return 'Escribe tu correo.';
    if (!_email.text.contains('@')) return 'Ese correo no parece válido.';
    if (_password.text.isEmpty) return 'Escribe tu contraseña.';
    return null;
  }

  void _entrar({required bool registrando}) {
    final error = _validar();
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final auth = ref.read(authControllerProvider.notifier);
    final correo = _email.text.trim();
    if (registrando) {
      auth.signUp(correo, _password.text);
    } else {
      auth.signIn(correo, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final theme = Theme.of(context);

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text(_mensajeAuth(next.error!))));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bienvenida a VITA',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tu sistema operativo personal.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Sin botón de "Crear cuenta": el registro está cerrado en
                  // Supabase (disable_signup), porque VITA es de una sola
                  // usuaria y la URL es pública. Para volver a abrirlo:
                  // panel de Supabase → Authentication → Sign In / Providers.
                  FilledButton(
                    onPressed:
                        isLoading ? null : () => _entrar(registrando: false),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
