import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MascotPose {
  phoneCall,
  envelopeThumbsUp,
}

/// Rich vector-rendered Gabby Mascot matching the exact brand spec:
/// - Light blue rounded speech-bubble body with tail & rosy cheeks
/// - Big cheerful expressive eyes with dual catchlights & happy smile
/// - Variant [phoneCall]: Holding retro green phone receiver with curly cord & musical notes
/// - Variant [envelopeThumbsUp]: Giving thumbs-up 👍 & holding envelope ✉️ with stars & sparkles
class GabbyMascotWidget extends StatefulWidget {
  final MascotPose pose;
  final double size;
  final bool animate;

  const GabbyMascotWidget({
    super.key,
    this.pose = MascotPose.phoneCall,
    this.size = 200,
    this.animate = true,
  });

  @override
  State<GabbyMascotWidget> createState() => _GabbyMascotWidgetState();
}

class _GabbyMascotWidgetState extends State<GabbyMascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _GabbyMascotPainter(pose: widget.pose, progress: 0.0),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = math.sin(_controller.value * math.pi) * 6.0;
        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _GabbyMascotPainter(
                pose: widget.pose,
                progress: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GabbyMascotPainter extends CustomPainter {
  final MascotPose pose;
  final double progress;

  _GabbyMascotPainter({required this.pose, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = math.min(w, h) / 200.0;

    canvas.save();
    canvas.scale(s, s);

    // Center pivot: (100, 100)
    _drawSurroundingAccents(canvas);
    _drawBody(canvas);
    _drawFace(canvas);

    if (pose == MascotPose.phoneCall) {
      _drawPhoneReceiver(canvas);
    } else {
      _drawEnvelopeAndHands(canvas);
    }

    canvas.restore();
  }

  void _drawSurroundingAccents(Canvas canvas) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (pose == MascotPose.phoneCall) {
      // 1. Musical Notes (Top right)
      _drawMusicNote(canvas, 168, 55, const Color(0xFF38BDF8), 1.1);
      _drawMusicNote(canvas, 185, 80, const Color(0xFF818CF8), 0.85);

      // 2. Pink Hearts
      _drawHeart(canvas, 25, 60, 14, const Color(0xFFFF6B81));
      _drawHeart(canvas, 175, 120, 10, const Color(0xFFFF8FA3));

      // 3. Colorful Confetti Streamers (Right side)
      final streamerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;

      // Streamer 1: Coral
      streamerPaint.color = const Color(0xFFFF7E67);
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(175, 65), radius: 16),
        0.2,
        1.2,
        false,
        streamerPaint,
      );

      // Streamer 2: Gold/Yellow
      streamerPaint.color = const Color(0xFFFBBF24);
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(178, 80), radius: 18),
        0.3,
        1.3,
        false,
        streamerPaint,
      );

      // Streamer 3: Mint/Lime
      streamerPaint.color = const Color(0xFF34D399);
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(174, 98), radius: 16),
        0.1,
        1.1,
        false,
        streamerPaint,
      );
    } else {
      // Envelope & Thumbs up mode: Stars & Sparkles
      _drawStar(canvas, 30, 48, 12, const Color(0xFFFBBF24));
      _drawStar(canvas, 170, 45, 14, const Color(0xFFFBBF24));
      _drawSparkle(canvas, 25, 95, 10, const Color(0xFF38BDF8));
      _drawSparkle(canvas, 178, 115, 12, const Color(0xFFFF7E67));
      _drawHeart(canvas, 42, 130, 11, const Color(0xFFFF6B81));
    }
  }

  void _drawBody(Canvas canvas) {
    // Speech Bubble Main Body with Tail on Bottom-Right
    final bodyPath = Path();
    
    // Rounded circle base centered at (100, 100), radius ~ 62
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(38, 38, 124, 124),
      const Radius.circular(62),
    );

    bodyPath.addRRect(rect);

    // Add Speech Bubble Tail at bottom right (140, 145) to (155, 168)
    final tailPath = Path()
      ..moveTo(125, 148)
      ..quadraticBezierTo(145, 162, 154, 166)
      ..quadraticBezierTo(145, 145, 142, 132)
      ..close();

    // Body Fill (Bright vibrant cyan-blue bubble)
    final bodyFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
      ).createShader(const Rect.fromLTWH(38, 38, 130, 130))
      ..style = PaintingStyle.fill;

    // Hard Neo drop shadow behind mascot
    final shadowPaint = Paint()
      ..color = const Color(0x331E293B)
      ..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.translate(4, 4);
    canvas.drawPath(bodyPath, shadowPaint);
    canvas.drawPath(tailPath, shadowPaint);
    canvas.restore();

    // Draw main body
    canvas.drawPath(bodyPath, bodyFill);
    canvas.drawPath(tailPath, bodyFill);

    // Subtle highlight on top of head
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(65, 46, 70, 20), highlightPaint);

    // Stroke outline
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bodyPath, strokePaint);
    canvas.drawPath(tailPath, strokePaint);
  }

  void _drawFace(Canvas canvas) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // 1. Eyebrows (Cute arched lines)
    final browPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Left eyebrow
    canvas.drawArc(
      const Rect.fromLTWH(70, 72, 16, 12),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      browPaint,
    );
    // Right eyebrow
    canvas.drawArc(
      const Rect.fromLTWH(114, 72, 16, 12),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      browPaint,
    );

    // 2. Big Cute Eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    // Left Eye
    canvas.drawOval(const Rect.fromLTWH(73, 84, 15, 20), eyePaint);
    // Right Eye
    canvas.drawOval(const Rect.fromLTWH(112, 84, 15, 20), eyePaint);

    // Eye Catchlights (White dots)
    final catchlight = Paint()..color = Colors.white;
    // Left eye catchlights
    canvas.drawCircle(const Offset(78, 89), 4.2, catchlight);
    canvas.drawCircle(const Offset(83, 97), 2.2, catchlight);
    // Right eye catchlights
    canvas.drawCircle(const Offset(117, 89), 4.2, catchlight);
    canvas.drawCircle(const Offset(122, 97), 2.2, catchlight);

    // 3. Pink Blushing Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF8FA3).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(58, 102, 16, 10), cheekPaint);
    canvas.drawOval(const Rect.fromLTWH(126, 102, 16, 10), cheekPaint);

    // 4. Cheerful Open Smile with Tongue
    final mouthPath = Path();
    mouthPath.moveTo(88, 104);
    mouthPath.quadraticBezierTo(100, 124, 112, 104);
    mouthPath.close();

    // Mouth interior (Dark maroon)
    final mouthFill = Paint()..color = const Color(0xFF881337);
    canvas.drawPath(mouthPath, mouthFill);

    // Tongue (Pastel coral pink)
    canvas.save();
    canvas.clipPath(mouthPath);
    final tonguePaint = Paint()..color = const Color(0xFFFB7185);
    canvas.drawCircle(const Offset(100, 118), 9, tonguePaint);
    canvas.restore();

    // Mouth outline
    canvas.drawPath(mouthPath, strokePaint);
  }

  void _drawPhoneReceiver(Canvas canvas) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final phoneFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
      ).createShader(const Rect.fromLTWH(20, 50, 60, 90))
      ..style = PaintingStyle.fill;

    // Coiled Phone Cord at bottom
    final cordPath = Path();
    cordPath.moveTo(48, 135);
    cordPath.cubicTo(40, 148, 55, 155, 45, 162);
    cordPath.cubicTo(35, 168, 52, 175, 42, 180);

    final cordPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(cordPath, cordPaint);
    canvas.drawPath(
      cordPath,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Cute retro phone handset tilted beside head
    canvas.save();
    canvas.translate(44, 98);
    canvas.rotate(-0.35);

    // Receiver handle body
    final handsetPath = Path();
    // Top earpiece bulb
    handsetPath.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -42, 32, 24),
        const Radius.circular(12),
      ),
    );
    // Center handle grip
    handsetPath.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -22, 20, 44),
        const Radius.circular(8),
      ),
    );
    // Bottom mouthpiece bulb
    handsetPath.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, 18, 32, 24),
        const Radius.circular(12),
      ),
    );

    // Handset Shadow & Fill
    canvas.drawPath(handsetPath, phoneFill);
    canvas.drawPath(handsetPath, strokePaint);

    // Receiver Sound Holes / Grille on earpiece & mouthpiece
    final holePaint = Paint()..color = const Color(0xFF065F46);
    canvas.drawCircle(const Offset(0, -30), 2.2, holePaint);
    canvas.drawCircle(const Offset(-6, -30), 1.8, holePaint);
    canvas.drawCircle(const Offset(6, -30), 1.8, holePaint);

    canvas.drawCircle(const Offset(0, 30), 2.2, holePaint);
    canvas.drawCircle(const Offset(-6, 30), 1.8, holePaint);
    canvas.drawCircle(const Offset(6, 30), 1.8, holePaint);

    canvas.restore();

    // Cute cartoon little blue hand holding the middle handle
    final handPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(38, 92, 18, 16), handPaint);
    canvas.drawOval(
      const Rect.fromLTWH(38, 92, 18, 16),
      strokePaint..strokeWidth = 2.4,
    );
  }

  void _drawEnvelopeAndHands(Canvas canvas) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final handFill = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.fill;

    // 1. Left Hand: Thumbs Up 👍
    final leftArm = Path();
    leftArm.moveTo(42, 105);
    leftArm.quadraticBezierTo(28, 105, 24, 96);
    leftArm.quadraticBezierTo(22, 90, 26, 84); // Thumb tip
    leftArm.quadraticBezierTo(32, 84, 34, 94);
    leftArm.quadraticBezierTo(42, 98, 44, 106);
    leftArm.close();

    canvas.drawPath(leftArm, handFill);
    canvas.drawPath(leftArm, strokePaint);

    // 2. Right Hand: Holding Envelope ✉️
    canvas.save();
    canvas.translate(145, 96);
    canvas.rotate(0.2);

    // Envelope Body
    final envRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 38, 28),
      const Radius.circular(6),
    );
    final envFill = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawRRect(envRect, envFill);
    canvas.drawRRect(envRect, strokePaint);

    // Envelope Flap Lines
    final flapPath = Path()
      ..moveTo(0, 0)
      ..lineTo(19, 15)
      ..lineTo(38, 0);
    canvas.drawPath(flapPath, strokePaint);

    final bottomFold = Path()
      ..moveTo(0, 28)
      ..lineTo(14, 12)
      ..moveTo(38, 28)
      ..lineTo(24, 12);
    canvas.drawPath(bottomFold, strokePaint);

    // Red seal heart on envelope
    _drawHeart(canvas, 19, 13, 6, const Color(0xFFEF4444));

    // Right Hand Fingers holding envelope
    canvas.drawOval(const Rect.fromLTWH(-6, 8, 12, 14), handFill);
    canvas.drawOval(const Rect.fromLTWH(-6, 8, 12, 14), strokePaint);

    canvas.restore();
  }

  void _drawHeart(Canvas canvas, double x, double y, double size, Color color) {
    final heartPath = Path();
    final h = size;
    heartPath.moveTo(x, y + h * 0.3);
    heartPath.cubicTo(x, y, x - h * 0.5, y, x - h * 0.5, y + h * 0.35);
    heartPath.cubicTo(x - h * 0.5, y + h * 0.6, x, y + h * 0.85, x, y + h);
    heartPath.cubicTo(x, y + h * 0.85, x + h * 0.5, y + h * 0.6, x + h * 0.5, y + h * 0.35);
    heartPath.cubicTo(x + h * 0.5, y, x, y, x, y + h * 0.3);
    heartPath.close();

    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(heartPath, fill);
    canvas.drawPath(heartPath, stroke);
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Color color) {
    final path = Path();
    const points = 5;
    final innerR = r * 0.48;
    for (int i = 0; i < points * 2; i++) {
      final rad = (i * math.pi / points) - math.pi / 2;
      final curR = i.isEven ? r : innerR;
      final x = cx + curR * math.cos(rad);
      final y = cy + curR * math.sin(rad);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawSparkle(Canvas canvas, double cx, double cy, double r, Color color) {
    final path = Path();
    path.moveTo(cx, cy - r);
    path.quadraticBezierTo(cx, cy, cx + r, cy);
    path.quadraticBezierTo(cx, cy, cx, cy + r);
    path.quadraticBezierTo(cx, cy, cx - r, cy);
    path.quadraticBezierTo(cx, cy, cx, cy - r);
    path.close();

    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawMusicNote(
    Canvas canvas,
    double x,
    double y,
    Color color,
    double scale,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);

    final notePath = Path();
    // Oval head
    notePath.addOval(const Rect.fromLTWH(0, 8, 9, 7));
    // Stem
    notePath.addRect(const Rect.fromLTWH(7, 0, 2.4, 12));
    // Flag
    notePath.moveTo(9.4, 0);
    notePath.quadraticBezierTo(15, 3, 13, 8);

    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawPath(notePath, fill);
    canvas.drawPath(notePath, stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GabbyMascotPainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.progress != progress;
  }
}
