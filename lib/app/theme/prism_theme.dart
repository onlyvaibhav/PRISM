/// PRISM Theme
///
/// Dark theme configuration for PRISM with calm, modern aesthetics.
library;

import 'package:flutter/material.dart';
import 'theme_constants.dart';

/// PRISM Dark Theme
class PrismTheme {
  PrismTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: PrismColors.primary,
        onPrimary: Colors.black,
        primaryContainer: PrismColors.primaryDark,
        secondary: PrismColors.secondary,
        onSecondary: Colors.black,
        secondaryContainer: PrismColors.secondaryDark,
        surface: PrismColors.surface,
        onSurface: PrismColors.textPrimary,
        error: PrismColors.error,
        onError: Colors.white,
      ),

      // Background
      scaffoldBackgroundColor: PrismColors.background,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: PrismColors.background,
        foregroundColor: PrismColors.textPrimary,
        titleTextStyle: PrismTypography.titleLarge,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: PrismColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PrismRadius.lg),
        ),
        shadowColor: PrismColors.cardShadow,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PrismColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: PrismSpacing.lg,
            vertical: PrismSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PrismRadius.md),
          ),
          textStyle: PrismTypography.labelLarge.copyWith(
            color: Colors.black,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PrismColors.primary,
          textStyle: PrismTypography.labelLarge,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PrismColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PrismRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PrismRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PrismRadius.md),
          borderSide: const BorderSide(
            color: PrismColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PrismSpacing.md,
          vertical: PrismSpacing.md,
        ),
        hintStyle: PrismTypography.bodyMedium.copyWith(
          color: PrismColors.textHint,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: PrismTypography.displayLarge,
        displayMedium: PrismTypography.displayMedium,
        headlineLarge: PrismTypography.headlineLarge,
        headlineMedium: PrismTypography.headlineMedium,
        titleLarge: PrismTypography.titleLarge,
        titleMedium: PrismTypography.titleMedium,
        bodyLarge: PrismTypography.bodyLarge,
        bodyMedium: PrismTypography.bodyMedium,
        labelLarge: PrismTypography.labelLarge,
        labelMedium: PrismTypography.labelMedium,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: PrismColors.surfaceVariant,
        thickness: 1,
        space: PrismSpacing.md,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: PrismColors.textSecondary,
        size: 24,
      ),
    );
  }
}
