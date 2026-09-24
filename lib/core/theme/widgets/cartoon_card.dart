import 'package:flutter/material.dart';
import '../cartoon_colors.dart';
import '../cartoon_dimensions.dart';

/// Cartoon Sticker Card with Thick Ink Outline & Hard Shadow
class CartoonCard extends StatefulWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final Offset shadowOffset;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const CartoonCard({
    super.key,
    required this.child,
    this.color = CartoonColors.white,
    this.borderColor = CartoonColors.ink,
    this.borderWidth = CartoonDimensions.borderWidth,
    this.radius = CartoonDimensions.cardRadius,
    this.shadowOffset = CartoonDimensions.defaultShadowOffset,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.onTap,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  State<CartoonCard> createState() => _CartoonCardState();
}

class _CartoonCardState extends State<CartoonCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = widget.onTap != null && _isPressed
        ? CartoonDimensions.shadowSmall(offset: const Offset(1, 1))
        : CartoonDimensions.shadow(offset: widget.shadowOffset);

    final transformOffset = widget.onTap != null && _isPressed
        ? Offset(widget.shadowOffset.dx - 1, widget.shadowOffset.dy - 1)
        : Offset.zero;

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: Matrix4.translationValues(transformOffset.dx, transformOffset.dy, 0),
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
        boxShadow: effectiveShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      cardContent = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }

    if (widget.margin != null) {
      return Padding(
        padding: widget.margin!,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
