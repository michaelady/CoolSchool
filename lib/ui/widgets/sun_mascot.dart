import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class SunMascot extends StatelessWidget {
  const SunMascot({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SunPainter()),
    );
  }
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;
    final rayPaint = Paint()
      ..color = CoolColors.sun
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final angle = (i / 10) * math.pi * 2;
      final inner = Offset(
        center.dx + math.cos(angle) * radius * 1.25,
        center.dy + math.sin(angle) * radius * 1.25,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * radius * 1.62,
        center.dy + math.sin(angle) * radius * 1.62,
      );
      canvas.drawLine(inner, outer, rayPaint);
    }
    canvas.drawCircle(center, radius, Paint()..color = CoolColors.sun);
    canvas.drawCircle(
      center.translate(0, 2),
      radius,
      Paint()
        ..color = const Color(0x33FF9F1C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    final face = Paint()
      ..color = CoolColors.ink
      ..strokeWidth = size.width * 0.035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center.translate(-radius * 0.28, -radius * 0.12), radius * 0.09, Paint()..color = CoolColors.ink);
    canvas.drawCircle(center.translate(radius * 0.28, -radius * 0.12), radius * 0.09, Paint()..color = CoolColors.ink);
    canvas.drawCircle(center.translate(-radius * 0.38, radius * 0.18), radius * 0.12, Paint()..color = const Color(0x55FF8A80));
    canvas.drawCircle(center.translate(radius * 0.38, radius * 0.18), radius * 0.12, Paint()..color = const Color(0x55FF8A80));
    final smile = Path()
      ..moveTo(center.dx - radius * 0.28, center.dy + radius * 0.22)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.48,
        center.dx + radius * 0.28,
        center.dy + radius * 0.22,
      );
    canvas.drawPath(smile, face);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
