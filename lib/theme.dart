import 'package:flutter/material.dart';

class LightModeColors {
  // Sunny Beach Day Palette
  static const lightPrimary = Color(0xFF2A9D8F); // Teal from palette
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE9C46A); // Yellow from palette
  static const lightOnPrimaryContainer =
      Color(0xFF264653); // Dark teal from palette
  static const lightSecondary = Color(0xFFF4A261); // Orange from palette
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Color(0xFFE76F51); // Coral from palette
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightError = Color(0xFFE76F51); // Using coral for error
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFF3E0);
  static const lightOnErrorContainer = Color(0xFF264653);
  static const lightInversePrimary = Color(0xFFE9C46A);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFFFFDF7); // Warm white
  static const lightOnSurface = Color(0xFF264653); // Dark teal
  static const lightAppBarBackground = Color(0xFFFFFDF7);
}

class DarkModeColors {
  // Dark version of Sunny Beach Day Palette
  static const darkPrimary = Color(0xFF52C7B8); // Lighter teal for dark mode
  static const darkOnPrimary = Color(0xFF264653);
  static const darkPrimaryContainer = Color(0xFF1A5D52); // Darker teal
  static const darkOnPrimaryContainer = Color(0xFFE9C46A);
  static const darkSecondary = Color(0xFFF4A261); // Keep orange
  static const darkOnSecondary = Color(0xFF264653);
  static const darkTertiary = Color(0xFFE76F51); // Keep coral
  static const darkOnTertiary = Color(0xFF264653);
  static const darkError = Color(0xFFE76F51); // Using coral for error
  static const darkOnError = Color(0xFF264653);
  static const darkErrorContainer = Color(0xFF8B4A3A);
  static const darkOnErrorContainer = Color(0xFFFFE4DE);
  static const darkInversePrimary = Color(0xFF2A9D8F);
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Color(0xFF1A2B2E); // Dark teal surface
  static const darkOnSurface = Color(0xFF52C7B8); // Yellow text
  static const darkAppBarBackground = Color(0xFF264653); // Darkest teal
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

// Helper function to create TextTheme with Quicksand font
TextTheme _createTextTheme() {
  return TextTheme(
    displayLarge: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  );
}

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: LightModeColors.lightPrimary,
        onPrimary: LightModeColors.lightOnPrimary,
        primaryContainer: LightModeColors.lightPrimaryContainer,
        onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
        secondary: LightModeColors.lightSecondary,
        onSecondary: LightModeColors.lightOnSecondary,
        tertiary: LightModeColors.lightTertiary,
        onTertiary: LightModeColors.lightOnTertiary,
        error: LightModeColors.lightError,
        onError: LightModeColors.lightOnError,
        errorContainer: LightModeColors.lightErrorContainer,
        onErrorContainer: LightModeColors.lightOnErrorContainer,
        inversePrimary: LightModeColors.lightInversePrimary,
        shadow: LightModeColors.lightShadow,
        surface: LightModeColors.lightSurface,
        onSurface: LightModeColors.lightOnSurface,
        outline: const Color(0xFFE5E7EB),
      ),
      brightness: Brightness.light,
      appBarTheme: AppBarTheme(
        backgroundColor: LightModeColors.lightAppBarBackground,
        foregroundColor: LightModeColors.lightOnPrimaryContainer,
        elevation: 0,
      ),
      fontFamily: 'Quicksand',
      textTheme: _createTextTheme(),
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: DarkModeColors.darkPrimary,
        onPrimary: DarkModeColors.darkOnPrimary,
        primaryContainer: DarkModeColors.darkPrimaryContainer,
        onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
        secondary: DarkModeColors.darkSecondary,
        onSecondary: DarkModeColors.darkOnSecondary,
        tertiary: DarkModeColors.darkTertiary,
        onTertiary: DarkModeColors.darkOnTertiary,
        error: DarkModeColors.darkError,
        onError: DarkModeColors.darkOnError,
        errorContainer: DarkModeColors.darkErrorContainer,
        onErrorContainer: DarkModeColors.darkOnErrorContainer,
        inversePrimary: DarkModeColors.darkInversePrimary,
        shadow: DarkModeColors.darkShadow,
        surface: DarkModeColors.darkSurface,
        onSurface: DarkModeColors.darkOnSurface,
        outline: const Color(0xFF374151),
      ),
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        backgroundColor: DarkModeColors.darkAppBarBackground,
        foregroundColor: DarkModeColors.darkOnPrimaryContainer,
        elevation: 0,
      ),
      fontFamily: 'Quicksand',
      fontFamilyFallback: const ['NotoEmoji'],
      textTheme: _createTextTheme(),
    );
