import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto'; // System fallback default

  static const TextStyle brandLogo = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.textBlack,
    height: 1.1,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.8,
    color: AppColors.textBlack,
    height: 1.15,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textBlack,
    height: 1.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.textBlack,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textBlack,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.35,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textBlack,
    height: 1.3,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textBlack,
    height: 1.3,
  );

  static const TextStyle labelUppercase = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.8,
    color: AppColors.textBlack,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.6,
    color: AppColors.textBlack,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.buttonTextLight,
    letterSpacing: 0.2,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textBlack,
    decoration: TextDecoration.underline,
  );
}
