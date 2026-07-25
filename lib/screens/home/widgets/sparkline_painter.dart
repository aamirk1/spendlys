import 'package:flutter/material.dart';

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double minVal = data.reduce((a, b) => a < b ? a : b);
    double range = maxVal - minVal;

    double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double normalizedY = range == 0 ? 0.5 : (data[i] - minVal) / range;
      // Map to 10% - 90% range to avoid clipping
      double y =
          size.height - (normalizedY * size.height * 0.7 + size.height * 0.15);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        double prevX = (i - 1) * stepX;
        double prevNormalizedY =
            range == 0 ? 0.5 : (data[i - 1] - minVal) / range;
        double prevY = size.height -
            (prevNormalizedY * size.height * 0.7 + size.height * 0.15);

        double cx1 = prevX + stepX / 2;
        double cy1 = prevY;
        double cx2 = prevX + stepX / 2;
        double cy2 = y;

        path.cubicTo(cx1, cy1, cx2, cy2, x, y);
      }
    }

    // Draw background gradient fill under sparkline
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
