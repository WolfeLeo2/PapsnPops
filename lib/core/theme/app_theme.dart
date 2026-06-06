import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgCanvasDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        primaryContainer: AppColors.accentDark,
        secondary: AppColors.brandSecondary,
        tertiary: AppColors.brandTertiary,
        surface: AppColors.bgSurfaceDark,
        surfaceContainer: AppColors.bgSurfaceDark,
        surfaceContainerHigh: AppColors.bgSurfaceHighlightDark,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textMutedDark,
        outline: AppColors.borderSubtleDark,
      ),
      textTheme: AppTypography.darkTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgCanvasDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgSurfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppColors.roundedCard,
          side: BorderSide(color: AppColors.borderSubtleDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtleDark,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurfaceHighlightDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: InputBorder.none,
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppColors.roundedCard,
          borderSide: BorderSide(color: AppColors.borderSubtleDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppColors.roundedCard,
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppColors.roundedCard,
          borderSide: BorderSide(color: AppColors.brandAccent),
        ),
        hintStyle: const TextStyle(color: AppColors.textMutedDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          textStyle: AppTypography.darkTextTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: AppColors.roundedPill,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurfaceDark,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppColors.roundedSoft),
        selectedTileColor: AppColors.accent.withValues(alpha: 0.1),
        selectedColor: AppColors.accent,
        iconColor: AppColors.textMutedDark,
        textColor: AppColors.textMutedDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        minLeadingWidth: 20,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgCanvasLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        primaryContainer: AppColors.accentDark,
        secondary: AppColors.brandSecondaryLight,
        surface: AppColors.bgSurfaceLight,
        surfaceContainer: AppColors.bgSurfaceLight,
        surfaceContainerHigh: AppColors.bgCanvasLight,
        tertiary: AppColors.brandTertiary,
        onTertiary: Colors.black87,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.textMutedLight,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimaryLight,
        onSurfaceVariant: AppColors.textMutedLight,
        outline: AppColors.borderSubtleLight,
      ),
      textTheme: AppTypography.lightTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgCanvasLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgSurfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppColors.roundedCard,
          side: BorderSide(color: AppColors.borderSubtleLight, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: InputBorder.none,
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppColors.roundedCard,
          borderSide: BorderSide(color: AppColors.borderSubtleLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppColors.roundedCard,
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppColors.roundedCard,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          textStyle: AppTypography.lightTextTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: AppColors.roundedPill,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppColors.roundedSoft),
        selectedTileColor: AppColors.accent.withValues(alpha: 0.1),
        selectedColor: AppColors.accent,
        iconColor: AppColors.textMutedLight,
        textColor: AppColors.textMutedLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        minLeadingWidth: 20,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
