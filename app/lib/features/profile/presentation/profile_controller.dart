import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/profile.dart';

/// Carga el perfil propio (round-trip con Supabase + caché local).
class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final session =
        ref.read(supabaseServiceProvider).client.auth.currentSession;
    if (session == null) return null;
    return ref.read(profileRepositoryProvider).loadOwnProfile();
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);
