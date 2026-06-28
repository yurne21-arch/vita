import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Construye los temas claro y oscuro de VITA.
/// Minimalismo premium: superficies limpias, pocas líneas, acento verde oliva.
abstract class AppTheme {
  const AppTheme._();

  static ThemeData light() => _base(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: AppColors.olive,
          onPrimary: Colors.white,
          secondary: AppColors.oliveSoft,
          surface: AppColors.lightBg,
          onSurface: AppColors.lightInk,
          surfaceContainerHighest: AppColors.lightSurface,
          outlineVariant: AppColors.lightHairline,
          error: AppColors.danger,
        ),
        scaffold: AppColors.lightBg,
        muted: AppColors.lightMuted,
        hairline: AppColors.lightHairline,
      );

  static ThemeData dark() => _base(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: AppColors.oliveSoft,
          onPrimary: AppColors.darkBg,
          secondary: AppColors.olive,
          surface: AppColors.darkBg,
          onSurface: AppColors.darkInk,
          surfaceContainerHighest: AppColors.darkSurface,
          outlineVariant: AppColors.darkHairline,
          error: AppColors.danger,
        ),
        scaffold: AppColors.darkBg,
        muted: AppColors.darkMuted,
        hairline: AppColors.darkHairline,
      );

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffold,
    required Color muted,
    required Color hairline,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffold,
        elevation: 0,
        height: 64,
        indicatorColor: scheme.primary.withAlpha(36),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),
      extensions: [AppSemanticColors(muted: muted, hairline: hairline)],
    );
  }
}

/// Colores semánticos que Material no expone directamente.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({required this.muted, required this.hairline});

  final Color muted;
  final Color hairline;

  @override
  AppSemanticColors copyWith({Color? muted, Color? hairline}) =>
      AppSemanticColors(
        muted: muted ?? this.muted,
        hairline: hairline ?? this.hairline,
      );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      hairline: Color.lerp(hairline, other.hairline, t) ?? hairline,
    );
  }
}
