import 'dart:async';

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
import 'package:web_view/providers/home_screen_state_providers.dart';
import 'package:web_view/services/check_internet.dart';
import 'package:web_view/system/logger.dart';

import '../../l10n/app_localizations.dart';

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
  String selectedSize = '';
  String selectedMarket = '';
  List<String> sizes = [];
  List<String> countries = [];
  GlobalKey repaintBoundaryKey = GlobalKey();
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late AppLocalizations localizations;
  Client? _httpClient;

  void _initializeValues() {
    selectedSize = localizations.translate('day');
    selectedMarket = localizations.translate('market');
    sizes = [
      localizations.translate('day'),
      '128', '64', '32', '16', '8'
    ];
    countries = [
      localizations.translate('market'),
      localizations.translate('US'),
      localizations.translate('KR')
    ];

    // 초기화 시 selectedSize와 selectedMarket이 리스트의 값 중 하나와 일치하는지 확인
    if (!sizes.contains(selectedSize)) {
      selectedSize = sizes.first;
    }
    if (!countries.contains(selectedMarket)) {
      selectedMarket = countries.first;
    }
  }

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = AppLocalizations.of(context);
    _initializeValues();

    if (!DrawingResultManager.isResultExist()) {
      ToastService().showToastMessage(localizations.translate("draw_desired_chart"));
    }
  }

  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // 저장된 값을 현재 언어로 번역된 값과 일치시킴
      String storedSize = prefs.getString('selectedSize') ?? localizations.translate("day");
      String storedMarket = prefs.getString('selectedMarket') ?? localizations.translate("market");

      selectedSize = sizes.contains(storedSize) ? storedSize : sizes.first;
      selectedMarket = countries.contains(storedMarket) ? storedMarket : countries.first;
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
        ref.read(isLoadingProvider.notifier).state = false;
      },
      child: Consumer(builder: (context, ref, child) {
        final isLoading = ref.watch(isLoadingProvider);
        final isCooldownCompleted = ref.watch(isCooldownCompletedProvider);
        final remainingTimeInSeconds = ref.watch(cooldownDurationProvider);

        bool isCooldownActive = !isCooldownCompleted;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryColor,
            title: Text(
              localizations.translate("drawing_search"),
              style: const TextStyle(
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
                  SharedPreferences prefs = await SharedPreferences.getInstance();
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
              const SizedBox(width: 10.0),
              DropdownButton<String>(
                value: selectedMarket,
                onChanged: isLoading
                    ? null
                    : (String? newValue) async {
                  setState(() {
                    selectedMarket = newValue!;
                  });
                  SharedPreferences prefs = await SharedPreferences.getInstance();
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
                  color: (selectedSize != localizations.translate("day") &&
                      selectedMarket != localizations.translate("market") &&
                      !drawingEnabled &&
                      !isLoading &&
                      !isCooldownActive)
                      ? AppColors.textColor
                      : AppColors.secondaryColor,
                ),
                onPressed: (selectedSize != localizations.translate("day") &&
                    selectedMarket != localizations.translate("market") &&
                    !drawingEnabled &&
                    !isLoading &&
                    !isCooldownActive)
                    ? () {
                  sendDrawing(widget.screenHeight);
                }
                    : () {
                  if (selectedSize == localizations.translate("day")) {
                    ToastService().showToastMessage(localizations.translate("select_comparison_days"));
                  } else if (selectedMarket == localizations.translate("market")) {
                    ToastService().showToastMessage(localizations.translate("select_market"));
                  } else if (drawingEnabled) {
                    ToastService().showToastMessage(localizations.translate("draw_to_search"));
                  } else if (isLoading) {
                    ToastService().showToastMessage(localizations.translate("please_wait"));
                  } else if (isCooldownActive) {
                    ToastService().showToastMessage(localizations.translateWithArgs("remaining_time", [remainingTimeInSeconds]));
                  } else {
                    ToastService().showToastMessage(localizations.translate("unknown_error"));
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
            ],
          ),
          bottomNavigationBar: const BottomBannerAd(),
          // bottomNavigationBar: Container(height: 60, color: AppColors.primaryColor),
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
    if (!await checkInternetConnection()) return;

    SearchingTimer(ref).startTimer(10);
    ref.read(isLoadingProvider.notifier).state = true;

    // API 호출 결과를 저장하기 위한 Completer
    Completer<Map<String, dynamic>> apiResultCompleter = Completer<Map<String, dynamic>>();

    // 백그라운드에서 API 호출을 수행
    _fetchDrawingResult(screenHeight).then((apiResult) {
      apiResultCompleter.complete(apiResult);
    });

    // 전면 광고를 먼저 보여줌
    _adManager.showInterstitialAd(context, () async {
      // 광고가 닫히면 호출되는 콜백
      Map<String, dynamic> apiResult = await apiResultCompleter.future;
      _handleDrawingApiResponse(context, apiResult);
    });
  }

  Future<Map<String, dynamic>> _fetchDrawingResult(double screenHeight) async {
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
    String market = selectedMarket == localizations.translate("KR") ? 'kospi_daq' : 'nyse_naq';
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
            sz: selectedSize);

        return {'success': true, 'results': results};
      } else {
        Log.instance.e('Failed to send data. Status code: ${response.statusCode}');
        Log.instance.i('Response body: ${response.body}');
        return {'success': false, 'error': 'Failed to send data.'};
      }
    } catch (e) {
      Log.instance.e('Error sending data to the API: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  void _handleDrawingApiResponse(BuildContext context, Map<String, dynamic> response) async {
    ref.read(isLoadingProvider.notifier).state = false;

    if (response['success']) {
      String? resultUrl = await DrawingResultManager.showDrawingResult(context);
      Navigator.pop(context, resultUrl); // URL을 반환하며 화면을 닫음

      setState(() {
        points.clear();
        originalPoints.clear();
        drawingEnabled = true;
      });
    } else {
      Log.instance.e('Error: ${response['error']}');
      // 에러 메시지를 표시하는 로직 추가 가능
    }
  }
}