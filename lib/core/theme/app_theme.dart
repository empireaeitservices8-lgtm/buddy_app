import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static const double strokeWidth = 2.0;
  static const double borderRadiusLarge = 28.0;
  static const double borderRadiusMedium = 20.0;
  static const double borderRadiusSmall = 14.0;

  static List<BoxShadow> neoShadow({
    Offset offset = const Offset(3.5, 3.5),
    Color color = AppColors.strokeBlack,
  }) {
    return [
      BoxShadow(
        color: color,
        offset: offset,
        blurRadius: 0, // Hard shadow, no blur
        spreadRadius: 0,
      ),
    ];
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.strokeBlack,
      fontFamily: AppTypography.fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.strokeBlack,
        secondary: AppColors.accentLavender,
        surface: AppColors.cardWhite,
        error: AppColors.errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.strokeBlack, size: 24),
        titleTextStyle: AppTypography.headlineMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(
          color: AppColors.textPlaceholder,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: AppColors.strokeBlack, width: strokeWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: AppColors.strokeBlack, width: strokeWidth + 0.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: AppColors.errorRed, width: strokeWidth),
        ),
      ),
    );
  }
}
