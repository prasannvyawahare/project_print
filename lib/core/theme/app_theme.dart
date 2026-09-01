import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Single source of truth for the app's visual language: color roles and a
/// text scale with an explicit, intentional [FontWeight] per role, so
/// screens pull styling from [Theme.of(context)] instead of re-declaring
/// magic hex values and weights inline.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brandBlue,
      onPrimary: AppColors.white,
      secondary: AppColors.dashboardAccent,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.headingDark,
      error: AppColors.error,
      onError: AppColors.white,
    );

    final textTheme = TextTheme(
      displayLarge: _style(32, FontWeight.w800, colorScheme.onSurface),
      displayMedium: _style(28, FontWeight.w800, colorScheme.onSurface),
      displaySmall: _style(24, FontWeight.w800, colorScheme.onSurface),
      headlineLarge: _style(22, FontWeight.w800, colorScheme.onSurface),
      headlineMedium: _style(20, FontWeight.w800, colorScheme.onSurface),
      headlineSmall: _style(18, FontWeight.w800, colorScheme.onSurface),
      titleLarge: _style(17, FontWeight.w700, colorScheme.onSurface),
      titleMedium: _style(15, FontWeight.w700, colorScheme.onSurface),
      titleSmall: _style(13, FontWeight.w700, colorScheme.onSurface),
      bodyLarge: _style(16, FontWeight.w500, AppColors.bodyText),
      bodyMedium: _style(14, FontWeight.w500, AppColors.bodyText),
      bodySmall: _style(12, FontWeight.w400, AppColors.mutedText),
      labelLarge: _style(16, FontWeight.w700, colorScheme.onSurface),
      labelMedium: _style(13, FontWeight.w600, colorScheme.onSurface),
      labelSmall: _style(11, FontWeight.w600, AppColors.mutedText),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.headingDark,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelMedium),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
      ),
    );
  }

  static TextStyle _style(double size, FontWeight weight, Color color) {
    return TextStyle(fontSize: size, fontWeight: weight, color: color);
  }
}
