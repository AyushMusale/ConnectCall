import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative hero illustration for auth screens matching the ConnectCall design:
/// - Flying orange paper airplane with dashed contrail
/// - Floating orange chat bubble with telephone handset
/// - Floating cream chat bubble with three dots
/// - Heart badge pill
/// - Ambient sparkles and bokeh dots
class AuthIllustration extends StatelessWidget {
  const AuthIllustration({
    super.key,
    this.size = 220,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    // Scale factor relative to baseline design 240px
    final scale = size / 240.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background soft ambient glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFEDD5).withValues(alpha: 0.65),
                    const Color(0xFFFFF7ED).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Custom painted dotted curves and sparkles
          Positioned.fill(
            child: CustomPaint(
              painter: _DottedTrailPainter(scale: scale),
            ),
          ),

          // 1. Paper Airplane at top right
          Positioned(
            top: 6 * scale,
            right: 14 * scale,
            child: Transform.rotate(
              angle: -15 * math.pi / 180,
              child: SizedBox(
                width: 44 * scale,
                height: 44 * scale,
                child: CustomPaint(
                  painter: _PaperPlanePainter(),
                ),
              ),
            ),
          ),

          // 2. Large Orange Speech Bubble with Phone
          Positioned(
            top: 42 * scale,
            right: 32 * scale,
            child: Container(
              width: 86 * scale,
              height: 72 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6E00),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28 * scale),
                  topRight: Radius.circular(28 * scale),
                  bottomRight: Radius.circular(28 * scale),
                  bottomLeft: Radius.circular(6 * scale),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6E00).withValues(alpha: 0.35),
                    blurRadius: 18 * scale,
                    offset: Offset(0, 8 * scale),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.phone_rounded,
                  size: 34 * scale,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // 3. Overlapping Light Peach/Cream Bubble with 3 dots
          Positioned(
            top: 86 * scale,
            right: 10 * scale,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 14 * scale,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24 * scale),
                  topRight: Radius.circular(24 * scale),
                  bottomRight: Radius.circular(8 * scale),
                  bottomLeft: Radius.circular(24 * scale),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.12),
                    blurRadius: 12 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(scale),
                  SizedBox(width: 4 * scale),
                  _dot(scale),
                  SizedBox(width: 4 * scale),
                  _dot(scale),
                ],
              ),
            ),
          ),

          // 4. Heart Badge pill below
          Positioned(
            bottom: 22 * scale,
            left: 54 * scale,
            child: Container(
              width: 38 * scale,
              height: 38 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.5 * scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.14),
                    blurRadius: 10 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.favorite_rounded,
                  size: 19 * scale,
                  color: const Color(0xFFFF6E00),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(double scale) {
    return Container(
      width: 7 * scale,
      height: 7 * scale,
      decoration: const BoxDecoration(
        color: Color(0xFFFF6E00),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Paints the curved dashed connection trails, sparkles, and ambient dots
class _DottedTrailPainter extends CustomPainter {
  const _DottedTrailPainter({required this.scale});

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = const Color(0xFFFDBA74).withValues(alpha: 0.8)
      ..strokeWidth = 1.6 * scale
      ..style = PaintingStyle.stroke;

    // Trail path 1: From heart badge curving upwards around bubbles to the airplane
    final path = Path();
    path.moveTo(70 * scale, size.height - 40 * scale);
    path.cubicTo(
      20 * scale,
      size.height - 90 * scale,
      40 * scale,
      80 * scale,
      140 * scale,
      70 * scale,
    );
    path.cubicTo(
      180 * scale,
      65 * scale,
      190 * scale,
      40 * scale,
      size.width - 26 * scale,
      28 * scale,
    );

    _drawDashedPath(canvas, path, dashPaint, 4 * scale, 4 * scale);

    // Ambient floating circular dots
    final dotPaint = Paint()
      ..color = const Color(0xFFFDBA74).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.25),
      3.2 * scale,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.94, size.height * 0.38),
      2.8 * scale,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.78),
      3.0 * scale,
      dotPaint,
    );

    // Ambient 4-point sparkle
    _drawSparkle(
      canvas,
      Offset(size.width * 0.86, size.height * 0.48),
      8 * scale,
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius) {
    final sparklePaint = Paint()
      ..color = const Color(0xFFFDBA74).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(
        center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(
        center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(
        center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(
        center.dx, center.dy, center.dx, center.dy - radius);
    canvas.drawPath(path, sparklePaint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint,
    double dashLength,
    double dashSpace,
  ) {
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashLength, metric.length - distance);
        final segment = metric.extractPath(distance, distance + length);
        canvas.drawPath(segment, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedTrailPainter oldDelegate) =>
      oldDelegate.scale != scale;
}

/// Paints the sleek origami paper plane
class _PaperPlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body paint (lighter orange)
    final mainPaint = Paint()
      ..color = const Color(0xFFFF851B)
      ..style = PaintingStyle.fill;

    // Fold/wing shadow paint (deeper orange)
    final shadowPaint = Paint()
      ..color = const Color(0xFFFF6E00)
      ..style = PaintingStyle.fill;

    // Back fold paint
    final backFoldPaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.fill;

    // Main top wing
    final topWing = Path()
      ..moveTo(0, h * 0.45)
      ..lineTo(w * 0.95, 0)
      ..lineTo(w * 0.45, h * 0.75)
      ..close();
    canvas.drawPath(topWing, mainPaint);

    // Underbody fold
    final underBody = Path()
      ..moveTo(0, h * 0.45)
      ..lineTo(w * 0.45, h * 0.75)
      ..lineTo(w * 0.32, h)
      ..close();
    canvas.drawPath(underBody, backFoldPaint);

    // Side wing
    final sideWing = Path()
      ..moveTo(w * 0.32, h)
      ..lineTo(w * 0.95, 0)
      ..lineTo(w * 0.45, h * 0.75)
      ..close();
    canvas.drawPath(sideWing, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
