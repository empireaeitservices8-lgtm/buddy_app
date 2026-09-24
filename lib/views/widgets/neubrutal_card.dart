import 'package:flutter/material.dart';
import '../../core/theme/cartoon_theme.dart';

/// NeubrutalCard:
/// - 3px solid #1E2022 Charcoal border
/// - Unblurred 4px solid offset drop shadow
/// - 24px default corner radius
/// - Configurable background colors (Lavender, Lime, Yellow, Pink, Beige, White)
class NeubrutalCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool hasShadow;
  final Offset shadowOffset;
  final double? width;
  final double? height;

  const NeubrutalCard({
    super.key,
    required this.child,
    this.backgroundColor = CartoonColors.cardWhite,
    this.onTap,
    this.borderRadius = CartoonTheme.cardRadius,
    this.borderWidth = CartoonTheme.borderWidth,
    this.padding,
    this.margin,
    this.hasShadow = true,
    this.shadowOffset = const Offset(4, 4),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: CartoonColors.charcoal,
          width: borderWidth,
        ),
        boxShadow: hasShadow
            ? CartoonTheme.shadow(offset: shadowOffset)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}
