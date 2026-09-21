import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool hasShadow;
  final Offset shadowOffset;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.cardWhite,
    this.onTap,
    this.borderRadius = AppTheme.borderRadiusLarge,
    this.padding,
    this.hasShadow = true,
    this.shadowOffset = const Offset(3.5, 3.5),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.strokeBlack,
            width: AppTheme.strokeWidth + 0.5,
          ),
          boxShadow: hasShadow
              ? AppTheme.neoShadow(offset: shadowOffset)
              : null,
        ),
        child: child,
      ),
    );
  }
}
