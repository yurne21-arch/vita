/// Configuración de entorno de VITA.
///
/// Las llaves se inyectan en tiempo de compilación con `--dart-define` y
/// **nunca** se guardan en el repositorio.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Indica si las llaves necesarias están presentes.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
