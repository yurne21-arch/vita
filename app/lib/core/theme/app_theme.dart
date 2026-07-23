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
          primary: AppColors.accent,
          onPrimary: Colors.white,
          secondary: AppColors.accentSoft,
          surface: AppColors.lightBg,
          onSurface: AppColors.lightInk,
          onSurfaceVariant: AppColors.lightMuted,
          surfaceContainerLowest: AppColors.lightBg,
          surfaceContainerLow: AppColors.lightPanel,
          surfaceContainer: AppColors.lightPanel,
          surfaceContainerHigh: AppColors.lightSurface,
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
          primary: AppColors.accentSoft,
          onPrimary: AppColors.darkBg,
          secondary: AppColors.accent,
          surface: AppColors.darkBg,
          onSurface: AppColors.darkInk,
          onSurfaceVariant: AppColors.darkMuted,
          surfaceContainerHigh: AppColors.darkSurface,
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
      // Tipografía aprobada (Documento 6): Inter autoalojada, con fallback de
      // sistema para evitar salto de fuente perceptible.
      fontFamily: 'Inter',
      fontFamilyFallback: const [
        '-apple-system',
        'Segoe UI',
        'Roboto',
        'Helvetica Neue',
        'sans-serif'
      ],
      // Sin ripple Material: el movimiento orienta y confirma, no decora
      // (MASTER §5). El estado "pressed" lo dan los overlays de cada componente.
      splashFactory: NoSplash.splashFactory,
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
          // Alto mínimo 52; ancho mínimo 0. OJO: `Size.fromHeight(52)` fijaba el
          // ancho mínimo en INFINITO, lo que rompía cualquier FilledButton
          // dentro de un Row (el contenido desaparecía). Los botones de ancho
          // completo siguen llenándose por su contenedor (Column stretch /
          // SizedBox), no por este mínimo.
          minimumSize: const Size(0, 52),
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
      // El estilo del NavigationBar (sin píldora Material, acento activo,
      // etiquetas adaptables) vive en core/widgets/app_shell.dart, que es la
      // única barra y ya envuelve el NavigationBar en su propio tema.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffold,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 400),
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
