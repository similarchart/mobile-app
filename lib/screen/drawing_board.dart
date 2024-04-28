import 'package:flutter/material.dart';
import 'dart:math';

class DrawingBoard extends StatefulWidget {
  @override
  _DrawingBoardState createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  List<Offset> points = [];
  bool drawingEnabled = true;
  String selectedSize = '128';
  String selectedCountry = '한국';
  final List<String> sizes = ['128', '64', '32', '16', '8'];
  final List<String> countries = ['미국', '한국'];
  bool isValid = true; // 그림의 유효성 검사 결과를 저장하는 변수
  String errMsg = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('드로잉검색'),
        automaticallyImplyLeading: false,
        actions: [
          DropdownButton<String>(
            value: selectedSize,
            onChanged: (String? newValue) {
              setState(() {
                selectedSize = newValue!;
              });
            },
            items: sizes.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          DropdownButton<String>(
            value: selectedCountry,
            onChanged: (String? newValue) {
              setState(() {
                selectedCountry = newValue!;
              });
            },
            items: countries.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetDrawing,
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: sendDrawing,
          ),
        ],
      ),
      body: Builder(builder: (BuildContext innerContext) {
        return Stack(
          children: [
            GestureDetector(
              onPanUpdate: drawingEnabled
                  ? (details) => onPanUpdate(details, innerContext)
                  : null,
              onPanEnd: onPanEnd,
              child: ClipRect(
                child: CustomPaint(
                  painter: DrawingPainter(points, drawingEnabled, isValid),
                  child: Container(),
                ),
              ),
            ),
            if (!isValid)
              Positioned(
                bottom: 10,
                left: 10,
                child: Text(
                  '그래프가 유효하지 않습니다: ' + errMsg,
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
          ],
        );
      }),
    );
  }

  void onPanUpdate(DragUpdateDetails details, BuildContext context) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    setState(() {
      points.add(renderBox.globalToLocal(details.globalPosition));
    });
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      validateDrawing();
      drawingEnabled = false;
      interpolatePoints();
    });
  }

  void validateDrawing() {}

  void resetDrawing() {
    setState(() {
      points.clear();
      drawingEnabled = true;
      isValid = true;
    });
  }

  void sendDrawing() {
    // 서버 전송 로직 구현: selectedSize와 selectedCountry 변수도 함께 전송
    print("Drawing sent with size $selectedSize and country $selectedCountry!");
  }

  void interpolatePoints() {
    if (points.isEmpty) return;

    // 최소와 최대 x 좌표값 찾기
    double minX = points.map((p) => p.dx).reduce(min);
    double maxX = points.map((p) => p.dx).reduce(max);
    int numPoints = int.parse(selectedSize); // selectedSize를 정수로 변환
    double interval = (maxX - minX) / (numPoints - 1);

    List<Offset> newPoints = [];
    newPoints.add(points.first); // 첫 번째 점 추가

    // 마지막 점을 제외하고 newPoints 리스트 생성
    for (int i = 1; i < numPoints - 1; i++) {
    double newX = minX + i * interval;
    // 보간을 위해 가장 가까운 두 점 찾기
    Offset p1 = points.lastWhere((p) => p.dx <= newX, orElse: () => points.first);
    Offset p2 = points.firstWhere((p) => p.dx >= newX, orElse: () => points.last);

    // 선형 보간 계산
    double slope = (p2.dy - p1.dy) / (p2.dx - p1.dx);
    double newY = p1.dy + slope * (newX - p1.dx);
    newPoints.add(Offset(newX, newY));
    }

    newPoints.add(points.last); // 마지막 점 추가
    points = newPoints; // points 리스트 업데이트
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final bool drawingEnabled;
  final bool isValid; // 그림의 유효성 상태를 나타내는 변수
  DrawingPainter(this.points, this.drawingEnabled, this.isValid);

  @override
  void paint(Canvas canvas, Size size) {
    // 그림 그리기 설정
    Paint paint = Paint()
      ..color =
          isValid ? (drawingEnabled ? Colors.black : Colors.grey) : Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    // 점들을 연결하여 선을 그림
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // 반투명 회색 십자가 그리기
    paint
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    paint..color = Colors.grey.withOpacity(0.2);
    // 화면 테두리에 반투명 회색 네모 그리기
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 화면 테두리에 반투명 회색 네모 그리기
    // Style을 Stroke로 변경하여 내부를 투명하게 만듭니다.
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0; // 테두리의 두께 설정
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
