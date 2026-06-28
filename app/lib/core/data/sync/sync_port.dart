/// Contrato de sincronización offline ↔ Supabase.
///
/// En el MVP lo implementa [OutboxSync] (Drift + cola propia, gratis).
/// Si en el futuro se justifica, PowerSync u otra solución puede implementar
/// esta misma interfaz sin tocar el resto de la app.
abstract interface class SyncPort {
  /// Encola una escritura para sincronizar cuando haya conexión.
  Future<void> enqueue(String entity, Map<String, dynamic> payload);

  /// Procesa la cola pendiente contra Supabase.
  Future<void> processQueue();
}
