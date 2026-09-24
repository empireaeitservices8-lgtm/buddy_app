import 'package:flutter/material.dart';
import 'cartoon_colors.dart';

/// Cartoon Design System Dimensions, Borders & Hard Shadow Utilities
class CartoonDimensions {
  CartoonDimensions._();

  // Outlines & Borders (2px – 3px)
  static const double borderWidthThin = 2.0;
  static const double borderWidth = 3.0; // Main component border
  static const double borderWidthThick = 3.5;

  // Corner Radii
  static const double radiusSmall = 12.0;
  static const double badgeRadius = 14.0;
  static const double inputRadius = 20.0;
  static const double buttonRadius = 20.0;
  static const double cardRadius = 24.0;
  static const double navBarRadius = 30.0;
  static const double bottomSheetRadius = 36.0;

  // Hard Shadows (Sharp, unblurred, no glassmorphism)
  static const Offset defaultShadowOffset = Offset(3, 4);
  static const Offset smallShadowOffset = Offset(2, 2.5);
  static const Offset largeShadowOffset = Offset(4, 5);

  /// Hard Cartoon Shadows (Solid unblurred ink offset)
  static List<BoxShadow> shadow({
    Offset offset = defaultShadowOffset,
    Color color = CartoonColors.ink,
  }) {
    return [
      BoxShadow(
        color: color,
        offset: offset,
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }

  /// Small Hard Cartoon Shadow (For chips, tags, pills)
  static List<BoxShadow> shadowSmall({
    Offset offset = smallShadowOffset,
    Color color = CartoonColors.ink,
  }) {
    return [
      BoxShadow(
        color: color,
        offset: offset,
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }

  /// Solid Ink Border
  static Border border({
    double width = borderWidth,
    Color color = CartoonColors.ink,
  }) {
    return Border.all(color: color, width: width);
  }

  /// Standard Box Decoration for Cartoon Stickers and Cards
  static BoxDecoration cardDecoration({
    Color color = CartoonColors.white,
    double radius = cardRadius,
    double borderWidth = borderWidth,
    Color borderColor = CartoonColors.ink,
    Offset shadowOffset = defaultShadowOffset,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return BoxDecoration(
      color: color,
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: shadow(offset: shadowOffset),
    );
  }

  /// Standard Box Decoration for Cartoon Pills & Badges
  static BoxDecoration pillDecoration({
    Color color = CartoonColors.yellow,
    double radius = badgeRadius,
    double borderWidth = borderWidthThin,
    Color borderColor = CartoonColors.ink,
    Offset shadowOffset = smallShadowOffset,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: shadowSmall(offset: shadowOffset),
    );
  }
}
