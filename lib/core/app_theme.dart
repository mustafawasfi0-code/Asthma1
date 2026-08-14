import 'package:flutter/material.dart';

abstract final class AppColors {
  static const blue = Color(0xFF2563EB),
      teal = Color(0xFF0D9488),
      pink = Color(0xFFDB2777),
      background = Color(0xFFF9FAFB),
      text = Color(0xFF111827),
      muted = Color(0xFF6B7280),
      border = Color(0xFFE5E7EB);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'SegoeUI',
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
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
  ),
);
