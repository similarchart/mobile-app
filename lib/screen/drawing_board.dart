import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:web_view/screen/drawing_result.dart';
import 'package:web_view/services/preferences.dart';

class DrawingBoard extends StatefulWidget {
  final double screenHeight;

  DrawingBoard({Key? key, required this.screenHeight}) : super(key: key);

  @override
  _DrawingBoardState createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  bool isLoading = false;
  List<Offset> points = [];
  bool drawingEnabled = true;
  String selectedSize = '128';
  String selectedMarket = '한국';
  final List<String> sizes = ['128', '64', '32', '16', '8'];
  final List<String> countries = ['미국', '한국'];
  GlobalKey repaintBoundaryKey = GlobalKey();

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
            value: selectedMarket,
            onChanged: (String? newValue) {
              setState(() {
                selectedMarket = newValue!;
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
            onPressed: () => sendDrawing(widget.screenHeight),
          ),
        ],
      ),
      body: Stack(
        children: [
          Builder(builder: (BuildContext innerContext) {
            return GestureDetector(
              onPanUpdate: drawingEnabled
                  ? (details) => onPanUpdate(details, innerContext)
                  : null,
              onPanEnd: drawingEnabled ? (details) => onPanEnd(details) : null,
              child: RepaintBoundary(
                key: repaintBoundaryKey,
                child: CustomPaint(
                  painter: DrawingPainter(points, drawingEnabled),
                  child: Container(),
                ),
              ),
            );
          }),
          if(isLoading)Center(
            child: FutureBuilder<String>(
              future: LanguagePreference
                  .getLanguageSetting(), // 현재 언어 설정을 가져옵니다.
              builder: (BuildContext context,
                  AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // 언어 설정을 로딩 중이면 기본 로딩 인디케이터 표시
                } else if (snapshot.hasData) {
                  String lang = snapshot.data!;
                  // 언어 설정에 따라 다른 GIF 이미지 로드
                  return Image.asset(lang == 'ko'
                      ? 'assets/loading_image.gif'
                      : 'assets/loading_image_en.gif');
                } else {
                  return const Text('로딩 이미지를 불러올 수 없습니다.');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void onPanUpdate(DragUpdateDetails details, BuildContext context) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    Size size = renderBox.size;

    if (localPosition.dx >= 0 && localPosition.dx <= size.width &&
        localPosition.dy >= 0 && localPosition.dy <= size.height) {
      setState(() {
        points.add(localPosition);
      });
    }
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      validatePoints();
      stretchGraphToFullWidth();
      if (points.isNotEmpty) {
        interpolatePoints();
        drawingEnabled = false;
      }
    });
  }

  void stretchGraphToFullWidth() {
    if (points.isEmpty) return;

    double minX = points.reduce((a, b) => a.dx < b.dx ? a : b).dx;
    double maxX = points.reduce((a, b) => a.dx > b.dx ? a : b).dx;
    double width = context.size!.width;

    for (var i = 0; i < points.length; i++) {
      double normalizedX = (points[i].dx - minX) / (maxX - minX);
      points[i] = Offset(normalizedX * width, points[i].dy);
    }
  }


  void validatePoints() {
    List<Offset> result = [];
    double? prevX;

    for (Offset point in points) {
      double currentX = point.dx;
      if (prevX == null || currentX > prevX) {
        result.add(point);
        prevX = currentX;
      }
    }

    points = result;
  }

  void interpolatePoints() {
    double minX = points.map((p) => p.dx).reduce(min);
    double maxX = points.map((p) => p.dx).reduce(max);
    int numPoints = int.parse(selectedSize);
    double interval = (maxX - minX) / (numPoints - 1);

    List<Offset> newPoints = [points.first];
    for (int i = 1; i < numPoints - 1; i++) {
      double newX = minX + i * interval;
      Offset p1 = points.lastWhere((p) => p.dx <= newX, orElse: () => points.first);
      Offset p2 = points.firstWhere((p) => p.dx >= newX, orElse: () => points.last);

      double slope = (p2.dy - p1.dy) / (p2.dx - p1.dx);
      double newY = p1.dy + slope * (newX - p1.dx);
      newPoints.add(Offset(newX, newY));
    }
    newPoints.add(points.last);

    points = newPoints;
  }

  void resetDrawing() {
    setState(() {
      points.clear();
      drawingEnabled = true;
    });
  }

  void sendDrawing(double screenHeight) async {
    setState(() {
      isLoading = true;  // 로딩 시작
    });

    RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    String encodedDrawing = base64Encode(pngBytes);

    List<double> numbers = points.map((point) => 1 - point.dy / screenHeight).toList();
    int dayNum = int.tryParse(selectedSize) ?? 0;

    String url = 'https://similarchart.com/api/drawing_search';
    String market = selectedMarket == '한국' ? 'kospi_daq' : 'nyse_naq';
    String lang = await LanguagePreference.getLanguageSetting();

    Map<String, dynamic> body = {
      'numbers': numbers,
      'day_num': dayNum,
      'market': market,
      'lang': lang,
    };

    try {
      http.Response response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        List<dynamic> results = jsonDecode(response.body);
        String? url = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DrawingResult(results: results, userDrawing: encodedDrawing, market: market, size: selectedSize, lang: lang),
          ),
        );

        if (url != null) {
          Navigator.pop(context, url);
        }

      } else {
        print('Failed to send data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending data to the API: $e');
    }finally {
      setState(() {
        isLoading = false; // 로딩 종료
      });
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final bool drawingEnabled;
  DrawingPainter(this.points, this.drawingEnabled);

  @override
  void paint(Canvas canvas, Size size) {
    // 그림 그리기 설정
    Paint paint = Paint()
      ..color = drawingEnabled ? Colors.black : Colors.grey
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
    paint..color = Colors.grey.withOpacity(0.1);
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
