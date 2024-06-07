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

enum PriceType { open, close, high, low }

int? highlightedRowIndex;

class PatternSearchBoard extends ConsumerStatefulWidget {
  final double screenHeight;

  PatternSearchBoard({Key? key, required this.screenHeight}) : super(key: key);

  @override
  _PatternSearchBoardState createState() => _PatternSearchBoardState();
}

class _PatternSearchBoardState extends ConsumerState<PatternSearchBoard>
    with SingleTickerProviderStateMixin {
  final InterstitialAdManager _adManager = InterstitialAdManager();
  List<int> openPrices = [1, 3, 5, 7];
  List<int> closePrices = [2, 4, 6, 8];
  List<int> highPrices = [3, 5, 7, 9];
  List<int> lowPrices = [0, 2, 4, 6];
  String selectedMarket = '시장';
  final List<String> countries = ['시장', '미국', '한국'];
  int selectedCandleIndex = 0; // 선택된 캔들스틱의 인덱스
  String lang = 'ko'; // 기본 언어 설정을 한국어로
  PriceType? selectedPriceType;
  GlobalKey repaintBoundaryKey = GlobalKey();

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
      openPrices = (prefs
          .getStringList('openPrices')
          ?.map((e) => int.tryParse(e) ?? 0)
          .toList() ??
          [1, 3, 5, 7]);
      closePrices = (prefs
          .getStringList('closePrices')
          ?.map((e) => int.tryParse(e) ?? 0)
          .toList() ??
          [2, 4, 6, 8]);
      highPrices = (prefs
          .getStringList('highPrices')
          ?.map((e) => int.tryParse(e) ?? 0)
          .toList() ??
          [3, 5, 7, 9]);
      lowPrices = (prefs
          .getStringList('lowPrices')
          ?.map((e) => int.tryParse(e) ?? 0)
          .toList() ??
          [0, 2, 4, 6]);
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
    double screenWidth = MediaQuery.of(context).size.width;
    double chartHeight = widget.screenHeight / 2;
    double chartWidth = chartHeight;
    double gridWidth = chartWidth / 8;
    double gridHeight = chartHeight / 10;
    double widthMargin = gridWidth / 2; // 상단 여백
    double heightMargin = gridHeight / 2; // 상단 여백
    final inputHeight = screenWidth - chartHeight;

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
            icon: Icon(
              Icons.send,
              color: (selectedMarket != "시장" &&
                  !isLoading &&
                  !SearchingTimer(ref).isCooldownActive &&
                  containsNumber(9, openPrices, closePrices, highPrices, lowPrices) &&
                  containsNumber(0, openPrices, closePrices, highPrices, lowPrices))
                  ? AppColors.textColor
                  : AppColors.secondaryColor,
            ),
            onPressed: (selectedMarket != "시장" &&
                !isLoading &&
                !SearchingTimer(ref).isCooldownActive &&
                containsNumber(9, openPrices, closePrices, highPrices, lowPrices) &&
                containsNumber(0, openPrices, closePrices, highPrices, lowPrices))
                ? () {
              SearchingTimer(ref).startTimer(10);
              sendPattern(widget.screenHeight);
            }
                : () {
              if (selectedMarket == "시장") {
                ToastService().showToastMessage("시장을 선택해 주세요.");
              } else if (isLoading) {
                ToastService().showToastMessage("잠시만 기다려주세요.");
              } else if (SearchingTimer(ref).isCooldownActive) {
                int remain = SearchingTimer(ref).remainingTimeInSeconds;
                ToastService().showToastMessage("$remain초 후 재검색이 가능합니다.");
              } else if (!containsNumber(9, openPrices, closePrices, highPrices, lowPrices)) {
                ToastService().showToastMessage("하나 이상의 캔들스틱을 맨 위 칸까지 그려주세요.");
              } else if (!containsNumber(0, openPrices, closePrices, highPrices, lowPrices)) {
                ToastService().showToastMessage("하나 이상의 캔들스틱을 맨 아래 칸까지 그려주세요.");
              } else {
                ToastService().showToastMessage("알 수 없는 오류가 발생했습니다.");
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTapDown: (TapDownDetails details) {
                      RenderBox box = context.findRenderObject() as RenderBox;
                      Offset localPosition = box.globalToLocal(details.globalPosition);

                      // 모눈의 영역 계산
                      double leftMargin = (constraints.maxWidth - chartWidth) / 2;

                      if (localPosition.dx >= leftMargin &&
                          localPosition.dx <= screenWidth - leftMargin) {
                        setState(() {
                          selectedCandleIndex = ((localPosition.dx - leftMargin) / gridWidth).floor() ~/ 2;
                          selectedPriceType = null;

                          // 터치한 위치와 시가/종가/고가/저가의 위치를 비교하여 선택된 항목 설정
                          double openPriceY = chartHeight - openPrices[selectedCandleIndex] * gridHeight - heightMargin;
                          double closePriceY = chartHeight - closePrices[selectedCandleIndex] * gridHeight - heightMargin;
                          double highPriceY = chartHeight - highPrices[selectedCandleIndex] * gridHeight - heightMargin;
                          double lowPriceY = chartHeight - lowPrices[selectedCandleIndex] * gridHeight - heightMargin;

                          if (localPosition.dy >= openPriceY - heightMargin &&
                              localPosition.dy < openPriceY + heightMargin) {
                            selectedPriceType = PriceType.open;
                          } else if (localPosition.dy >= closePriceY - heightMargin &&
                              localPosition.dy < closePriceY + heightMargin) {
                            selectedPriceType = PriceType.close;
                          } else if (localPosition.dy >= highPriceY - heightMargin &&
                              localPosition.dy < highPriceY + heightMargin) {
                            selectedPriceType = PriceType.high;
                          } else if (localPosition.dy >= lowPriceY - heightMargin &&
                              localPosition.dy < lowPriceY + heightMargin) {
                            selectedPriceType = PriceType.low;
                          }
                        });
                      }
                      setState(() {
                        highlightedRowIndex = ((chartHeight - localPosition.dy + heightMargin) / gridHeight).floor();
                      });
                    },
                    onPanUpdate: (DragUpdateDetails details) {
                      RenderBox box = context.findRenderObject() as RenderBox;
                      Offset localPosition = box.globalToLocal(details.globalPosition);
                      double margin = gridHeight / 2; // 상단 여백, 필요시 조정
                      int touchedRow = max(0, min(9, ((chartHeight - localPosition.dy + margin) / gridHeight).floor()));
                      setState(() {
                        highlightedRowIndex = touchedRow;
                      });
                      // 드래그 중인 경우
                      if (selectedPriceType != null &&
                          localPosition.dy >= 0 &&
                          localPosition.dy <= chartHeight) {
                        setState(() {
                          if (selectedPriceType == PriceType.open) {
                            openPrices[selectedCandleIndex] = touchedRow;
                          } else if (selectedPriceType == PriceType.close) {
                            closePrices[selectedCandleIndex] = touchedRow;
                          } else if (selectedPriceType == PriceType.high) {
                            highPrices[selectedCandleIndex] = touchedRow;
                          } else if (selectedPriceType == PriceType.low) {
                            lowPrices[selectedCandleIndex] = touchedRow;
                          }
                        });
                        adjustPrices(selectedCandleIndex, selectedPriceType!);
                      }
                    },
                    onPanEnd: (DragEndDetails details) {
                      selectedPriceType = null;
                      highlightedRowIndex = null;
                    },
                    child: Container(
                      height: chartHeight,
                      color: AppColors.secondaryColor,
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: chartWidth,
                              height: chartHeight,
                              color: Colors.white, // 배경색을 하얀색으로 설정
                              child: RepaintBoundary(
                                key: repaintBoundaryKey,
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
                          Positioned(
                            left: 0, // 오른쪽에서 약간의 여백을 둠
                            top: 8, // 차트 높이의 절반 위치
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  // 시가와 종가 값을 바꾸는 로직
                                  int temp = openPrices[selectedCandleIndex];
                                  openPrices[selectedCandleIndex] = closePrices[selectedCandleIndex];
                                  closePrices[selectedCandleIndex] = temp;
                                  adjustPrices(selectedCandleIndex, PriceType.open);
                                  adjustPrices(selectedCandleIndex, PriceType.close);
                                });

                                ToastService().showToastMessage("시가 종가 반전");
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(8), // 버튼 크기 조절
                              ),
                              child: CustomPaint(
                                size: Size(24, 24), // 원형 버튼의 크기
                                painter: HalfRedHalfBluePainter(lang: lang),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0, // 오른쪽에서 약간의 여백을 둠
                            top: 60, // 차트 높이의 절반 위치
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  highPrices[selectedCandleIndex] = max(openPrices[selectedCandleIndex], closePrices[selectedCandleIndex]);
                                  lowPrices[selectedCandleIndex] = min(openPrices[selectedCandleIndex], closePrices[selectedCandleIndex]);
                                  adjustPrices(selectedCandleIndex, PriceType.open);
                                });

                                ToastService().showToastMessage("꼬리 제거");
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(8), // 버튼 크기 조절
                              ),
                              child: Image.asset(
                                'assets/not_tail.png',
                                width: 24.0,
                                height: 24.0,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0, // 오른쪽에서 약간의 여백을 둠
                            top: 8, // 차트 높이의 절반 위치
                            child: ElevatedButton(
                                onPressed: () {
                                  if (highPrices[selectedCandleIndex] < 9) {
                                    setState(() {
                                      // 시가와 종가 값을 바꾸는 로직
                                      openPrices[selectedCandleIndex]++;
                                      closePrices[selectedCandleIndex]++;
                                      highPrices[selectedCandleIndex]++;
                                      lowPrices[selectedCandleIndex]++;
                                    });
                                  }

                                  ToastService().showToastMessage("전체 한칸 위로");
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(8), // 버튼 크기 조절
                                ),
                                child: Icon(Icons.arrow_circle_up)
                            ),
                          ),
                          Positioned(
                            right: 0, // 오른쪽에서 약간의 여백을 둠
                            top: 60, // 차트 높이의 절반 위치
                            child: ElevatedButton(
                                onPressed: () {
                                  if (0 < lowPrices[selectedCandleIndex]) {
                                    setState(() {
                                      // 시가와 종가 값을 바꾸는 로직
                                      openPrices[selectedCandleIndex]--;
                                      closePrices[selectedCandleIndex]--;
                                      highPrices[selectedCandleIndex]--;
                                      lowPrices[selectedCandleIndex]--;
                                    });
                                  }

                                  ToastService().showToastMessage("전체 한칸 아래로");
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(8), // 버튼 크기 조절
                                ),
                                child: Icon(Icons.arrow_circle_down)
                            ),
                          ),
                        ],
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
                          backgroundColor: selectedCandleIndex == index
                              ? Colors.black26
                              : Colors.white70, // 선택된 버튼 색상 변경
                        ),
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // 텍스트 굵게
                            color: selectedCandleIndex == index
                                ? Colors.white
                                : Colors.black, // 선택된 버튼 텍스트 색상 변경
                          ),
                        ),
                      );
                    }),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildPriceInputRow(PriceType.open, openPrices, PriceType.close, closePrices, selectedCandleIndex),
                        Container(
                          margin: EdgeInsets.zero,
                          height: 1.0,
                          color: Colors.black12,
                        ),
                        buildPriceInputRow(PriceType.high, highPrices, PriceType.low, lowPrices, selectedCandleIndex),
                      ],
                    ),
                  ),
                ],
              ),
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
          );
        },
      ),
      bottomNavigationBar: const BottomBannerAd(),
    );
  }

  Widget buildPriceInputRow(PriceType type1, List<int> prices1, PriceType type2,
      List<int> prices2, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildSinglePriceInput(type1, prices1, index),
        Container(
          height: 30, // Divider의 높이를 지정
          child: VerticalDivider(
            color: Colors.black12,
            thickness: 1,
          ),
        ),
        buildSinglePriceInput(type2, prices2, index),
      ],
    );
  }

  Widget buildSinglePriceInput(PriceType type, List<int> prices, int index) {
    String label = '';
    if (type == PriceType.open) {
      label = '시가';
    } else if (type == PriceType.close) {
      label = '종가';
    } else if (type == PriceType.high) {
      label = '고가';
    } else if (type == PriceType.low) {
      label = '저가';
    }
    Color textColor = Colors.black;

    // 고가와 저가에 따른 색상 변경
    if (type == PriceType.high) {
      textColor = lang == 'ko' ? Colors.red : Colors.green;
    } else if (type == PriceType.low) {
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
        SizedBox(
          width: 16,
        ), // 텍스트와 아이콘 사이의 간격 조절
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

  void adjustPrices(int index, PriceType type) {
    if (index < 0) {
      index = 0;
    }
    if (9 < index) {
      index = 9;
    }
    setState(() {
      if (type == PriceType.open || type == PriceType.close) {
        if (openPrices[index] > highPrices[index]) {
          highPrices[index] = openPrices[index];
        }
        if (openPrices[index] < lowPrices[index]) {
          lowPrices[index] = openPrices[index];
        }
        if (closePrices[index] > highPrices[index]) {
          highPrices[index] = closePrices[index];
        }
        if (closePrices[index] < lowPrices[index]) {
          lowPrices[index] = closePrices[index];
        }
      } else if (type == PriceType.high) {
        if (highPrices[index] < openPrices[index]) {
          openPrices[index] = highPrices[index];
        }
        if (highPrices[index] < closePrices[index]) {
          closePrices[index] = highPrices[index];
        }
        if (highPrices[index] < lowPrices[index]) {
          lowPrices[index] = highPrices[index];
        }
      } else if (type == PriceType.low) {
        if (lowPrices[index] > openPrices[index]) {
          openPrices[index] = lowPrices[index];
        }
        if (lowPrices[index] > closePrices[index]) {
          closePrices[index] = lowPrices[index];
        }
        if (lowPrices[index] > highPrices[index]) {
          highPrices[index] = lowPrices[index];
        }
      }
      savePrices();
    });
  }

  void savePrices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'openPrices', openPrices.map((e) => e.toString()).toList());
    prefs.setStringList(
        'closePrices', closePrices.map((e) => e.toString()).toList());
    prefs.setStringList(
        'highPrices', highPrices.map((e) => e.toString()).toList());
    prefs.setStringList(
        'lowPrices', lowPrices.map((e) => e.toString()).toList());
  }

  void sendPattern(double screenHeight) async {
    // 로딩 상태를 true로 설정
    ref.read(isPatternLoadingProvider.notifier).state = true;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedMarket', selectedMarket);

    RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    String encodedDrawing = base64Encode(pngBytes);

    String url = dotenv.env["PATTERN_SEARCH_API_URL"] ?? "";
    String market = selectedMarket == '한국' ? 'kospi_daq' : 'nyse_naq';
    String lang = await LanguagePreference.getLanguageSetting();
    String pattern = openPrices.join() + closePrices.join() + highPrices.join() + lowPrices.join();

    Map<String, dynamic> body = {
      'pattern': pattern,
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
        PatternResultManager.initializePatternResult(
            res: results,
            pattern: encodedDrawing,
            mkt: market,
            language: lang);

        ref.read(isPatternLoadingProvider.notifier).state = false;

        PatternResultManager.showPatternResult(context);

      } else {
        print('Failed to send data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending data to the API: $e');
    } finally {
      // 로딩 상태를 false로 설정
      ref.read(isPatternLoadingProvider.notifier).state = false;
    }
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
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(2, y - 8));
      }

      // 회색 실선 그리기
      if (highlightedRowIndex != null && highlightedRowIndex == i) {
        axisPaint.color = Colors.orange; // 드래그 중인 가로선 색상 변경
      } else {
        axisPaint.color = Colors.black12; // 기본 색상
      }
      canvas.drawLine(
          Offset(15, y), Offset(size.width - marginWidth, y), axisPaint);
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
          Rect.fromLTWH(
              x - marginWidth, marginHeight, gridWidth, chartHeight),
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

    if(!containsNumber(9, openPrices, closePrices, highPrices, lowPrices)) {
      Paint backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.red.withOpacity(0.05);
      canvas.drawRect(
        Rect.fromLTWH(
            marginWidth, marginHeight, gridWidth * 7, gridHeight),
        backgroundPaint,
      );
    }

    if(!containsNumber(0, openPrices, closePrices, highPrices, lowPrices)) {
      Paint backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.red.withOpacity(0.05);
      canvas.drawRect(
        Rect.fromLTWH(
            marginWidth, marginHeight + gridHeight * 8, gridWidth * 7, gridHeight),
        backgroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class HalfRedHalfBluePainter extends CustomPainter {
  final String lang;

  HalfRedHalfBluePainter({required this.lang});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

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

bool containsNumber(int num, List<int> openPrices, List<int> closePrices, List<int> highPrices, List<int> lowPrices) {
  return openPrices.contains(num) || closePrices.contains(num) || highPrices.contains(num) || lowPrices.contains(num);
}
