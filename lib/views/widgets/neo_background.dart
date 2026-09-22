import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'sparkle_widget.dart';

/// Signature neo-brutalist organic pastel background matching the reference mockups:
/// - Warm cream base canvas (#FBF8EE)
/// - Top-Right soft mint green circle (#C5EBAA)
/// - Middle-Left warm peach/sand circle (#F6E3BE)
/// - Bottom-Right pastel chartreuse circle (#D4F49C)
/// - Delicate floating sparkle accents (✦, ★)
class NeoBackground extends StatelessWidget {
  final Widget? child;

  const NeoBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBF8EE),
      child: Stack(
        children: [
          // 1. Top-Right Soft Mint Circle
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                color: Color(0xFFC5EBAA),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Middle-Left Warm Sandy Peach Organic Circle
          Positioned(
            top: 260,
            left: -85,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFFF6E3BE),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 3. Bottom-Right Pastel Mint/Chartreuse Circle
          Positioned(
            bottom: -50,
            right: -65,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                color: Color(0xFFD4F49C),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 4. Subtle Floating Sparkles matching mockup
          const Positioned(
            top: 75,
            left: 28,
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Positioned(
            top: 140,
            right: 40,
            child: Text(
              '★',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Positioned(
            bottom: 120,
            left: 36,
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            right: 120,
            child: Text(
              '★',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}
