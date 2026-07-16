import 'profile.dart';

/// Contrato del perfil. Carga (y crea si hace falta) el perfil propio.
abstract interface class ProfileRepository {
  /// Asegura que exista el perfil de la usuaria autenticada y lo devuelve.
  /// Demuestra el round-trip con Supabase (RLS) + caché local best-effort.
  Future<Profile?> loadOwnProfile();

  /// Cambia el nombre que se muestra en la app.
  Future<void> actualizarNombre(String nombre);
}
