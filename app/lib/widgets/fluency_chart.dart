import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FluencyChart extends StatelessWidget {
  const FluencyChart({
    required this.points,
    super.key,
  });

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: CustomPaint(
        painter: _FluencyPainter(points),
      ),
    );
  }
}

class _FluencyPainter extends CustomPainter {
  _FluencyPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final grid = Paint()
      ..color = const Color(0xFFDCE7EC)
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final spread = (max - min).abs() < 0.001 ? 1 : max - min;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = (values[i] - min) / spread;
      final y = size.height - (normalized * (size.height - 10)) - 5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x6631A6B8), Color(0x0031A6B8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );

    final dotPaint = Paint()..color = AppColors.secondary;
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = (values[i] - min) / spread;
      final y = size.height - (normalized * (size.height - 10)) - 5;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FluencyPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
