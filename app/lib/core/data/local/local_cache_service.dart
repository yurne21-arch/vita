import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';

/// Envoltura de la base local. Todas las operaciones son **best-effort**:
/// si el almacenamiento local no está disponible (p. ej. Web sin los assets
/// de Drift), la app sigue funcionando porque Supabase es la fuente de verdad.
class LocalCacheService {
  LocalCacheService(this._db);

  final AppDatabase _db;

  Future<void> saveProfile({
    required String id,
    String? displayName,
    String? locale,
  }) async {
    try {
      await _db.into(_db.cachedProfiles).insertOnConflictUpdate(
            CachedProfilesCompanion.insert(
              id: id,
              displayName: Value(displayName),
              locale: Value(locale),
            ),
          );
    } catch (e) {
      debugPrint('LocalCache no disponible (se omite): $e');
    }
  }
}
