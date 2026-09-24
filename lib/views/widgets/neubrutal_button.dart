import 'package:flutter/material.dart';
import '../../core/theme/cartoon_theme.dart';

/// NeubrutalButton:
/// - 3px solid #1E2022 Charcoal border
/// - Unblurred 4px solid drop shadow with tactile press state
/// - 20px default corner radius
/// - Retains all callbacks and loading indicators
class NeubrutalButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final Widget? leadingWidget;
  final Color backgroundColor;
  final Color textColor;
  final Color iconBadgeColor;
  final double height;
  final double? width;
  final double borderRadius;
  final double borderWidth;
  final Offset shadowOffset;
  final double fontSize;

  const NeubrutalButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.leadingWidget,
    this.backgroundColor = CartoonColors.charcoal,
    this.textColor = Colors.white,
    this.iconBadgeColor = CartoonColors.lime,
    this.height = 58.0,
    this.width = double.infinity,
    this.borderRadius = CartoonTheme.buttonRadius,
    this.borderWidth = CartoonTheme.borderWidth,
    this.shadowOffset = const Offset(4, 4),
    this.fontSize = 16.0,
  });

  @override
  State<NeubrutalButton> createState() => _NeubrutalButtonState();
}

class _NeubrutalButtonState extends State<NeubrutalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final currentOffset = _isPressed
        ? const Offset(1, 1)
        : widget.shadowOffset;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(
          _isPressed ? 3.0 : 0.0,
          _isPressed ? 3.0 : 0.0,
          0.0,
        ),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isEnabled ? widget.backgroundColor : widget.backgroundColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: CartoonColors.charcoal,
            width: widget.borderWidth,
          ),
          boxShadow: isEnabled
              ? CartoonTheme.shadow(offset: currentOffset)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.leadingWidget != null)
              Positioned(
                left: 8,
                child: widget.leadingWidget!,
              )
            else if (widget.leadingIcon != null && !widget.isLoading)
              Positioned(
                left: 8,
                child: Container(
                  width: widget.height - 18,
                  height: widget.height - 18,
                  decoration: BoxDecoration(
                    color: widget.iconBadgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CartoonColors.charcoal,
                      width: 2.0,
                    ),
                  ),
                  child: Icon(
                    widget.leadingIcon,
                    color: CartoonColors.charcoal,
                    size: 20,
                  ),
                ),
              ),
            if (widget.isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(CartoonColors.lime),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: widget.fontSize,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
