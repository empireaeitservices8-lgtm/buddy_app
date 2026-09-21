import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';

class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final Color backgroundColor;
  final Color textColor;
  final Color iconBadgeColor;
  final double height;
  final double? width;

  const NeoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon = Icons.phone,
    this.backgroundColor = AppColors.buttonDark,
    this.textColor = AppColors.buttonTextLight,
    this.iconBadgeColor = AppColors.accentLavender,
    this.height = 62.0,
    this.width = double.infinity,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: AppColors.strokeBlack,
              width: AppTheme.strokeWidth,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.leadingIcon != null && !widget.isLoading)
                Positioned(
                  left: 6,
                  child: Container(
                    width: widget.height - 12,
                    height: widget.height - 12,
                    decoration: BoxDecoration(
                      color: widget.iconBadgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.strokeBlack,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.leadingIcon,
                      color: AppColors.strokeBlack,
                      size: 22,
                    ),
                  ),
                ),
              if (widget.isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentLavender),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56.0),
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: AppTypography.buttonText.copyWith(
                      color: widget.textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
