import 'dart:math';
import 'package:flutter/material.dart';

/// Draws a 45° diagonal hatch pattern at full opacity with thin, sparse lines.
/// Designed for e-ink: no semi-transparency — just hairlines at 100% ink.
class HatchPainter extends CustomPainter {
  const HatchPainter({
    this.color = const Color(0xFF1A1A1A),
    this.spacing = 14.0,
    this.strokeWidth = 0.5,
  });

  final Color color;
  final double spacing;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final total = size.width + size.height;
    var offset = 0.0;
    while (offset < total) {
      final x1 = min(offset, size.width);
      final y1 = max(0.0, offset - size.width);
      final x2 = max(0.0, offset - size.height);
      final y2 = min(offset, size.height);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      offset += spacing;
    }
  }

  @override
  bool shouldRepaint(HatchPainter oldDelegate) =>
      oldDelegate.spacing != spacing ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Draws a dot grid at full opacity — like bullet journal paper.
/// Dots are small and sparse so they read as texture, not clutter.
class DotGridPainter extends CustomPainter {
  const DotGridPainter({
    this.color = const Color(0xFF1A1A1A),
    this.dotRadius = 0.8,
    this.spacingX = 24.0,
    this.spacingY = 24.0,
  });

  final Color color;
  final double dotRadius;
  final double spacingX;
  final double spacingY;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var x = spacingX;
    while (x < size.width) {
      var y = spacingY;
      while (y < size.height) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
        y += spacingY;
      }
      x += spacingX;
    }
  }

  @override
  bool shouldRepaint(DotGridPainter oldDelegate) =>
      oldDelegate.spacingX != spacingX ||
      oldDelegate.spacingY != spacingY ||
      oldDelegate.color != color;
}

/// A widget that paints a hatch pattern behind its [child].
class HatchBackground extends StatelessWidget {
  const HatchBackground({
    super.key,
    required this.child,
    this.spacing = 14.0,
    this.strokeWidth = 0.5,
  });

  final Widget child;
  final double spacing;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final inkColor = Theme.of(context).colorScheme.primary;
    return CustomPaint(
      painter: HatchPainter(
        color: inkColor,
        spacing: spacing,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}
