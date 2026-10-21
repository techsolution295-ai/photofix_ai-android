import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Medal icon used on the Pro screen.
class ProAwardBadge extends StatelessWidget {
  const ProAwardBadge({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.15),
      painter: const _ProAwardBadgePainter(),
    );
  }
}

class _ProAwardBadgePainter extends CustomPainter {
  const _ProAwardBadgePainter();

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C4CF1), Color(0xFF2677FF)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final shader = _gradient.createShader(Offset.zero & size);
    final scale = size.width / 84;
    final stroke = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height * 0.38);
    final radius = size.width * 0.34;

    canvas.drawCircle(center, radius, stroke);
    canvas.drawCircle(
      center,
      radius * 0.78,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );
    canvas.drawPath(_star(center, radius * 0.42), stroke);

    final wing = 22 * scale;
    final inset = 7 * scale;
    final tail = 10 * scale;
    final leftRibbon = Path()
      ..moveTo(center.dx - 4 * scale, center.dy + radius * 0.72)
      ..lineTo(center.dx - wing, size.height - 2 * scale)
      ..lineTo(center.dx - inset, size.height - tail)
      ..lineTo(center.dx + 3 * scale, center.dy + radius * 0.78)
      ..close();
    final rightRibbon = Path()
      ..moveTo(center.dx + 4 * scale, center.dy + radius * 0.72)
      ..lineTo(center.dx + wing, size.height - 2 * scale)
      ..lineTo(center.dx + inset, size.height - tail)
      ..lineTo(center.dx - 3 * scale, center.dy + radius * 0.78)
      ..close();
    canvas.drawPath(leftRibbon, stroke);
    canvas.drawPath(rightRibbon, stroke);
  }

  Path _star(Offset center, double radius) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final angle = -math.pi / 2 + (i * math.pi / points);
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
