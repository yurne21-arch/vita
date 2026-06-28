/// Perfil de la usuaria (entidad de dominio).
class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.locale,
    required this.currency,
    required this.measurementSystem,
  });

  final String id;
  final String? displayName;
  final String locale;
  final String currency;
  final String measurementSystem;

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        displayName: map['display_name'] as String?,
        locale: (map['locale'] as String?) ?? 'es-CL',
        currency: (map['currency'] as String?) ?? 'CLP',
        measurementSystem: (map['measurement_system'] as String?) ?? 'metric',
      );
}
