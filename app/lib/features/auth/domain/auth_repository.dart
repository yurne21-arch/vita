/// Contrato de autenticación. El dominio no conoce a Supabase.
abstract interface class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();
}
