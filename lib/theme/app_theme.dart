import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ------ Tokens de forma ------
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radius = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  // ------ Espaçamentos (grid 4px) ------
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;

  // ============================================================
  // Temas
  // ============================================================
  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      brightness: Brightness.light,
      primary: AppColors.indigo,
      onPrimary: Colors.white,
      secondary: AppColors.violet,
      onSecondary: Colors.white,
      tertiary: AppColors.pink,
      onTertiary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      surfaceContainerLowest: AppColors.lightSurface,
      surfaceContainerLow: AppColors.lightBackground,
      surfaceContainer: AppColors.lightSurfaceAlt,
      surfaceContainerHigh: AppColors.lightSurfaceMuted,
      error: AppColors.danger,
    );

    return _baseTheme(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      dividerColor: AppColors.lightBorder,
      cardColor: AppColors.lightSurface,
    );
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      brightness: Brightness.dark,
      primary: const Color(0xFF6FA8D8),
      onPrimary: const Color(0xFF0B1422),
      secondary: const Color(0xFF45C2B5),
      onSecondary: const Color(0xFF0B1422),
      tertiary: const Color(0xFFE6A86E),
      onTertiary: const Color(0xFF1B2735),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurfaceAlt,
      surfaceContainerHigh: AppColors.darkSurfaceMuted,
      error: const Color(0xFFE07575),
    );

    return _baseTheme(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      dividerColor: AppColors.darkBorder,
      cardColor: AppColors.darkSurface,
    );
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final Color textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final TextTheme base = GoogleFonts.dmSansTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final TextTheme textTheme = base.copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 40,
        color: scheme.onSurface,
        height: 1.05,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 30,
        color: scheme.onSurface,
        height: 1.12,
        letterSpacing: -0.3,
      ),
      displaySmall: GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        color: scheme.onSurface,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 22,
        color: scheme.onSurface,
        height: 1.25,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        letterSpacing: -0.2,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        letterSpacing: -0.1,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.1,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.6),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.55),
      bodySmall: base.bodySmall?.copyWith(color: textMuted, fontSize: 12.5),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        fontSize: 12,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        fontSize: 10.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark ? Colors.black26 : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        labelStyle: textTheme.labelLarge?.copyWith(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 14.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: BorderSide(color: border, width: 1.2),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: scheme.primary.withValues(alpha: 0.14),
        disabledColor: surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: border),
        ),
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(radiusXs),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.18),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.14),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimary,
        ),
      ),
    );
  }

  // ============================================================
  // Responsividade refinada
  // ============================================================
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1280;
  static const double wideBreakpoint = 1600;

  static double horizontalPadding(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    if (w >= desktopBreakpoint) return 48;
    if (w >= tabletBreakpoint) return 36;
    if (w >= mobileBreakpoint) return 24;
    return 16;
  }

  static double contentMaxWidth(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    if (w >= wideBreakpoint) return 1400;
    if (w >= desktopBreakpoint) return 1180;
    if (w >= tabletBreakpoint) return 960;
    return w;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Retorna um valor baseado no breakpoint atual.
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return desktop ?? tablet ?? mobile;
  }
}
