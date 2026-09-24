import 'package:flutter/material.dart';
import 'cartoon_theme.dart';

class AppTheme {
  AppTheme._();

  static const double strokeWidth = CartoonDimensions.borderWidth;
  static const double borderRadiusLarge = CartoonDimensions.cardRadius;
  static const double borderRadiusMedium = CartoonDimensions.buttonRadius;
  static const double borderRadiusSmall = CartoonDimensions.badgeRadius;

  static List<BoxShadow> neoShadow({
    Offset offset = CartoonDimensions.defaultShadowOffset,
    Color color = CartoonColors.ink,
  }) {
    return CartoonDimensions.shadow(offset: offset, color: color);
  }

  static ThemeData get lightTheme => CartoonTheme.cartoonLightTheme();
}
