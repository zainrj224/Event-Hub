import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors  –  all static Color constants used across the app
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF1A1A2E); // deep navy
  static const Color lime           = Color(0xFFCCFF00); // neon lime accent

  // ── Dark-mode surfaces ─────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F0F17);
  static const Color darkSurface    = Color(0xFF1C1C28);
  static const Color darkSurfaceLow = Color(0xFF16161F);
  static const Color darkOutline    = Color(0xFF3A3A50);

  // ── Dark-mode text ─────────────────────────────────────────────────────────
  static const Color darkText          = Color(0xFFF0F0F8);
  static const Color darkTextSecondary = Color(0xFF9090AA);

  // ── Light-mode surfaces ────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF0F0F5);
  static const Color surfaceLow      = Color(0xFFF5F5FA);

  // ── Light-mode text ────────────────────────────────────────────────────────
  static const Color lightText          = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B88);

  // ── Material / semantic ────────────────────────────────────────────────────
  static const Color onSurface        = Color(0xFF1A1A2E);
  static const Color onSurfaceVariant = Color(0xFF6B6B88);
  static const Color outline          = Color(0xFFBBBBCC);

  // ── Semantic colours ───────────────────────────────────────────────────────
  static const Color error          = Color(0xFFFF4D4D);
  static const Color errorContainer = Color(0xFFFFECEC);

  // ── Purple accent (saved-events screen) ───────────────────────────────────
  static const Color purple      = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFEDE9FE);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme  –  light + dark ThemeData
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark => _buildDark();
  static ThemeData get light => _buildLight();

  static ThemeData _buildDark() {
    const colorScheme = ColorScheme.dark(
      primary:          AppColors.lime,
      onPrimary:        AppColors.primary,
      secondary:        AppColors.lime,
      onSecondary:      AppColors.primary,
      surface:          AppColors.darkSurface,
      onSurface:        AppColors.darkText,
      error:            AppColors.error,
      onError:          Colors.white,
      outline:          AppColors.darkOutline,
    );

    return ThemeData(
      useMaterial3:  true,
      colorScheme:   colorScheme,
      brightness:    Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Inter',

      appBarTheme: const AppBarTheme(
        backgroundColor:  AppColors.darkBackground,
        foregroundColor:  AppColors.darkText,
        elevation:        0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkText),
        titleTextStyle: TextStyle(
          color:      AppColors.darkText,
          fontSize:   18,
          fontWeight: FontWeight.w700,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      AppColors.darkSurface,
        selectedItemColor:    AppColors.lime,
        unselectedItemColor:  AppColors.darkTextSecondary,
        elevation:            0,
        type: BottomNavigationBarType.fixed,
      ),

      cardTheme: CardThemeData(
        color:        AppColors.darkSurface,
        elevation:    0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.primary,
          elevation:       0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w800),
        displaySmall:  TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w500),
        titleSmall:    TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w500),
        bodyLarge:     TextStyle(color: AppColors.darkText),
        bodyMedium:    TextStyle(color: AppColors.darkText),
        bodySmall:     TextStyle(color: AppColors.darkTextSecondary),
        labelLarge:    TextStyle(color: AppColors.darkText,          fontWeight: FontWeight.w600),
        labelMedium:   TextStyle(color: AppColors.darkTextSecondary),
        labelSmall:    TextStyle(color: AppColors.darkTextSecondary),
      ),

      dividerTheme: const DividerThemeData(
        color:     AppColors.darkOutline,
        thickness: 0.5,
      ),

      iconTheme: const IconThemeData(color: AppColors.darkText),

      switchTheme: SwitchThemeData(
        thumbColor:  WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.white),
        trackColor:  WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.lime : AppColors.darkOutline),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.lime : Colors.transparent),
        checkColor: WidgetStateProperty.all(AppColors.primary),
        side: const BorderSide(color: AppColors.darkOutline),
      ),

      chipTheme: ChipThemeData(
        backgroundColor:    AppColors.darkSurface,
        selectedColor:      AppColors.lime,
        labelStyle:         const TextStyle(color: AppColors.darkText, fontSize: 13),
        secondaryLabelStyle:const TextStyle(color: AppColors.primary,  fontSize: 13),
        side: const BorderSide(color: AppColors.darkOutline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor:         AppColors.lime,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor:     AppColors.lime,
        dividerColor:       Colors.transparent,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.primary,
        elevation: 4,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: const TextStyle(color: AppColors.darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
            color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: const TextStyle(
            color: AppColors.darkTextSecondary, fontSize: 14),
      ),
    );
  }

  static ThemeData _buildLight() {
    const colorScheme = ColorScheme.light(
      primary:    AppColors.primary,
      onPrimary:  Colors.white,
      secondary:  AppColors.lime,
      onSecondary:AppColors.primary,
      surface:    Colors.white,
      onSurface:  AppColors.onSurface,
      error:      AppColors.error,
      onError:    Colors.white,
      outline:    AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme:  colorScheme,
      brightness:   Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: 'Inter',

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.onSurface,
        elevation:       0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.onSurface),
        titleTextStyle: TextStyle(
          color:      AppColors.onSurface,
          fontSize:   18,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        color:     Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation:       0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle:  const TextStyle(color: AppColors.onSurfaceVariant),
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      iconTheme: const IconThemeData(color: AppColors.onSurface),

      dividerTheme: const DividerThemeData(
        color:     AppColors.outline,
        thickness: 0.5,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.onSurface,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
            color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: const TextStyle(
            color: AppColors.onSurfaceVariant, fontSize: 14),
      ),
    );
  }
}
