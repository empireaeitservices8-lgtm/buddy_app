import 'dart:math' as math;
import 'package:flutter/material.dart';

class SparklePainter extends CustomPainter {
  final Color color;

  SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;

    // 4-pointed sparkle star with curved arcs
    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy, w, cy);
    path.quadraticBezierTo(cx, cy, cx, h);
    path.quadraticBezierTo(cx, cy, 0, cy);
    path.quadraticBezierTo(cx, cy, cx, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) => oldDelegate.color != color;
}

class SparkleWidget extends StatelessWidget {
  final double size;
  final Color color;
  final double angle;

  const SparkleWidget({
    super.key,
    this.size = 24.0,
    this.color = Colors.black,
    this.angle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * (math.pi / 180),
      child: CustomPaint(
        size: Size(size, size),
        painter: SparklePainter(color: color),
      ),
    );
  }
}
