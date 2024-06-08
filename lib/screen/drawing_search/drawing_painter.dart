import 'package:flutter/material.dart';
import 'package:web_view/constants/colors.dart';

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final bool drawingEnabled;
  DrawingPainter(this.points, this.drawingEnabled);

  @override
  void paint(Canvas canvas, Size size) {
    // 기존 그리기 설정
    Paint paint = Paint()
      ..color = drawingEnabled ? Colors.black : AppColors.secondaryColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    // 점들을 연결하여 선을 그림
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // 반투명 회색으로 화면 전체를 채우는 네모를 추가
    paint
      ..color = Colors.grey.withOpacity(0.15) // 색상과 투명도 설정
      ..style = PaintingStyle.fill; // 채우기 스타일로 변경
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 가이드 라인 추가
    paint
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, size.height * 0.2),
        Offset(size.width, size.height * 0.2), paint);
    canvas.drawLine(Offset(0, size.height * 0.8),
        Offset(size.width, size.height * 0.8), paint);

    // 화면 테두리 그리기
    paint
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}