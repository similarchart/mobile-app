import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class CandlestickChartPainter extends CustomPainter {
  final List<int> openPrices;
  final List<int> closePrices;
  final List<int> highPrices;
  final List<int> lowPrices;
  final int selectedCandleIndex;
  final String lang;
  final int? highlightedRowIndex;

  CandlestickChartPainter({
    required this.openPrices,
    required this.closePrices,
    required this.highPrices,
    required this.lowPrices,
    required this.selectedCandleIndex,
    required this.lang,
    required this.highlightedRowIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double gridWidth = size.width / 8;
    double marginWidth = gridWidth / 2;
    double totalHeight = size.height;
    double chartHeight = totalHeight * 0.9; // 차트 높이를 90%로 설정하여 위아래에 공백 추가
    double marginHeight = (totalHeight - chartHeight) / 2; // 위아래 공백
    double gridHeight = chartHeight / 9; // 10개의 그리드 라인

    double minHeight = 1.0; // 최소 높이 설정

    Paint axisPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 9; i++) {
      double y = totalHeight - marginHeight - i * gridHeight;

      // 높이 숫자 표기 (0, 3, 6, 9에만 숫자 표시)
      if (i % 3 == 0) {
        textPainter.text = TextSpan(
          text: '$i',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(8, y - 8));
      }

      // 회색 실선 그리기
      if (highlightedRowIndex != null && highlightedRowIndex == i) {
        axisPaint.color = Colors.orange; // 드래그 중인 가로선 색상 변경
      } else {
        axisPaint.color = Colors.black12; // 기본 색상
      }
      canvas.drawLine(
          Offset(20, y), Offset(size.width - marginWidth, y), axisPaint);
    }

    axisPaint.color = Colors.black12;
    for (int i = 1; i <= 8; i++) {
      double x = i * gridWidth - marginWidth;

      // 세로선 그리기
      canvas.drawLine(Offset(x, marginHeight),
          Offset(x, totalHeight - marginHeight), axisPaint);
    }

    for (int i = 0; i < 4; i++) {
      double x = (i * 2 + 1) * gridWidth;
      double open = totalHeight - marginHeight - openPrices[i] * gridHeight;
      double close = totalHeight - marginHeight - closePrices[i] * gridHeight;
      double high = totalHeight - marginHeight - highPrices[i] * gridHeight;
      double low = totalHeight - marginHeight - lowPrices[i] * gridHeight;

      Color candleColor;
      if (lang == 'ko') {
        candleColor = close <= open ? Colors.red : Colors.blue;
      } else {
        candleColor = close <= open ? Colors.green : Colors.red;
      }

      Paint candlePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = candleColor;

      Paint wickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = candleColor; // 꼬리 색을 캔들 색과 맞춤

      double top = min(open, close);
      double bottom = max(open, close);

      if (bottom - top < minHeight) {
        bottom = top + minHeight;
      }

      // 선택된 캔들스틱의 배경을 노란색으로 설정
      if (i == selectedCandleIndex) {
        Paint backgroundPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.yellow.withOpacity(0.3);
        canvas.drawRect(
          Rect.fromLTWH(x - marginWidth, marginHeight, gridWidth, chartHeight),
          backgroundPaint,
        );
      }

      // 캔들 바디 그리기
      canvas.drawRect(
        Rect.fromPoints(
          Offset(x - marginWidth, top),
          Offset(x + marginWidth, bottom),
        ),
        candlePaint,
      );

      // 꼬리 그리기
      canvas.drawLine(Offset(x, low), Offset(x, high), wickPaint);
    }

    if (!containsNumber(9, openPrices, closePrices, highPrices, lowPrices)) {
      Paint backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.red.withOpacity(0.05);
      canvas.drawRect(
        Rect.fromLTWH(marginWidth, marginHeight, gridWidth * 7, gridHeight),
        backgroundPaint,
      );
    }

    if (!containsNumber(0, openPrices, closePrices, highPrices, lowPrices)) {
      Paint backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.red.withOpacity(0.05);
      canvas.drawRect(
        Rect.fromLTWH(marginWidth, marginHeight + gridHeight * 8, gridWidth * 7,
            gridHeight),
        backgroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

bool containsNumber(int num, List<int> openPrices, List<int> closePrices,
    List<int> highPrices, List<int> lowPrices) {
  return openPrices.contains(num) ||
      closePrices.contains(num) ||
      highPrices.contains(num) ||
      lowPrices.contains(num);
}