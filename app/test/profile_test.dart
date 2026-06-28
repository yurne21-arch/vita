import 'package:flutter_test/flutter_test.dart';
import 'package:vita/features/profile/domain/profile.dart';

void main() {
  group('Profile.fromMap', () {
    test('mapea los campos presentes', () {
      final profile = Profile.fromMap({
        'id': 'u1',
        'display_name': 'Yurnelly',
        'locale': 'es-CL',
        'currency': 'CLP',
        'measurement_system': 'metric',
      });

      expect(profile.id, 'u1');
      expect(profile.displayName, 'Yurnelly');
      expect(profile.locale, 'es-CL');
      expect(profile.currency, 'CLP');
      expect(profile.measurementSystem, 'metric');
    });

    test('aplica valores por defecto cuando faltan', () {
      final profile = Profile.fromMap({'id': 'u2'});

      expect(profile.displayName, isNull);
      expect(profile.locale, 'es-CL');
      expect(profile.currency, 'CLP');
      expect(profile.measurementSystem, 'metric');
    });
  });
}
