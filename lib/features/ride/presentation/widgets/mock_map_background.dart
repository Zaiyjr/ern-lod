import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Renders the vector dark map mirroring the SVG design in mockup.html
class MockMapBackground extends StatelessWidget {
  const MockMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MockMapPainter(),
    );
  }
}

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background fill
    final bgPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Coordinate space normalization (from 390 x 844 viewBox)
    final scaleX = size.width / 390.0;
    final scaleY = size.height / 844.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Park / water accents
    final waterPaint = Paint()..color = const Color(0xFF0B2237);
    final waterPath = Path()
      ..moveTo(0, 690)
      ..quadraticBezierTo(96, 702, 134, 736)
      ..quadraticBezierTo(162, 761, 172, 844)
      ..lineTo(0, 844)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    final parkPaint = Paint()..color = const Color(0xFF0F2A22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(252, 86, 118, 104),
        const Radius.circular(18),
      ),
      parkPaint,
    );

    // City blocks (buildings)
    final blockPaint = Paint()..color = const Color(0xFF141D2F);
    final blocks = [
      const Rect.fromLTWH(34, 120, 86, 66),
      const Rect.fromLTWH(146, 132, 70, 96),
      const Rect.fromLTWH(34, 250, 96, 120),
      const Rect.fromLTWH(160, 286, 88, 74),
      const Rect.fromLTWH(286, 238, 84, 112),
      const Rect.fromLTWH(196, 404, 120, 90),
      const Rect.fromLTWH(30, 430, 110, 76),
      const Rect.fromLTWH(86, 560, 120, 88),
      const Rect.fromLTWH(238, 540, 120, 118),
      const Rect.fromLTWH(292, 700, 98, 90),
      const Rect.fromLTWH(40, 740, 120, 70),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(8)),
        blockPaint,
      );
    }

    // Minor building shadows / highlights
    final subBlockPaint = Paint()..color = const Color(0xBF18233A);
    final subBlocks = [
      const Rect.fromLTWH(150, 300, 30, 22),
      const Rect.fromLTWH(300, 256, 40, 26),
      const Rect.fromLTWH(96, 574, 34, 24),
      const Rect.fromLTWH(250, 556, 36, 26),
    ];
    for (final sb in subBlocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(sb, const Radius.circular(4)),
        subBlockPaint,
      );
    }

    // Road strokes
    final majorRoadPaint = Paint()
      ..color = const Color(0xFF1C2840)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roads = [
      (const Offset(-10, 214), const Offset(400, 214), 16.0),
      (const Offset(-10, 404), const Offset(400, 404), 14.0),
      (const Offset(-10, 658), const Offset(400, 658), 16.0),
      (const Offset(130, -10), const Offset(130, 860), 14.0),
      (const Offset(268, -10), const Offset(268, 860), 12.0),
      (const Offset(-10, 520), const Offset(400, 520), 10.0),
    ];
    for (final r in roads) {
      majorRoadPaint.strokeWidth = r.$3;
      canvas.drawLine(r.$1, r.$2, majorRoadPaint);
    }

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFF182236)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    final secRoads = [
      (const Offset(-10, 300), const Offset(240, 300)),
      (const Offset(60, -10), const Offset(60, 860)),
      (const Offset(340, 200), const Offset(340, 860)),
      (const Offset(-10, 590), const Offset(130, 590)),
      (const Offset(-10, 780), const Offset(400, 780)),
      (const Offset(204, 214), const Offset(204, 404)),
      (const Offset(268, 404), const Offset(268, 658)),
    ];
    for (final sr in secRoads) {
      canvas.drawLine(sr.$1, sr.$2, secondaryRoadPaint);
    }

    // Nearby simulated cars on the map
    _drawCar(canvas, const Offset(286, 338), -16 * math.pi / 180);
    _drawCar(canvas, const Offset(86, 584), 72 * math.pi / 180);

    // Current rider user pin (x: 196, y: 430)
    final outerRing = Paint()..color = const Color(0x332563EB);
    canvas.drawCircle(const Offset(196, 430), 22, outerRing);

    final whitePin = Paint()..color = const Color(0xFFF1F5FB);
    canvas.drawCircle(const Offset(196, 430), 11, whitePin);

    final borderPin = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(196, 430), 11, borderPin);

    canvas.restore();
  }

  void _drawCar(Canvas canvas, Offset pos, double angleRad) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angleRad);

    // Car shadow
    final shadowPaint = Paint()..color = const Color(0x80040812);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 9), width: 24, height: 6),
      shadowPaint,
    );

    // Car body
    final bodyPaint = Paint()..color = const Color(0xFFDCE6F5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -6, 24, 12),
        const Radius.circular(5),
      ),
      bodyPaint,
    );

    // Car windshield
    final windshieldPaint = Paint()..color = AppColors.accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5.5, -3.2, 11, 6.4),
        const Radius.circular(2.2),
      ),
      windshieldPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
