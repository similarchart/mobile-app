import 'package:flutter/material.dart';
import 'dart:math';

class HalfCirclePainter extends CustomPainter {
  final String lang;

  HalfCirclePainter({required this.lang});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (lang == 'ko') {
      // 왼쪽 반쪽을 빨간색으로 채움
      paint.color = Colors.red;
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        -pi / 2, // 시작 각도
        pi, // sweep 각도
        true, // 중심을 채움
        paint,
      );

      // 오른쪽 반쪽을 파란색으로 채움
      paint.color = Colors.blue;
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        pi / 2, // 시작 각도
        pi, // sweep 각도
        true, // 중심을 채움
        paint,
      );
    } else if (lang == 'en') {
      // 왼쪽 반쪽을 초록색으로 채움
      paint.color = Colors.green;
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        -pi / 2, // 시작 각도
        pi, // sweep 각도
        true, // 중심을 채움
        paint,
      );

      // 오른쪽 반쪽을 빨간색으로 채움
      paint.color = Colors.red;
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        pi / 2, // 시작 각도
        pi, // sweep 각도
        true, // 중심을 채움
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false; // static한 페인터이므로 다시 그릴 필요가 없음
  }
}