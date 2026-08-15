import 'dart:math' as math;

import 'package:flutter/material.dart';

class CompassConePainter extends CustomPainter {
  final Color color;

  CompassConePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    // We set inner radius to 8 so the seam hides perfectly under your 20px (radius 10) dot
    final innerRadius = 8.0;

    // Angles
    const double facingDir = -math.pi / 2; // North (-90 degrees)
    // Starts almost at the horizontal sides of the dot (~68 degrees off-center)
    const double innerHalfAngle = 1.8;
    // Flares out to a total of ~68 degrees at the edge (34 degrees each side)
    const double outerHalfAngle = 0.6;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.1, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    final path = Path();

    // 1. Start at the left "shoulder" of the inner dot
    path.moveTo(
      center.dx + innerRadius * math.cos(facingDir - innerHalfAngle),
      center.dy + innerRadius * math.sin(facingDir - innerHalfAngle),
    );

    // 2. Draw a straight line out to the left outer edge of the cone
    path.lineTo(
      center.dx + outerRadius * math.cos(facingDir - outerHalfAngle),
      center.dy + outerRadius * math.sin(facingDir - outerHalfAngle),
    );

    // 3. Draw a smooth rounded arc along the top to the right side
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      facingDir - outerHalfAngle,
      outerHalfAngle * 2,
      false,
    );

    // 4. Draw a straight line back in to the right "shoulder" of the inner dot
    path.lineTo(
      center.dx + innerRadius * math.cos(facingDir + innerHalfAngle),
      center.dy + innerRadius * math.sin(facingDir + innerHalfAngle),
    );

    // 5. Close the path smoothly underneath the dot
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}