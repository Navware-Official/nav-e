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
        surface: AppColors.lightGray,
        onSurface: AppColors.capeCodDark01,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        color: AppColors.blueRibbonDark02,
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
        bodyLarge: TextStyle(color: AppColors.capeCodDark01),
        bodyMedium: TextStyle(color: AppColors.capeCodLight02),
        titleLarge: TextStyle(
          color: AppColors.blueRibbonDark04,
          fontWeight: FontWeight.bold,
        ),
        labelLarge: TextStyle(color: AppColors.blueRibbon),
      ),
      cardColor: AppColors.lightGray,
      dividerColor: AppColors.capeCodLight02,
      iconTheme: const IconThemeData(color: AppColors.blueRibbonDark04),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGray,
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.blueRibbon),
        ),
        labelStyle: TextStyle(color: AppColors.blueRibbonDark04),
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
        background: AppColors.capeCodDark02,
        onBackground: AppColors.white,
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
        labelStyle: TextStyle(color: AppColors.lightGray),
      ),
    );
  }
 
  // Add custom themes here in the future (if needed i.e high contrast, etc.)

}
