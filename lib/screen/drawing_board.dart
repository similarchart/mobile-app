import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/screen/drawing_result.dart';
import 'package:web_view/screen/home_screen_module/drawing_timer.dart';
import 'package:web_view/services/preferences.dart';

import '../services/toast_service.dart';

class DrawingBoard extends StatefulWidget {
  final double screenHeight;

  DrawingBoard({Key? key, required this.screenHeight}) : super(key: key);

  @override
  _DrawingBoardState createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  List<Offset> points = [];
  List<Offset> originalPoints = [];
  bool drawingEnabled = true;
  String selectedSize = '비교일수';
  String selectedMarket = '시장';
  final List<String> sizes = ['비교일수', '128', '64', '32', '16', '8'];
  final List<String> countries = ['시장', '미국', '한국'];
  GlobalKey repaintBoundaryKey = GlobalKey();

  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: AppColors.textColor,
      end: AppColors.secondaryColor,
    ).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    loadPreferences();
  }

  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSize = prefs.getString('selectedSize') ?? '비교일수';
      selectedMarket = prefs.getString('selectedMarket') ?? '시장';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Text(
          '드로잉검색',
          style: TextStyle(
            color: AppColors.textColor,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          DropdownButton<String>(
            value: selectedSize,
            onChanged: isLoading
                ? null
                : (String? newValue) {
                    setState(() {
                      selectedSize = newValue!;
                    });
                    points = originalPoints;
                    makeReadyToSend();
                  },
            style: TextStyle(color: AppColors.textColor),
            dropdownColor: AppColors.primaryColor,
            items: sizes.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value,
                    style: TextStyle(
                        color: isLoading
                            ? AppColors.secondaryColor
                            : AppColors.textColor)),
              );
            }).toList(),
          ),
          SizedBox(width: 10.0),
          DropdownButton<String>(
            value: selectedMarket,
            onChanged: isLoading
                ? null
                : (String? newValue) {
                    setState(() {
                      selectedMarket = newValue!;
                    });
                  },
            style: TextStyle(color: AppColors.textColor),
            dropdownColor: AppColors.primaryColor,
            items: countries.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value,
                    style: TextStyle(
                        color: isLoading
                            ? AppColors.secondaryColor
                            : AppColors.textColor)),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(Icons.refresh,
                color: isLoading
                    ? AppColors.secondaryColor
                    : _colorAnimation.value ?? AppColors.textColor),
            onPressed: isLoading
                ? null
                : () => setState(() {
                      points.clear();
                      drawingEnabled = true;
                    }),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: (selectedSize != "비교일수" &&
                      selectedMarket != "시장" &&
                      !drawingEnabled &&
                      !isLoading)
                  ? AppColors.textColor
                  : AppColors.secondaryColor,
            ),
            onPressed: (selectedSize != "비교일수" &&
                    selectedMarket != "시장" &&
                    !drawingEnabled &&
                    !isLoading &&
                    !DrawingTimer().isCooldownActive)
                ? () {
                    DrawingTimer().startTimer(); // 1분 쿨타입
                    sendDrawing(widget.screenHeight);
                  }
                : () {
                    // 조건에 따른 메시지 분기
                    if (selectedSize == "비교일수") {
                      ToastService().showToastMessage("비교 일수를 선택해주세요.");
                    } else if (selectedMarket == "시장") {
                      ToastService().showToastMessage("시장을 선택해주세요.");
                    } else if (drawingEnabled) {
                      ToastService()
                          .showToastMessage("비슷한차트 검색을 위해 그림을 그려주세요.");
                    } else if (isLoading) {
                      ToastService().showToastMessage("잠시만 기다려주세요.");
                    } else if (DrawingTimer().isCooldownActive) {
                      ToastService().showToastMessage("재검색은 1분 후 가능합니다.");
                    } else {
                      ToastService().showToastMessage("알 수 없는 오류가 발생했습니다.");
                    }
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          Builder(builder: (BuildContext innerContext) {
            return GestureDetector(
              onPanStart: (details) => onPanStart(details, innerContext),
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
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.0),
                child: Center(
                  child: FutureBuilder<String>(
                    future: LanguagePreference.getLanguageSetting(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasData) {
                        String lang = snapshot.data!;
                        return Image.asset(lang == 'ko'
                            ? 'assets/loading_image.gif'
                            : 'assets/loading_image_en.gif');
                      } else {
                        return const Text('로딩 이미지를 불러올 수 없습니다.');
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void onPanStart(DragStartDetails details, BuildContext context) {
    if (!drawingEnabled) {
      _controller.forward().whenComplete(() {
        _controller.reverse();
      });
    }
  }

  void onPanUpdate(DragUpdateDetails details, BuildContext context) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    Size size = renderBox.size;

    if (localPosition.dx >= 0 &&
        localPosition.dx <= size.width &&
        localPosition.dy >= 0 &&
        localPosition.dy <= size.height) {
      setState(() {
        points.add(localPosition);
      });
    }
  }

  void onPanEnd(DragEndDetails details) {
    originalPoints = points.toList();
    makeReadyToSend();
  }

  void makeReadyToSend() {
    setState(() {
      validatePoints();
      if (points.isNotEmpty) {
        stretchGraphToFullWidth();
        interpolatePoints();
        drawingEnabled = false;
      }
      if (points.any((point) => point.dx.isNaN || point.dy.isNaN)) {
        points = [];
        drawingEnabled = true;
      }
    });
  }

  void validatePoints() {
    List<Offset> result = [];
    double? prevX;

    for (Offset point in originalPoints) {
      double currentX = point.dx;
      if (prevX == null || currentX > prevX) {
        result.add(point);
        prevX = currentX;
      }
    }

    points = result;
  }

  void stretchGraphToFullWidth() {
    double minX = points.reduce((a, b) => a.dx < b.dx ? a : b).dx;
    double maxX = points.reduce((a, b) => a.dx > b.dx ? a : b).dx;
    double width = context.size!.width;

    for (var i = 0; i < points.length; i++) {
      double normalizedX = (points[i].dx - minX) / (maxX - minX);
      points[i] = Offset(normalizedX * width, points[i].dy);
    }
  }

  void interpolatePoints() {
    double minX = points.map((p) => p.dx).reduce(min);
    double maxX = points.map((p) => p.dx).reduce(max);
    int numPoints = int.tryParse(selectedSize) ?? 128;
    double interval = (maxX - minX) / (numPoints - 1);

    List<Offset> newPoints = [points.first];
    for (int i = 1; i < numPoints - 1; i++) {
      double newX = minX + i * interval;
      Offset p1 =
          points.lastWhere((p) => p.dx <= newX, orElse: () => points.first);
      Offset p2 =
          points.firstWhere((p) => p.dx >= newX, orElse: () => points.last);

      double slope = (p2.dy - p1.dy) / (p2.dx - p1.dx);
      double newY = p1.dy + slope * (newX - p1.dx);
      newPoints.add(Offset(newX, newY));
    }
    newPoints.add(points.last);

    points = newPoints;
  }

  void sendDrawing(double screenHeight) async {
    setState(() {
      isLoading = true; // 로딩 시작
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSize', selectedSize);
    await prefs.setString('selectedMarket', selectedMarket);

    RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    String encodedDrawing = base64Encode(pngBytes);

    List<double> numbers =
        points.map((point) => 1 - point.dy / screenHeight).toList();
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
            builder: (context) => DrawingResult(
                results: results,
                userDrawing: encodedDrawing,
                market: market,
                size: selectedSize,
                lang: lang),
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
    } finally {
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
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);

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
