import 'package:flutter/material.dart';
import '../cartoon_colors.dart';
import '../cartoon_dimensions.dart';
import '../cartoon_text_theme.dart';

/// Reusable Cartoon Pill Badge
class CartoonBadge extends StatelessWidget {
  final String text;
  final Widget? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Offset shadowOffset;

  const CartoonBadge({
    super.key,
    required this.text,
    this.icon,
    this.backgroundColor = CartoonColors.yellow,
    this.textColor = CartoonColors.ink,
    this.borderColor = CartoonColors.ink,
    this.borderWidth = CartoonDimensions.borderWidthThin,
    this.radius = CartoonDimensions.badgeRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.shadowOffset = CartoonDimensions.smallShadowOffset,
  });

  /// Factory: Verified Badge
  factory CartoonBadge.verified({String text = 'VERIFIED'}) {
    return CartoonBadge(
      text: text,
      icon: const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0284C7)),
      backgroundColor: CartoonColors.blueSoft,
      textColor: CartoonColors.ink,
    );
  }

  /// Factory: PRO Badge
  factory CartoonBadge.pro({String text = 'PRO'}) {
    return CartoonBadge(
      text: text,
      backgroundColor: CartoonColors.purpleSoft,
      textColor: CartoonColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    );
  }

  /// Factory: Rating Badge
  factory CartoonBadge.rating(double rating) {
    return CartoonBadge(
      text: rating > 0 ? rating.toStringAsFixed(1) : '5.0',
      icon: const Icon(Icons.star_rounded, size: 16, color: CartoonColors.warning),
      backgroundColor: CartoonColors.yellowSoft,
      textColor: CartoonColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  /// Factory: Agent Badge
  factory CartoonBadge.agent({String text = 'AGENT'}) {
    return CartoonBadge(
      text: text,
      backgroundColor: CartoonColors.yellow,
      textColor: CartoonColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: CartoonDimensions.shadowSmall(offset: shadowOffset),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: CartoonTextTheme.badge.copyWith(
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
