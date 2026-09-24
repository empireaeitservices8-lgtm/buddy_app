import 'package:flutter/material.dart';
import '../cartoon_colors.dart';
import '../cartoon_dimensions.dart';
import '../cartoon_text_theme.dart';
import 'cartoon_card.dart';

/// Cartoon Stat / Metric Card
class CartoonStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Widget? icon;
  final String? emoji;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final String? subtitle;

  const CartoonStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.emoji,
    this.backgroundColor = CartoonColors.yellowSoft,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return CartoonCard(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (emoji != null)
                Text(
                  emoji!,
                  style: const TextStyle(fontSize: 26),
                )
              else if (icon != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CartoonColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CartoonColors.ink,
                      width: CartoonDimensions.borderWidthThin,
                    ),
                  ),
                  child: icon,
                ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: CartoonTextTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: CartoonColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: CartoonTextTheme.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: CartoonColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: CartoonTextTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: CartoonColors.ink,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
