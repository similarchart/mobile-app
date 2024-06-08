import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/screen/drawing_search/drawing_result.dart';
import 'package:web_view/screen/home_screen_module/searching_timer.dart';
import 'package:web_view/services/preferences.dart';
import 'package:web_view/component/bottom_banner_ad.dart';
import 'package:web_view/component/interstitial_ad_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_view/services/toast_service.dart';
import 'package:web_view/providers/search_state_providers.dart';
import 'package:web_view/screen/drawing_search/drawing_painter.dart';
import 'package:web_view/screen/drawing_search/drawing_utils.dart';
import 'dart:ui' as ui;
import 'dart:convert';

class DrawingBoard extends ConsumerStatefulWidget {
  final double screenHeight;

  const DrawingBoard({super.key, required this.screenHeight});

  @override
  _DrawingBoardState createState() => _DrawingBoardState();
}

class _DrawingBoardState extends ConsumerState<DrawingBoard>
    with SingleTickerProviderStateMixin {
  final InterstitialAdManager _adManager = InterstitialAdManager();
  List<Offset> points = [];
  List<Offset> originalPoints = [];
  bool drawingEnabled = true;
  String selectedSize = '비교일';
  String selectedMarket = '시장';
  final List<String> sizes = ['비교일', '128', '64', '32', '16', '8'];
  final List<String> countries = ['시장', '미국', '한국'];
  GlobalKey repaintBoundaryKey = GlobalKey();

  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  Client? _httpClient;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
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

    // 페이지가 초기화될 때 세로 모드로 설정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSize = prefs.getString('selectedSize') ?? '비교일';
      selectedMarket = prefs.getString('selectedMarket') ?? '시장';
    });
  }

  @override
  void dispose() {
    _httpClient?.close(); // HTTP 요청 취소
    _controller.dispose();
    _adManager.dispose();

    // 페이지를 벗어날 때 화면 방향 제한을 해제
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (bool value) {
        ref.read(isDrawingLoadingProvider.notifier).state = false;
      },
      child: Consumer(builder: (context, ref, child) {
        final isLoading = ref.watch(isDrawingLoadingProvider);
        final isCooldownCompleted = ref.watch(isCooldownCompletedProvider);
        final remainingTimeInSeconds = ref.watch(cooldownDurationProvider);

        bool isCooldownActive = !isCooldownCompleted;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryColor,
            title: const Text(
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
                    : (String? newValue) async {
                  setState(() {
                    selectedSize = newValue!;
                  });
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  await prefs.setString('selectedSize', selectedSize);
                  points = originalPoints;
                  makeReadyToSend();
                },
                style: const TextStyle(color: AppColors.textColor),
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
                    : (String? newValue) async {
                  setState(() {
                    selectedMarket = newValue!;
                  });
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  await prefs.setString('selectedMarket', selectedMarket);
                },
                style: const TextStyle(color: AppColors.textColor),
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
                  originalPoints.clear();
                  drawingEnabled = true;
                }),
              ),
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: (selectedSize != "비교일" &&
                      selectedMarket != "시장" &&
                      !drawingEnabled &&
                      !isLoading &&
                      !isCooldownActive)
                      ? AppColors.textColor
                      : AppColors.secondaryColor,
                ),
                onPressed: (selectedSize != "비교일" &&
                    selectedMarket != "시장" &&
                    !drawingEnabled &&
                    !isLoading &&
                    !isCooldownActive)
                    ? () {
                  SearchingTimer(ref).startTimer(10);
                  sendDrawing(widget.screenHeight);
                }
                    : () {
                  if (selectedSize == "비교일") {
                    ToastService().showToastMessage("비교 일수를 선택해 주세요.");
                  } else if (selectedMarket == "시장") {
                    ToastService().showToastMessage("시장을 선택해 주세요.");
                  } else if (drawingEnabled) {
                    ToastService().showToastMessage("검색을 위해 그림을 그려주세요.");
                  } else if (isLoading) {
                    ToastService().showToastMessage("잠시만 기다려주세요.");
                  } else if (isCooldownActive) {
                    ToastService().showToastMessage("$remainingTimeInSeconds초 후 재검색이 가능합니다.");
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
                    color: Colors.black.withOpacity(0.2),
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
          bottomNavigationBar: const BottomBannerAd(),
        );
      }),
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
      validatePoints(originalPoints, points);
      if (points.isNotEmpty) {
        stretchGraphToFullWidth(context, points);
        interpolatePoints(selectedSize, points);
        drawingEnabled = false;
      }
      if (points.any((point) => point.dx.isNaN || point.dy.isNaN)) {
        points = [];
        drawingEnabled = true;
      }
    });
  }

  void sendDrawing(double screenHeight) async {
    // 로딩 상태를 true로 설정
    ref.read(isDrawingLoadingProvider.notifier).state = true;

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

    String url = dotenv.env["DRAWING_SEARCH_API_URL"] ?? "";
    String market = selectedMarket == '한국' ? 'kospi_daq' : 'nyse_naq';
    String lang = await LanguagePreference.getLanguageSetting();

    Map<String, dynamic> body = {
      'numbers': numbers,
      'day_num': dayNum,
      'market': market,
      'lang': lang,
    };

    try {
      http.Response response = await _httpClient!.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        List<dynamic> results = jsonDecode(response.body);
        DrawingResultManager.initializeDrawingResult(
            res: results,
            drawing: encodedDrawing,
            mkt: market,
            sz: selectedSize,
            language: lang);

        ref.read(isDrawingLoadingProvider.notifier).state = false;

        DrawingResultManager.showDrawingResult(context);

        setState(() {
          points.clear();
          originalPoints.clear();
          drawingEnabled = true;
        });
      } else {
        print('Failed to send data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending data to the API: $e');
    } finally {
      // 로딩 상태를 false로 설정
      ref.read(isDrawingLoadingProvider.notifier).state = false;
    }
  }
}