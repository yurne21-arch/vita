/// Perfil de la usuaria (entidad de dominio).
class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.locale,
    required this.currency,
    required this.measurementSystem,
    this.calendarToken,
  });

  final String id;
  final String? displayName;
  final String locale;
  final String currency;
  final String measurementSystem;
  final String? calendarToken; // secreto del feed de calendario (.ics)

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        displayName: map['display_name'] as String?,
        locale: (map['locale'] as String?) ?? 'es-CL',
        currency: (map['currency'] as String?) ?? 'CLP',
        measurementSystem: (map['measurement_system'] as String?) ?? 'metric',
        calendarToken: map['calendar_token'] as String?,
      );
}
