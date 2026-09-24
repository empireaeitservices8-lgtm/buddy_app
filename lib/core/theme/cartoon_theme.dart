import 'package:flutter/material.dart';
import 'cartoon_colors.dart';
import 'cartoon_dimensions.dart';
import 'cartoon_text_theme.dart';

export 'cartoon_colors.dart';
export 'cartoon_dimensions.dart';
export 'cartoon_text_theme.dart';
export 'widgets/cartoon_background.dart';
export 'widgets/cartoon_scaffold.dart';
export 'widgets/cartoon_card.dart';
export 'widgets/cartoon_button.dart';
export 'widgets/cartoon_text_field.dart';
export 'widgets/cartoon_badge.dart';
export 'widgets/cartoon_avatar.dart';
export 'widgets/cartoon_stat_card.dart';
export 'widgets/cartoon_bottom_nav.dart';

/// Cartoon Design System Main Theme Manager
class CartoonTheme {
  CartoonTheme._();

  // Re-export dimensions constants for quick access
  static const double borderWidth = CartoonDimensions.borderWidth;
  static const double cardRadius = CartoonDimensions.cardRadius;
  static const double buttonRadius = CartoonDimensions.buttonRadius;
  static const double badgeRadius = CartoonDimensions.badgeRadius;
  static const double navBarRadius = CartoonDimensions.navBarRadius;

  static List<BoxShadow> shadow({
    Offset offset = CartoonDimensions.defaultShadowOffset,
    Color color = CartoonColors.ink,
  }) =>
      CartoonDimensions.shadow(offset: offset, color: color);

  static List<BoxShadow> shadowSmall({
    Offset offset = CartoonDimensions.smallShadowOffset,
    Color color = CartoonColors.ink,
  }) =>
      CartoonDimensions.shadowSmall(offset: offset, color: color);

  static Border border({
    double width = CartoonDimensions.borderWidth,
    Color color = CartoonColors.ink,
  }) =>
      CartoonDimensions.border(width: width, color: color);

  static BoxDecoration cardDecoration({
    Color color = CartoonColors.white,
    double radius = CartoonDimensions.cardRadius,
    double borderWidth = CartoonDimensions.borderWidth,
    Color borderColor = CartoonColors.ink,
    Offset shadowOffset = CartoonDimensions.defaultShadowOffset,
    BoxShape shape = BoxShape.rectangle,
  }) =>
      CartoonDimensions.cardDecoration(
        color: color,
        radius: radius,
        borderWidth: borderWidth,
        borderColor: borderColor,
        shadowOffset: shadowOffset,
        shape: shape,
      );

  static BoxDecoration pillDecoration({
    Color color = CartoonColors.yellow,
    double radius = CartoonDimensions.badgeRadius,
    double borderWidth = CartoonDimensions.borderWidthThin,
    Color borderColor = CartoonColors.ink,
    Offset shadowOffset = CartoonDimensions.smallShadowOffset,
  }) =>
      CartoonDimensions.pillDecoration(
        color: color,
        radius: radius,
        borderWidth: borderWidth,
        borderColor: borderColor,
        shadowOffset: shadowOffset,
      );

  /// Primary Light Cartoon Theme
  static ThemeData cartoonLightTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: CartoonColors.canvas,
      primaryColor: CartoonColors.primary,
      fontFamily: CartoonTextTheme.fontFamily,
      textTheme: CartoonTextTheme.textTheme,
      colorScheme: const ColorScheme.light(
        primary: CartoonColors.primary,
        onPrimary: CartoonColors.white,
        secondary: CartoonColors.purpleSoft,
        onSecondary: CartoonColors.ink,
        surface: CartoonColors.white,
        onSurface: CartoonColors.ink,
        error: CartoonColors.error,
        onError: CartoonColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: CartoonColors.ink, size: 24),
        titleTextStyle: TextStyle(
          fontFamily: CartoonTextTheme.fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: CartoonColors.ink,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: CartoonColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CartoonDimensions.cardRadius),
          side: const BorderSide(
            color: CartoonColors.ink,
            width: CartoonDimensions.borderWidth,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CartoonColors.primary,
          foregroundColor: CartoonColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CartoonDimensions.buttonRadius),
            side: const BorderSide(
              color: CartoonColors.ink,
              width: CartoonDimensions.borderWidth,
            ),
          ),
          textStyle: CartoonTextTheme.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CartoonColors.ink,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CartoonDimensions.buttonRadius),
            side: const BorderSide(
              color: CartoonColors.ink,
              width: CartoonDimensions.borderWidth,
            ),
          ),
          textStyle: CartoonTextTheme.button.copyWith(color: CartoonColors.ink),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CartoonColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(
          fontFamily: CartoonTextTheme.fontFamily,
          color: CartoonColors.textPlaceholder,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          fontFamily: CartoonTextTheme.fontFamily,
          color: CartoonColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CartoonDimensions.inputRadius),
          borderSide: const BorderSide(
            color: CartoonColors.ink,
            width: CartoonDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CartoonDimensions.inputRadius),
          borderSide: const BorderSide(
            color: CartoonColors.primary,
            width: CartoonDimensions.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CartoonDimensions.inputRadius),
          borderSide: const BorderSide(
            color: CartoonColors.error,
            width: CartoonDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CartoonDimensions.inputRadius),
          borderSide: const BorderSide(
            color: CartoonColors.error,
            width: CartoonDimensions.borderWidthThick,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: CartoonColors.ink,
        thickness: 2,
        space: 24,
      ),
    );
  }

  /// Alias for backward compatibility
  static ThemeData get themeData => cartoonLightTheme();
}
