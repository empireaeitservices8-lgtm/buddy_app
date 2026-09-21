import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable background widget providing the signature neo-brutalist organic pastel background:
/// - Base pastel lime canvas (#D7F688)
/// - Top-Right muted sage circle (#C3E2A0) extending around the wallet coin pill
/// - Middle-Left warm sandy peach circle (#E8D4AF)
/// - Bottom-Right subtle soft lime highlight (#CEF17D)
class NeoBackground extends StatelessWidget {
  final Widget? child;

  const NeoBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // 1. Top-Right Soft Sage Circle (Wraps around status bar and Coin badge)
          Positioned(
            top: -65,
            right: -60,
            child: Container(
              width: 270,
              height: 270,
              decoration: const BoxDecoration(
                color: Color(0xFFC3E2A0), // Soft sage pastel
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Middle-Left Warm Peach / Sand Organic Circle
          Positioned(
            top: 270,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                color: Color(0xFFE8D4AF), // Warm sandy peach
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 3. Bottom-Right Subtle Soft Lime Glow Circle
          Positioned(
            top: 500,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                color: Color(0xFFCEF17D), // Soft chartreuse accent
                shape: BoxShape.circle,
              ),
            ),
          ),

          ?child,
        ],
      ),
    );
  }
}
