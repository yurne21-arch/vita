import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita/core/theme/app_colors.dart';
import 'package:vita/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('el tema claro usa Material 3 y brillo claro', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.accent);
    });

    test('el tema oscuro usa brillo oscuro', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('expone los colores semánticos como extensión', () {
      final theme = AppTheme.light();
      final semantic = theme.extension<AppSemanticColors>();
      expect(semantic, isNotNull);
      expect(semantic!.muted, AppColors.lightMuted);
    });
  });
}
