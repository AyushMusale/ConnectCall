import 'package:flutter/material.dart';

/// Custom painter that draws the organic, warm peach decorative background shapes
/// and subtle orange contour accent lines matching the ConnectCall splash screen.
class SplashBackgroundPainter extends CustomPainter {
  const SplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft top-left organic blob
    final topLeftBlobPaint = Paint()
      ..color = const Color(0xFFFFEAD9).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final topLeftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.46, 0)
      ..cubicTo(
        w * 0.42,
        h * 0.08,
        w * 0.32,
        h * 0.16,
        w * 0.18,
        h * 0.18,
      )
      ..cubicTo(
        w * 0.08,
        h * 0.19,
        0,
        h * 0.22,
        0,
        h * 0.26,
      )
      ..close();
    canvas.drawPath(topLeftPath, topLeftBlobPaint);

    // 2. Top-left subtle orange accent contour stroke
    final topLeftLinePaint = Paint()
      ..color = const Color(0xFFFF8A3D).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final topLeftLinePath = Path()
      ..moveTo(0, h * 0.16)
      ..cubicTo(
        w * 0.12,
        h * 0.14,
        w * 0.30,
        h * 0.10,
        w * 0.44,
        0,
      );
    canvas.drawPath(topLeftLinePath, topLeftLinePaint);

    // 3. Bottom-right soft organic blob (background layer)
    final brLayer1Paint = Paint()
      ..color = const Color(0xFFFFE8D6).withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;

    final brLayer1Path = Path()
      ..moveTo(w, h)
      ..lineTo(w * 0.38, h)
      ..cubicTo(
        w * 0.44,
        h * 0.88,
        w * 0.65,
        h * 0.82,
        w * 0.72,
        h * 0.72,
      )
      ..cubicTo(
        w * 0.78,
        h * 0.64,
        w * 0.90,
        h * 0.62,
        w,
        h * 0.66,
      )
      ..close();
    canvas.drawPath(brLayer1Path, brLayer1Paint);

    // 4. Bottom-right foreground warm peach blob
    final brLayer2Paint = Paint()
      ..color = const Color(0xFFFFDFC8).withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;

    final brLayer2Path = Path()
      ..moveTo(w, h)
      ..lineTo(w * 0.58, h)
      ..cubicTo(
        w * 0.64,
        h * 0.92,
        w * 0.76,
        h * 0.86,
        w * 0.80,
        h * 0.78,
      )
      ..cubicTo(
        w * 0.84,
        h * 0.70,
        w * 0.94,
        h * 0.71,
        w,
        h * 0.76,
      )
      ..close();
    canvas.drawPath(brLayer2Path, brLayer2Paint);

    // 5. Bottom-right subtle orange contour accent stroke
    final brLinePaint = Paint()
      ..color = const Color(0xFFFF8533).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final brLinePath = Path()
      ..moveTo(w * 0.32, h)
      ..cubicTo(
        w * 0.46,
        h * 0.92,
        w * 0.70,
        h * 0.87,
        w,
        h * 0.84,
      );
    canvas.drawPath(brLinePath, brLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
