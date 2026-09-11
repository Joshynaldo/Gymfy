import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/strength_standards.dart';
import '../data/tier_style.dart';

/// A hexagonal medal for one strength tier.
///
/// A shape rather than a coloured chip: five chips in a column read as five
/// labels, while five emblems read as a ladder you are somewhere on. The
/// hexagon is drawn rather than shipped as an asset so it takes the tier
/// colour, scales to any size, and costs nothing in the APK.
class RankEmblem extends StatelessWidget {
  const RankEmblem({super.key, required this.tier, this.size = 44});

  final StrengthTier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = tierColor(tier);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _EmblemPainter(color: color, pips: tierPips(tier)),
        child: Center(
          child: Icon(
            Icons.military_tech,
            // Leaves room for the pip row along the bottom edge.
            size: size * 0.38,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter({required this.color, required this.pips});

  final Color color;

  /// One through five, drawn along the bottom edge.
  final int pips;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexagon(size);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        // Faint fill, solid rim: a fully saturated hexagon at this size is a
        // blob, and the icon inside it stops being readable.
        ..color = color.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, size.width * 0.045)
        ..color = color,
    );

    _paintPips(canvas, size);
  }

  /// A flat-topped hexagon inscribed in [size].
  Path _hexagon(Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - size.width * 0.04;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      // Starting at -90° puts a vertex at the top, which reads as a crest
      // rather than as a rotated box.
      final angle = math.pi / 180 * (60 * i - 90);
      final point = Offset(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  void _paintPips(Canvas canvas, Size size) {
    final r = size.width * 0.035;
    final gap = r * 2.6;
    final y = size.height * 0.76;
    final start = size.width / 2 - (pips - 1) * gap / 2;
    final paint = Paint()..color = color;

    for (var i = 0; i < pips; i++) {
      canvas.drawCircle(Offset(start + i * gap, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.color != color || old.pips != pips;
}
