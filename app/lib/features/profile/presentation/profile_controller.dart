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
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);
