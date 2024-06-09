import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ExampleCandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double width = size.width / 2;
    double height = size.height;
    double bodyHeight = height / 4;
    double tailHeight = height / 4;
    double headHeight = height / 4;

    double bodyTop = height / 4;
    double bodyBottom = bodyTop + bodyHeight;

    double tailTop = bodyBottom;
    double tailBottom = tailTop + tailHeight;

    double headTop = bodyTop - headHeight;
    double headBottom = bodyTop;

    Paint candlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    Paint wickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.red;

    canvas.drawRect(
      Rect.fromPoints(
        Offset(width - 10, bodyTop),
        Offset(width + 10, bodyBottom),
      ),
      candlePaint,
    );

    canvas.drawLine(Offset(width, tailTop), Offset(width, tailBottom), wickPaint);
    canvas.drawLine(Offset(width, headTop), Offset(width, headBottom), wickPaint);

    Paint circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.blue;

    canvas.drawCircle(Offset(width, tailBottom), 7, circlePaint);
    canvas.drawCircle(Offset(width, bodyTop), 7, circlePaint);
    canvas.drawCircle(Offset(width, bodyBottom), 7, circlePaint);
    canvas.drawCircle(Offset(width, headTop), 7, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}