import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local/local_cache_service.dart';
import 'data/remote/supabase_service.dart';
import 'data/sync/outbox_sync.dart';
import 'data/sync/sync_port.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/profile/data/profile_repository_impl.dart';
import '../features/profile/domain/profile_repository.dart';

final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => const SupabaseService());

/// Id de la usuaria con sesión abierta (null si no hay ninguna).
///
/// Todo controlador que lea datos de una usuaria debe observarlo:
///
///     ref.watch(usuarioActualProvider);
///
/// Así, al cerrar sesión y entrar otra persona, el estado cacheado se
/// reconstruye. Sin esto, los hábitos, prioridades y proyectos de la usuaria
/// anterior seguirían en memoria y se los mostraríamos a la siguiente.
///
/// Se expone el id (no la sesión) a propósito: al refrescarse el token, la
/// sesión cambia pero el id no, y no hay que recargar nada.
final usuarioActualProvider = Provider<String?>((ref) {
  final auth = ref.watch(supabaseServiceProvider).client.auth;
  final sub = auth.onAuthStateChange.listen((evento) {
    final nuevo = evento.session?.user.id;
    if (nuevo != ref.state) ref.state = nuevo;
  });
  ref.onDispose(sub.cancel);
  return auth.currentUser?.id;
});

final localCacheProvider =
    Provider<LocalCacheService>((ref) => const LocalCacheService());

final syncPortProvider = Provider<SyncPort>((ref) => const OutboxSync());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(supabaseServiceProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ref.read(supabaseServiceProvider),
    ref.read(localCacheProvider),
  ),
);
