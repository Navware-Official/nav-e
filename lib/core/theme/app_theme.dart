import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.white,
      primaryColor: AppColors.blueRibbon,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.blueRibbon,
        onPrimary: AppColors.white,
        secondary: AppColors.blueRibbonDark02,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.capeCodDark02,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        color: AppColors.capeCodDark01,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.blueRibbon,
        foregroundColor: AppColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blueRibbon,
          foregroundColor: AppColors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.capeCodDark02),
        bodyMedium: TextStyle(color: AppColors.capeCodDark02),
        titleLarge: TextStyle(
          color: AppColors.blueRibbonDark04,
          fontWeight: FontWeight.bold,
        ),
        labelLarge: TextStyle(color: AppColors.blueRibbon),
      ),
      cardColor: AppColors.white,
      dividerColor: AppColors.capeCodLight02,
      iconTheme: const IconThemeData(color: AppColors.blueRibbonDark04),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGray,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.capeCodLight02, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.blueRibbon, width: 2.0),
        ),
        border: OutlineInputBorder(), // fallback
        labelStyle: TextStyle(color: AppColors.blueRibbonDark04),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.blueRibbon, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: AppColors.blueRibbonDark02,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.capeCodDark02,
      primaryColor: AppColors.blueRibbon,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.blueRibbon,
        onPrimary: AppColors.white,
        secondary: AppColors.blueRibbonDark02,
        onSecondary: AppColors.white,
        surface: AppColors.capeCodLight02,
        onSurface: AppColors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        color: AppColors.blueRibbonDark04,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.blueRibbon,
        foregroundColor: AppColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blueRibbon,
          foregroundColor: AppColors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.white),
        bodyMedium: TextStyle(color: AppColors.lightGray),
        titleLarge: TextStyle(
          color: AppColors.blueRibbon,
          fontWeight: FontWeight.bold,
        ),
        labelLarge: TextStyle(color: AppColors.lightGray),
      ),
      cardColor: AppColors.capeCodLight02,
      dividerColor: AppColors.lightGray,
      iconTheme: const IconThemeData(color: AppColors.white),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.capeCodLight02,
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.blueRibbon),
        ),
        labelStyle: TextStyle(color: AppColors.capeCodDark01),
      ),
    );
  }

  static BoxDecoration get userLocationMarkerDecoration => BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.white,
    border: Border.all(color: AppColors.blueRibbon, width: 2),
    boxShadow: const [
      BoxShadow(
        color: AppColors.blueRibbon,
        blurRadius: 10,
        spreadRadius: 1,
        offset: Offset(0, 1),
      ),
    ],
  );

  // Add custom themes here in the future (if needed i.e high contrast, etc.)

}
