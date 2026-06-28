import '../../../core/data/local/local_cache_service.dart';
import '../../../core/data/remote/supabase_service.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._supabase, this._cache);

  final SupabaseService _supabase;
  final LocalCacheService _cache;

  @override
  Future<Profile?> loadOwnProfile() async {
    final user = _supabase.client.auth.currentUser;
    if (user == null) return null;

    final fallbackName =
        (user.userMetadata?['display_name'] as String?) ??
            user.email?.split('@').first ??
            'VITA';

    // Round-trip con Supabase: upsert (respeta RLS) + lectura de la fila propia.
    final row = await _supabase.client
        .from('profiles')
        .upsert({'id': user.id, 'display_name': fallbackName}, onConflict: 'id')
        .select()
        .single();

    final profile = Profile.fromMap(row);

    // Caché local best-effort (no rompe si no está disponible).
    await _cache.saveProfile(
      id: profile.id,
      displayName: profile.displayName,
      locale: profile.locale,
    );

    return profile;
  }
}
