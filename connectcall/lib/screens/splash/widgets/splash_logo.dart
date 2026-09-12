import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pixel-perfect emblem matching the ConnectCall splash screen:
/// An open circular arc framing a phone handset and three concentric call waves.
class SplashLogo extends StatelessWidget {
  const SplashLogo({
    super.key,
    this.size = 120,
    this.color = const Color(0xFFFF6E00),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _SplashLogoPainter(color: color),
      ),
    );
  }
}

class _SplashLogoPainter extends CustomPainter {
  const _SplashLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final scale = s / 120.0;

    final orangePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5 * scale
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Outer circular arc
    // Center at (52, 64) with radius ~46 in 120x120 space
    final arcCenter = Offset(52 * scale, 64 * scale);
    final arcRadius = 45 * scale;
    final arcRect = Rect.fromCircle(center: arcCenter, radius: arcRadius);

    // Arc sweeps clockwise from ~130° (2.27 rad) to ~355° (sweep angle of ~4.1 rad / 235°)
    const startAngle = 135 * math.pi / 180;
    const sweepAngle = 240 * math.pi / 180;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, orangePaint);

    // 2. Three concentric sound / call waves
    // Origin near the earpiece of the handset (approx at (62, 54))
    final waveCenter = Offset(58 * scale, 58 * scale);
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8 * scale
      ..strokeCap = StrokeCap.round;

    // Radii of the three waves: inner, middle, outer
    final waveRadii = [23.0 * scale, 34.0 * scale, 45.0 * scale];
    const waveStartAngle = -75 * math.pi / 180;
    const waveSweepAngle = 65 * math.pi / 180;

    for (final r in waveRadii) {
      final waveRect = Rect.fromCircle(center: waveCenter, radius: r);
      canvas.drawArc(waveRect, waveStartAngle, waveSweepAngle, false, wavePaint);
    }

    // 3. Handset icon in the center
    // Drawn via native vector icon or custom transformed handset path
    canvas.save();
    // Center of handset positioning
    canvas.translate(56 * scale, 68 * scale);
    // Tilted ~45 degrees
    canvas.rotate(-15 * math.pi / 180);

    final handsetPath = Path();
    // Modern stylized phone receiver
    // Top earpiece: bulb rounded at top-left
    // Center body: indented inner curve, smooth convex outer curve
    // Bottom mouthpiece: bulb rounded at bottom-left
    handsetPath.moveTo(-8 * scale, -22 * scale);
    handsetPath.cubicTo(
      -2 * scale,
      -24 * scale,
      8 * scale,
      -18 * scale,
      9 * scale,
      -10 * scale,
    );
    handsetPath.cubicTo(
      10 * scale,
      -3 * scale,
      5 * scale,
      2 * scale,
      -1 * scale,
      -1 * scale,
    );
    handsetPath.cubicTo(
      -6 * scale,
      -4 * scale,
      -8 * scale,
      -2 * scale,
      -10 * scale,
      3 * scale,
    );
    handsetPath.cubicTo(
      -12 * scale,
      8 * scale,
      -8 * scale,
      13 * scale,
      -3 * scale,
      16 * scale,
    );
    handsetPath.cubicTo(
      4 * scale,
      19 * scale,
      8 * scale,
      13 * scale,
      15 * scale,
      14 * scale,
    );
    handsetPath.cubicTo(
      22 * scale,
      15 * scale,
      25 * scale,
      24 * scale,
      20 * scale,
      29 * scale,
    );
    handsetPath.cubicTo(
      13 * scale,
      36 * scale,
      -5 * scale,
      30 * scale,
      -17 * scale,
      18 * scale,
    );
    handsetPath.cubicTo(
      -28 * scale,
      7 * scale,
      -31 * scale,
      -11 * scale,
      -22 * scale,
      -19 * scale,
    );
    handsetPath.cubicTo(
      -18 * scale,
      -23 * scale,
      -13 * scale,
      -22 * scale,
      -8 * scale,
      -22 * scale,
    );
    handsetPath.close();

    canvas.drawPath(handsetPath, fillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
