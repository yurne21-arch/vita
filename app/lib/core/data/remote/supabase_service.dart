import 'package:supabase_flutter/supabase_flutter.dart';

/// Punto de acceso único al cliente de Supabase.
/// VITA es la fuente de verdad; el cliente solo lee y escribe en ella.
class SupabaseService {
  const SupabaseService();

  SupabaseClient get client => Supabase.instance.client;
}
