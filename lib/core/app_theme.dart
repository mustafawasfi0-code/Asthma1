import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- Brand palette (exact HEX codes) ---
  static const darkGreen = Color(0xFF1C3A36); // #1c3a36
  static const green = Color(0xFF007359); // #007359
  static const brightGreen = Color(0xFF03F694); // #03f694
  static const oceanBlue = Color(0xFF69D4D1); // #69d4d1
  static const white = Color(0xFFFFFFFF); // #ffffff
  static const grey = Color(0xFFE3E0E3); // #e3e0e3
  static const black = Color(0xFF000D0D); // #000d0d

  // --- Legacy aliases ---
  static const blue = green;
  static const teal = oceanBlue;
  static const pink = Color(0xFFDB2777);

  // --- Soft tints derived from the palette (for icon tiles / highlights) ---
  static const softGreen = Color(0xFFE6F4F0);
  static const softOcean = Color(0xFFE5F7F6);

  // --- Semantic roles ---
  static const background = Color(0xFFF5F8F7);
  static const text = darkGreen;
  static const heading = black;
  static const muted = Color(0xFF5B6D69);
  static const border = grey;
  static const success = brightGreen;
}

/// Brand gradients (Green -> Bright Green), used for main buttons and
/// active elements.
abstract final class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.green, AppColors.brightGreen],
  );

  /// Soft mint wash used for hero / header cards.
  static const mint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9F5EA), Color(0xFFF1FBF7)],
  );
}

/// Soft floating-card shadows.
abstract final class AppShadows {
  static const soft = [
    BoxShadow(
      color: Color(0x141C3A36),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A1C3A36),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const button = [
    BoxShadow(
      color: Color(0x40007359),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'SegoeUI',
  scaffoldBackgroundColor: AppColors.background,
  dividerColor: AppColors.grey,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    onPrimary: AppColors.white,
    secondary: AppColors.oceanBlue,
    tertiary: AppColors.brightGreen,
    surface: AppColors.white,
    onSurface: AppColors.black,
    surfaceTint: Colors.transparent,
    outline: AppColors.grey,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.black,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.darkGreen),
    titleTextStyle: TextStyle(
      color: AppColors.black,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: AppColors.black,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: AppColors.black,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.black,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.black,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkGreen, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkGreen, height: 1.45),
  ),
  cardTheme: CardThemeData(
    color: AppColors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.green,
      foregroundColor: AppColors.white,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.green,
      side: const BorderSide(color: AppColors.green, width: 1.4),
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.white,
    selectedColor: AppColors.softGreen,
    checkmarkColor: AppColors.green,
    side: const BorderSide(color: AppColors.grey),
    labelStyle: const TextStyle(
      color: AppColors.darkGreen,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.darkGreen,
    contentTextStyle: const TextStyle(color: AppColors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  iconTheme: const IconThemeData(color: AppColors.green),
  sliderTheme: const SliderThemeData(
    activeTrackColor: AppColors.green,
    thumbColor: AppColors.green,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.green,
    linearTrackColor: AppColors.grey,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.white
          : AppColors.white,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.green
          : AppColors.grey,
    ),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  ),
  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.green, width: 1.6),
    ),
  ),
);