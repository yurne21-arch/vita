import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local/app_database.dart';
import 'data/local/local_cache_service.dart';
import 'data/remote/supabase_service.dart';
import 'data/sync/outbox_sync.dart';
import 'data/sync/sync_port.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/profile/data/profile_repository_impl.dart';
import '../features/profile/domain/profile_repository.dart';

/// Infraestructura
final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => const SupabaseService());

final appDatabaseProvider = Provider<AppDatabase?>((ref) {
  final db = openLocalDatabaseOrNull();
  if (db != null) ref.onDispose(db.close);
  return db;
});

final localCacheProvider = Provider<LocalCacheService>(
  (ref) => LocalCacheService(ref.read(appDatabaseProvider)),
);

final syncPortProvider =
    Provider<SyncPort>((ref) => OutboxSync(ref.read(appDatabaseProvider)));

/// Repositorios
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(supabaseServiceProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ref.read(supabaseServiceProvider),
    ref.read(localCacheProvider),
  ),
);
