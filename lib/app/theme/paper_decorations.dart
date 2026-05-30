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

/// Draws a dashed line. Perfect for internal dividers that should feel "lighter" than main borders.
class DashedLinePainter extends CustomPainter {
  const DashedLinePainter({
    this.color = const Color(0xFF1A1A1A),
    this.dashWidth = 4.0,
    this.dashSpace = 4.0,
    this.strokeWidth = 1.0,
    this.axis = Axis.horizontal,
  });

  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;
  final Axis axis;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (axis == Axis.horizontal) {
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, size.height / 2),
          Offset(min(startX + dashWidth, size.width), size.height / 2),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    } else {
      double startY = 0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(size.width / 2, startY),
          Offset(size.width / 2, min(startY + dashWidth, size.height)),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.axis != axis;
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({
    super.key,
    this.height = 1.0,
    this.dashWidth = 4.0,
    this.dashSpace = 4.0,
    this.strokeWidth = 1.0,
    this.color,
    this.axis = Axis.horizontal,
  });

  final double height;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;
  final Color? color;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: axis == Axis.horizontal ? double.infinity : height,
      height: axis == Axis.vertical ? double.infinity : height,
      child: CustomPaint(
        painter: DashedLinePainter(
          color: color ?? Theme.of(context).colorScheme.primary,
          dashWidth: dashWidth,
          dashSpace: dashSpace,
          strokeWidth: strokeWidth,
          axis: axis,
        ),
      ),
    );
  }
}
