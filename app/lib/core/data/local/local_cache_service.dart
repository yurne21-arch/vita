/// Caché local deshabilitado en el Sprint 0 (era best-effort).
///
/// Implementación temporal sin operación: la fuente de verdad es Supabase.
/// Se reactivará con Drift en un sprint posterior, con soporte Web correcto.
class LocalCacheService {
  const LocalCacheService();

  Future<void> saveProfile({
    required String id,
    String? displayName,
    String? locale,
  }) async {
    // Sin operación por ahora.
  }
}
