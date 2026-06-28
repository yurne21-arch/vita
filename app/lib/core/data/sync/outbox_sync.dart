import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../local/app_database.dart';
import 'sync_port.dart';

/// Implementación gratuita del [SyncPort] con el patrón outbox sobre Drift.
///
/// Esqueleto del Sprint 0: [enqueue] persiste la intención de escritura;
/// [processQueue] se completará en sprints posteriores (cuando haya módulos
/// que escriban offline). Todo es best-effort y no rompe la app.
class OutboxSync implements SyncPort {
  OutboxSync(this._db);

  final AppDatabase _db;

  @override
  Future<void> enqueue(String entity, Map<String, dynamic> payload) async {
    try {
      await _db.into(_db.outboxEntries).insert(
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
    // TODO(sprint-posterior): leer pendientes, enviarlos a Supabase,
    // marcar syncedAt y resolver conflictos (con datos append-only es simple).
  }
}
