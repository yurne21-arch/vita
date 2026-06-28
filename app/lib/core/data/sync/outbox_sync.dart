import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../local/app_database.dart';
import 'sync_port.dart';

/// Implementación gratuita del SyncPort con el patrón outbox sobre Drift.
/// Esqueleto del Sprint 0. Best-effort: si no hay base (Web), no hace nada.
class OutboxSync implements SyncPort {
  OutboxSync(this._db);

  final AppDatabase? _db;

  @override
  Future<void> enqueue(String entity, Map<String, dynamic> payload) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.into(db.outboxEntries).insert(
            OutboxEntriesCompanion.insert(
              entity: entity,
              payload: jsonEncode(payload),
            ),
          );
    } catch (e) {
      debugPrint('Outbox no disponible (se omite): $e');
    }
  }

  @override
  Future<void> processQueue() async {
    // TODO(sprint-posterior): procesar pendientes contra Supabase.
  }
}
