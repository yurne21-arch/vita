import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';

/// Envoltura de la base local. Best-effort: si no hay base (p. ej. en Web),
/// no hace nada y la app sigue funcionando (Supabase es la fuente de verdad).
class LocalCacheService {
  LocalCacheService(this._db);

  final AppDatabase? _db;

  Future<void> saveProfile({
    required String id,
    String? displayName,
    String? locale,
  }) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.into(db.cachedProfiles).insertOnConflictUpdate(
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
