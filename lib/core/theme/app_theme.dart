import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryGreen,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryGreen,
        secondary: AppColors.achievementGold,
        surface: AppColors.cardLight,
        error: AppColors.errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardLight,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textLight),
        bodyMedium: TextStyle(color: AppColors.textLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryGreen,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryGreen,
        secondary: AppColors.achievementGold,
        surface: AppColors.cardDark,
        error: AppColors.errorRed,
        onSurface: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
      ),
    );
  }
}
