import 'package:flutter/material.dart';

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
