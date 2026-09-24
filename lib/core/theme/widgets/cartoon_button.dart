import 'package:flutter/material.dart';
import '../cartoon_colors.dart';
import '../cartoon_dimensions.dart';
import '../cartoon_text_theme.dart';

enum CartoonButtonVariant {
  primary, // Cartoon Purple #8B7CFF
  secondary, // Cartoon Yellow #FFD95A
  success, // Cartoon Green #9BE58A
  destructive, // Cartoon Pink #FF9FBC / Red #EF4444
  white, // White
  ink, // Dark Ink
}

/// Tactile Cartoon Button with 3px Outline, Hard Shadow & Micro-Press Animation
class CartoonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final CartoonButtonVariant variant;
  final Color? customColor;
  final Color? customTextColor;
  final Widget? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final double radius;
  final double borderWidth;
  final Offset shadowOffset;
  final EdgeInsetsGeometry? padding;

  const CartoonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CartoonButtonVariant.primary,
    this.customColor,
    this.customTextColor,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 54.0,
    this.radius = CartoonDimensions.buttonRadius,
    this.borderWidth = CartoonDimensions.borderWidth,
    this.shadowOffset = CartoonDimensions.defaultShadowOffset,
    this.padding,
  });

  @override
  State<CartoonButton> createState() => _CartoonButtonState();
}

class _CartoonButtonState extends State<CartoonButton> {
  bool _isPressed = false;

  Color get _backgroundColor {
    if (widget.customColor != null) return widget.customColor!;
    switch (widget.variant) {
      case CartoonButtonVariant.primary:
        return CartoonColors.primary;
      case CartoonButtonVariant.secondary:
        return CartoonColors.yellow;
      case CartoonButtonVariant.success:
        return CartoonColors.green;
      case CartoonButtonVariant.destructive:
        return CartoonColors.pink;
      case CartoonButtonVariant.white:
        return CartoonColors.white;
      case CartoonButtonVariant.ink:
        return CartoonColors.ink;
    }
  }

  Color get _textColor {
    if (widget.customTextColor != null) return widget.customTextColor!;
    switch (widget.variant) {
      case CartoonButtonVariant.primary:
      case CartoonButtonVariant.ink:
        return Colors.white;
      case CartoonButtonVariant.secondary:
      case CartoonButtonVariant.success:
      case CartoonButtonVariant.destructive:
      case CartoonButtonVariant.white:
        return CartoonColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveShadow = isEnabled && _isPressed
        ? CartoonDimensions.shadowSmall(offset: const Offset(1, 1))
        : CartoonDimensions.shadow(offset: widget.shadowOffset);

    final transformOffset = isEnabled && _isPressed
        ? Offset(widget.shadowOffset.dx - 1, widget.shadowOffset.dy - 1)
        : Offset.zero;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(transformOffset.dx, transformOffset.dy, 0),
        width: widget.width ?? double.infinity,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isEnabled ? _backgroundColor : _backgroundColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: CartoonColors.ink,
            width: widget.borderWidth,
          ),
          boxShadow: effectiveShadow,
        ),
        alignment: Alignment.center,
        child: widget.isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: CartoonTextTheme.button.copyWith(
                      color: _textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}
