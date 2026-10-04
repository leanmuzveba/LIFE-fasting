import 'package:flutter/painting.dart';

/// Pill outline drawn as dashes (CSS `border: 1.5px dashed`). Flutter has no
/// built-in dashed border.
class DashedStadiumBorder extends OutlinedBorder {
  const DashedStadiumBorder({required this.color, this.width = 1.5, this.dash = 4.5, this.gap = 3});

  final Color color;
  final double width;
  final double dash;
  final double gap;

  Path _pill(Rect rect) => Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2)));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _pill(rect.deflate(width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _pill(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final metric in _pill(rect.deflate(width / 2)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  ShapeBorder scale(double t) => DashedStadiumBorder(color: color, width: width * t, dash: dash * t, gap: gap * t);

  @override
  OutlinedBorder copyWith({BorderSide? side}) => this;
}
