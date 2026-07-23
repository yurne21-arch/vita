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
    final client = _supabase.client;

    // 1. Lee el perfil existente (respeta el display_name ya guardado).
    final existing =
        await client.from('profiles').select().eq('id', user.id).maybeSingle();

    Map<String, dynamic> row;
    if (existing != null) {
      row = existing; // ya existe -> NO se sobrescribe el nombre
    } else {
      // 2. Solo si no existe, lo crea con un nombre inicial.
      final fallbackName = (user.userMetadata?['display_name'] as String?) ??
          user.email?.split('@').first ??
          'VITA';
      row = await client
          .from('profiles')
          .insert({'id': user.id, 'display_name': fallbackName})
          .select()
          .single();
    }

    final profile = Profile.fromMap(row);

    await _cache.saveProfile(
      id: profile.id,
      displayName: profile.displayName,
      locale: profile.locale,
    );

    return profile;
  }

  @override
  Future<void> actualizarNombre(String nombre) async {
    final user = _supabase.client.auth.currentUser;
    if (user == null) return;
    final limpio = nombre.trim();
    if (limpio.isEmpty) return;
    await _supabase.client
        .from('profiles')
        .update({'display_name': limpio}).eq('id', user.id);
  }
}
