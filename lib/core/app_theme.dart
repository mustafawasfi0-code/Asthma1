import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- Brand palette ---
  static const darkGreen = Color(0xFF1C3A36);
  static const green = Color(0xFF007359);
  static const brightGreen = Color(0xFF03F694);
  static const oceanBlue = Color(0xFF69D4D1);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFFE3E0E3);
  static const black = Color(0xFF000D0D);

  // --- Legacy aliases ---
  static const blue = green; 
  static const teal = oceanBlue; 
  static const pink = Color(0xFFDB2777); 

  // --- Semantic roles ---
  static const background = Color(0xFFF6FAF8); 
  static const text = darkGreen;
  static const muted = Color(0xFF5B6D69);
  static const border = grey;
  static const success = brightGreen;
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'SegoeUI',
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    secondary: AppColors.oceanBlue,
    tertiary: AppColors.brightGreen,
    surface: AppColors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.darkGreen,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.darkGreen),
    titleTextStyle: TextStyle(
      color: AppColors.darkGreen,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.45),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.green,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.green,
      side: const BorderSide(color: AppColors.green),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: AppColors.green),
  ),
  iconTheme: const IconThemeData(color: AppColors.green),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.green,
    linearTrackColor: AppColors.grey,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.green
          : AppColors.grey,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.oceanBlue.withValues(alpha: .55)
          : AppColors.grey,
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.green
          : Colors.transparent,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
    ),
  ),
);