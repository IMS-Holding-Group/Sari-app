import 'package:flutter/material.dart';

class AppColors {
  static const Color darkBg = Color(0xFF0B1F3A);
  static const Color darkSurface = Color(0xFF07152B);
  static const Color cardBg = Color(0xFF102847);
  static const Color cardBorder = Color(0xFF1E3A66);

  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color primaryGlow = Color(0xFF3385FF);

  static const Color safeGreen = Color(0xFF22C55E);
  static const Color safeGreenGlow = Color(0xFF4ADE80);

  static const Color warningOrange = Color(0xFFFF9800);
  static const Color warningGlow = Color(0xFFFFB74D);

  static const Color dangerRed = Color(0xFFE53935);
  static const Color dangerGlow = Color(0xFFEF5350);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const Color gridLine = Color(0xFF1E293B);
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        surface: AppColors.darkSurface,
        error: AppColors.dangerRed,
        onSurface: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      fontFamily: 'Outfit',
      textTheme: baseTextTheme.apply(
        fontFamily: 'Outfit',
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }
}
