import 'package:flutter/material.dart';
import '../cartoon_colors.dart';

/// Decorative Cartoon Background with Cream Canvas, Organic Blobs & Dots
class CartoonBackground extends StatelessWidget {
  final Widget child;
  final bool showBlobs;
  final bool showDots;
  final Color backgroundColor;

  const CartoonBackground({
    super.key,
    required this.child,
    this.showBlobs = true,
    this.showDots = true,
    this.backgroundColor = CartoonColors.canvas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showBlobs)
            IgnorePointer(
              child: Stack(
                children: [
                  // Top-Right Soft Purple Blob
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: const BoxDecoration(
                        color: CartoonColors.purpleSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Middle-Left Soft Yellow Blob
                  Positioned(
                    top: 260,
                    left: -60,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: const BoxDecoration(
                        color: CartoonColors.yellowSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Bottom-Right Soft Green Blob
                  Positioned(
                    bottom: -40,
                    right: -40,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: const BoxDecoration(
                        color: CartoonColors.greenSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Bottom-Left Soft Pink Blob
                  Positioned(
                    bottom: 120,
                    left: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        color: CartoonColors.pinkSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (showDots)
            IgnorePointer(
              child: CustomPaint(
                painter: _CartoonDotsPainter(),
                size: Size.infinite,
              ),
            ),

          // Content Layer
          child,
        ],
      ),
    );
  }
}

/// Subtle decorative pastel dots and starlets
class _CartoonDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = CartoonColors.ink.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Fixed scattered decorative dots across the canvas
    final dots = [
      Offset(size.width * 0.12, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.22),
      Offset(size.width * 0.90, size.height * 0.45),
      Offset(size.width * 0.08, size.height * 0.65),
      Offset(size.width * 0.82, size.height * 0.78),
      Offset(size.width * 0.25, size.height * 0.92),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
