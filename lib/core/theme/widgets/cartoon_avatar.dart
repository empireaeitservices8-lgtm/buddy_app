import 'package:flutter/material.dart';
import '../cartoon_colors.dart';
import '../cartoon_dimensions.dart';
import '../cartoon_text_theme.dart';

enum CartoonAvatarStatus {
  none,
  online, // green dot
  offline, // gray dot
  busy, // red/pink dot
}

/// Cartoon Sticker Avatar with 3px Outline, Hard Shadow & Status Indicator
class CartoonAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final Widget? fallbackIcon;
  final double size;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Offset shadowOffset;
  final CartoonAvatarStatus status;
  final VoidCallback? onTap;

  const CartoonAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.fallbackIcon,
    this.size = 64.0,
    this.backgroundColor = CartoonColors.purpleSoft,
    this.borderColor = CartoonColors.ink,
    this.borderWidth = CartoonDimensions.borderWidth,
    this.shadowOffset = CartoonDimensions.smallShadowOffset,
    this.status = CartoonAvatarStatus.none,
    this.onTap,
  });

  Color get _statusColor {
    switch (status) {
      case CartoonAvatarStatus.online:
        return CartoonColors.success;
      case CartoonAvatarStatus.offline:
        return CartoonColors.textMuted;
      case CartoonAvatarStatus.busy:
        return CartoonColors.error;
      case CartoonAvatarStatus.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarBody = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: CartoonDimensions.shadow(offset: shadowOffset),
      ),
      child: ClipOval(
        child: _buildContent(),
      ),
    );

    if (status != CartoonAvatarStatus.none) {
      final dotSize = (size * 0.28).clamp(12.0, 22.0);
      avatarBody = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarBody,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: _statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CartoonColors.ink,
                  width: CartoonDimensions.borderWidthThin,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatarBody,
      );
    }

    return avatarBody;
  }

  Widget _buildContent() {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty && imageUrl!.startsWith('http')) {
      return Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    if (initials != null && initials!.trim().isNotEmpty) {
      final cleanInitials = initials!.trim();
      final letter = cleanInitials.isNotEmpty ? cleanInitials[0].toUpperCase() : 'G';
      return Center(
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: CartoonTextTheme.fontFamily,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w900,
            color: CartoonColors.ink,
          ),
        ),
      );
    }
    return fallbackIcon ??
        Center(
          child: Icon(
            Icons.person_rounded,
            size: size * 0.55,
            color: CartoonColors.ink,
          ),
        );
  }
}
