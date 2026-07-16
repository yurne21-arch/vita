import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/profile.dart';

/// Carga el perfil propio (round-trip con Supabase + caché local).
class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final uid = ref.watch(usuarioActualProvider); // recarga al cambiar sesión
    if (uid == null) return null;
    return ref.read(profileRepositoryProvider).loadOwnProfile();
  }

  Future<void> actualizarNombre(String nombre) async {
    await ref.read(profileRepositoryProvider).actualizarNombre(nombre);
    ref.invalidateSelf();
    await future;
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);
