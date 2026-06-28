import 'sync_port.dart';

/// Implementación temporal del SyncPort para el Sprint 0: no hace nada.
/// (El outbox con Drift se reactivará en un sprint posterior.)
class OutboxSync implements SyncPort {
  const OutboxSync();

  @override
  Future<void> enqueue(String entity, Map<String, dynamic> payload) async {
    // Sin operación por ahora.
  }

  @override
  Future<void> processQueue() async {
    // Sin operación por ahora.
  }
}
