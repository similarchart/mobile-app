import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/screen/pattern_result.dart';
import 'package:web_view/screen/home_screen_module/searching_timer.dart';
import 'package:web_view/services/preferences.dart';
import 'package:web_view/component/bottom_banner_ad.dart';
import 'package:web_view/component/interstitial_ad_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_view/services/toast_service.dart';
import 'package:web_view/providers/search_state_providers.dart';

class PatternSearchBoard extends ConsumerStatefulWidget {
  final double screenHeight;

  PatternSearchBoard({Key? key, required this.screenHeight}) : super(key: key);

  @override
  _PatternSearchBoardState createState() => _PatternSearchBoardState();
}

class _PatternSearchBoardState extends ConsumerState<PatternSearchBoard>
    with SingleTickerProviderStateMixin {
  final InterstitialAdManager _adManager = InterstitialAdManager();
  List<int> openPrices = List.filled(4, 0);
  List<int> closePrices = List.filled(4, 0);
  List<int> highPrices = List.filled(4, 0);
  List<int> lowPrices = List.filled(4, 0);
  String selectedMarket = '시장';
  final List<String> countries = ['시장', '미국', '한국'];
  int selectedCandleIndex = 0; // 선택된 캔들스틱의 인덱스
  String lang = 'ko'; // 기본 언어 설정을 한국어로

  @override
  void initState() {
    super.initState();
    loadPreferences();
    loadPrices(); // Load prices from SharedPreferences
    loadLanguagePreference(); // 언어 설정 로드

    // 페이지가 초기화될 때 세로 모드로 설정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void loadPrices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      openPrices = (prefs.getStringList('openPrices')?.map((e) => int.tryParse(e) ?? 0).toList() ?? List.filled(4, 0));
      closePrices = (prefs.getStringList('closePrices')?.map((e) => int.tryParse(e) ?? 0).toList() ?? List.filled(4, 0));
      highPrices = (prefs.getStringList('highPrices')?.map((e) => int.tryParse(e) ?? 0).toList() ?? List.filled(4, 0));
      lowPrices = (prefs.getStringList('lowPrices')?.map((e) => int.tryParse(e) ?? 0).toList() ?? List.filled(4, 0));
    });
  }

  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedMarket = prefs.getString('selectedMarket') ?? '시장';
    });
  }

  void loadLanguagePreference() async {
    lang = await LanguagePreference.getLanguageSetting();
    setState(() {});
  }

  @override
  void dispose() {
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
    final isLoading = ref.watch(isPatternLoadingProvider);
    double chartHeight = widget.screenHeight / 2;
    double chartWidth = chartHeight;
    final inputHeight = MediaQuery.of(context).size.width - chartHeight;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          '패턴검색',
          style: TextStyle(
            color: AppColors.textColor,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          SizedBox(width: 10.0),
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
            icon: Icon(
              Icons.send,
              color: (selectedMarket != "시장" &&
                  !isLoading &&
                  !SearchingTimer(ref).isCooldownActive)
                  ? AppColors.textColor
                  : AppColors.secondaryColor,
            ),
            onPressed: (selectedMarket != "시장" &&
                !isLoading &&
                !SearchingTimer(ref).isCooldownActive)
                ? () {
              SearchingTimer(ref).startTimer(10);
              // sendPattern(widget.screenHeight);
            }
                : () {
              if (selectedMarket == "시장") {
                ToastService().showToastMessage("시장을 선택해 주세요.");
              } else if (isLoading) {
                ToastService().showToastMessage("잠시만 기다려주세요.");
              } else if (SearchingTimer(ref).isCooldownActive) {
                int remain = SearchingTimer(ref).remainingTimeInSeconds;
                ToastService().showToastMessage("$remain초 후 재검색이 가능합니다.");
              } else {
                ToastService().showToastMessage("알 수 없는 오류가 발생했습니다.");
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: [
              Container(
                height: chartHeight,
                color: AppColors.secondaryColor,
                child: Center(
                  child: Container(
                    width: chartWidth,
                    height: chartHeight,
                    color: Colors.white, // 배경색을 하얀색으로 설정
                    child: CustomPaint(
                      painter: CandlestickChartPainter(
                        openPrices: openPrices,
                        closePrices: closePrices,
                        highPrices: highPrices,
                        lowPrices: lowPrices,
                        selectedCandleIndex: selectedCandleIndex,
                        lang: lang, // 추가
                      ),
                      child: Container(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: inputHeight * 0.05), // 5% 패딩 추가
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCandleIndex = index;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(8), // 버튼 크기 조절
                      backgroundColor: selectedCandleIndex == index ? Colors.black26 : Colors.white70, // 선택된 버튼 색상 변경
                    ),
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold, // 텍스트 굵게
                        color: selectedCandleIndex == index ? Colors.white : Colors.black, // 선택된 버튼 텍스트 색상 변경
                      ),
                    ),
                  );
                }),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildPriceInputRow('시가', openPrices, '종가', closePrices, selectedCandleIndex),
                    Container(
                      margin: EdgeInsets.zero,
                      height: 1.0,
                      color: Colors.black12,
                    ),
                    buildPriceInputRow('고가', highPrices, '저가', lowPrices, selectedCandleIndex),
                  ],
                ),
              ),
              if (isLoading)
                Expanded(
                  child: Container(
                    color: Colors.white.withOpacity(0.0),
                    child: Center(
                      child: FutureBuilder<String>(
                        future: LanguagePreference.getLanguageSetting(),
                        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
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
          );
        },
      ),
      bottomNavigationBar: const BottomBannerAd(),
    );
  }

  Widget buildPriceInputRow(String label1, List<int> prices1, String label2, List<int> prices2, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildSinglePriceInput(label1, prices1, index, label1),
        Container(
          height: 30, // Divider의 높이를 지정
          child: VerticalDivider(
            color: Colors.black12,
            thickness: 1,
          ),
        ),
        buildSinglePriceInput(label2, prices2, index, label2),
      ],
    );
  }

  Widget buildSinglePriceInput(String label, List<int> prices, int index, String type) {
    Color textColor = Colors.black;

    // 고가와 저가에 따른 색상 변경
    if (label == '고가') {
      textColor = lang == 'ko' ? Colors.red : Colors.green;
    } else if (label == '저가') {
      textColor = lang == 'ko' ? Colors.blue : Colors.red;
    }

    return Row(
      children: [
        Text(
          '$label : ${prices[index]}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(width: 16,), // 텍스트와 아이콘 사이의 간격 조절
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (prices[index] < 9) {
                    prices[index]++;
                    adjustPrices(index, type);
                  }
                });
              },
              child: Icon(Icons.arrow_circle_up),
            ),
            SizedBox(width: 10), // 아이콘 사이의 간격을 좁게 설정
            InkWell(
              onTap: () {
                setState(() {
                  if (prices[index] > 0) {
                    prices[index]--;
                    adjustPrices(index, type);
                  }
                });
              },
              child: Icon(Icons.arrow_circle_down),
            ),
          ],
        ),
      ],
    );
  }

  void adjustPrices(int index, String type) {
    setState(() {
      if (type == '시가' || type == '종가') {
        if (openPrices[index] > highPrices[index]) highPrices[index] = openPrices[index];
        if (openPrices[index] < lowPrices[index]) lowPrices[index] = openPrices[index];
        if (closePrices[index] > highPrices[index]) highPrices[index] = closePrices[index];
        if (closePrices[index] < lowPrices[index]) lowPrices[index] = closePrices[index];
      } else if (type == '고가') {
        if (highPrices[index] < openPrices[index]) openPrices[index] = highPrices[index];
        if (highPrices[index] < closePrices[index]) closePrices[index] = highPrices[index];
        if (highPrices[index] < lowPrices[index]) lowPrices[index] = highPrices[index];
      } else if (type == '저가') {
        if (lowPrices[index] > openPrices[index]) openPrices[index] = lowPrices[index];
        if (lowPrices[index] > closePrices[index]) closePrices[index] = lowPrices[index];
        if (lowPrices[index] > highPrices[index]) highPrices[index] = lowPrices[index];
      }
      savePrices();
    });
  }

  void savePrices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('openPrices', openPrices.map((e) => e.toString()).toList());
    prefs.setStringList('closePrices', closePrices.map((e) => e.toString()).toList());
    prefs.setStringList('highPrices', highPrices.map((e) => e.toString()).toList());
    prefs.setStringList('lowPrices', lowPrices.map((e) => e.toString()).toList());
  }
}

class CandlestickChartPainter extends CustomPainter {
  final List<int> openPrices;
  final List<int> closePrices;
  final List<int> highPrices;
  final List<int> lowPrices;
  final int selectedCandleIndex;
  final String lang;

  CandlestickChartPainter({
    required this.openPrices,
    required this.closePrices,
    required this.highPrices,
    required this.lowPrices,
    required this.selectedCandleIndex,
    required this.lang,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double gridWidth = size.width / 8;
    double totalHeight = size.height;
    double chartHeight = totalHeight * 0.9; // 차트 높이를 90%로 설정하여 위아래에 공백 추가
    double marginHeight = (totalHeight - chartHeight) / 2; // 위아래 공백
    double gridHeight = chartHeight / 9; // 10개의 그리드 라인

    double minHeight = 1.0;  // 최소 높이 설정

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
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(2, y - 8));
      }

      // 회색 실선 그리기
      canvas.drawLine(Offset(12, y), Offset(size.width - gridWidth / 2, y), axisPaint);
    }

    for (int i = 1; i <= 8; i++) {
      double x = i * gridWidth - gridWidth / 2;

      // 세로선 그리기
      canvas.drawLine(Offset(x, marginHeight), Offset(x, totalHeight - marginHeight), axisPaint);
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
        candleColor = close <= open ? Colors.red : Colors.green;
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
          Rect.fromLTWH(x - gridWidth / 2, marginHeight, gridWidth, chartHeight),
          backgroundPaint,
        );
      }

      // 캔들 바디 그리기
      canvas.drawRect(
        Rect.fromPoints(
          Offset(x - gridWidth / 2, top),
          Offset(x + gridWidth / 2, bottom),
        ),
        candlePaint,
      );

      // 꼬리 그리기
      canvas.drawLine(Offset(x, low), Offset(x, high), wickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}