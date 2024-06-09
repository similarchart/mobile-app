import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/screen/pattern_search/pattern_result.dart';
import 'package:web_view/screen/home_screen_module/searching_timer.dart';
import 'package:web_view/services/preferences.dart';
import 'package:web_view/component/bottom_banner_ad.dart';
import 'package:web_view/component/interstitial_ad_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:math';
import 'package:web_view/providers/home_screen_state_providers.dart';
import 'package:web_view/services/toast_service.dart';
import 'package:web_view/providers/search_state_providers.dart';
import 'package:web_view/screen/pattern_search/candlestick_chart_painter.dart';
import 'package:web_view/screen/pattern_search/half_circle_painter.dart';

enum PriceType { open, close, high, low }

class PatternBoard extends ConsumerStatefulWidget {

  const PatternBoard({super.key});

  @override
  _PatternBoardState createState() => _PatternBoardState();
}

class _PatternBoardState extends ConsumerState<PatternBoard>
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

  int? highlightedRowIndex;

  Client? _httpClient;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();

    loadPreferences();
    loadPrices(); // Load prices from SharedPreferences
    loadLanguagePreference(); // 언어 설정 로드

    // 페이지가 초기화될 때 세로 모드로 설정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (!PatternResultManager.isResultExist()) {
      ToastService().showToastMessage("원하는 패턴을 그려보세요!");
    }
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
    _httpClient?.close(); // HTTP 요청 취소

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

        double screenWidth = MediaQuery.of(context).size.width;
        double chartHeight = screenWidth - 110;
        double chartWidth = screenWidth - 110;
        double gridHeight = chartHeight / 10;
        double gridWidth = chartWidth / 8;
        double heightMargin = gridHeight / 2; // 상단 여백

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: AppColors.primaryColor,
            title: const Text(
              '캔들패턴검색',
              style: TextStyle(
                color: AppColors.textColor,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              const SizedBox(width: 10.0),
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
              const SizedBox(width: 10.0),
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: (selectedMarket != "시장" &&
                      !isLoading &&
                      !isCooldownActive &&
                      containsNumber(9, openPrices, closePrices, highPrices,
                          lowPrices) &&
                      containsNumber(0, openPrices, closePrices, highPrices,
                          lowPrices))
                      ? AppColors.textColor
                      : AppColors.secondaryColor,
                ),
                onPressed: (selectedMarket != "시장" &&
                    !isLoading &&
                    !isCooldownActive &&
                    containsNumber(9, openPrices, closePrices, highPrices,
                        lowPrices) &&
                    containsNumber(
                        0, openPrices, closePrices, highPrices, lowPrices))
                    ? () {
                  SearchingTimer(ref).startTimer(10);
                  sendPattern();
                }
                    : () {
                  if (selectedMarket == "시장") {
                    ToastService().showToastMessage("시장을 선택해 주세요.");
                  } else if (isLoading) {
                    ToastService().showToastMessage("잠시만 기다려주세요.");
                  } else if (isCooldownActive) {
                    ToastService().showToastMessage(
                        "$remainingTimeInSeconds초 후 재검색이 가능합니다.");
                  } else if (!containsNumber(9, openPrices, closePrices,
                      highPrices, lowPrices)) {
                    ToastService().showToastMessage(
                        "하나 이상의 캔들스틱을 맨 위 칸까지 그려주세요.");
                  } else if (!containsNumber(0, openPrices, closePrices,
                      highPrices, lowPrices)) {
                    ToastService().showToastMessage(
                        "하나 이상의 캔들스틱을 맨 아래 칸까지 그려주세요.");
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
                          RenderBox box =
                          context.findRenderObject() as RenderBox;
                          Offset localPosition =
                          box.globalToLocal(details.globalPosition);

                          // 모눈의 영역 계산
                          double leftMargin =
                              (constraints.maxWidth - chartWidth) / 2;

                          if (localPosition.dx >= leftMargin &&
                              localPosition.dx <= screenWidth - leftMargin) {
                            setState(() {
                              selectedCandleIndex =
                                  ((localPosition.dx - leftMargin) / gridWidth)
                                      .floor() ~/
                                      2;
                              selectedPriceType = null;

                              // 터치한 위치와 시가/종가/고가/저가의 위치를 비교하여 선택된 항목 설정
                              double openPriceY = chartHeight -
                                  openPrices[selectedCandleIndex] * gridHeight -
                                  heightMargin;
                              double closePriceY = chartHeight -
                                  closePrices[selectedCandleIndex] *
                                      gridHeight -
                                  heightMargin;
                              double highPriceY = chartHeight -
                                  highPrices[selectedCandleIndex] * gridHeight -
                                  heightMargin;
                              double lowPriceY = chartHeight -
                                  lowPrices[selectedCandleIndex] * gridHeight -
                                  heightMargin;

                              if (localPosition.dy >=
                                  openPriceY - heightMargin &&
                                  localPosition.dy <
                                      openPriceY + heightMargin) {
                                selectedPriceType = PriceType.open;
                              } else if (localPosition.dy >=
                                  closePriceY - heightMargin &&
                                  localPosition.dy <
                                      closePriceY + heightMargin) {
                                selectedPriceType = PriceType.close;
                              } else if (localPosition.dy >=
                                  highPriceY - heightMargin &&
                                  localPosition.dy <
                                      highPriceY + heightMargin) {
                                selectedPriceType = PriceType.high;
                              } else if (localPosition.dy >=
                                  lowPriceY - heightMargin &&
                                  localPosition.dy < lowPriceY + heightMargin) {
                                selectedPriceType = PriceType.low;
                              }

                              highlightedRowIndex = ((chartHeight -
                                  localPosition.dy +
                                  heightMargin) /
                                  gridHeight)
                                  .floor();
                            });
                          }
                        },
                        onPanUpdate: (DragUpdateDetails details) {
                          RenderBox box =
                          context.findRenderObject() as RenderBox;
                          Offset localPosition =
                          box.globalToLocal(details.globalPosition);
                          double margin = gridHeight / 2; // 상단 여백, 필요시 조정
                          int touchedRow = max(
                              0,
                              min(
                                  9,
                                  ((chartHeight - localPosition.dy + margin) /
                                      gridHeight)
                                      .floor()));
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
                            adjustPrices(
                                selectedCandleIndex, selectedPriceType!);
                          }
                        },
                        onPanEnd: (DragEndDetails details) {
                          setState(() {
                            selectedPriceType = null;
                            highlightedRowIndex = null;
                          });
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
                                        selectedCandleIndex:
                                        selectedCandleIndex,
                                        lang: lang, // 추가
                                        highlightedRowIndex:
                                        highlightedRowIndex, // 추가
                                      ),
                                      child: Container(),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -5, // 오른쪽에서 약간의 여백을 둠
                                top: 8, // 차트 높이의 절반 위치
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      // 시가와 종가 값을 바꾸는 로직
                                      int temp =
                                      openPrices[selectedCandleIndex];
                                      openPrices[selectedCandleIndex] =
                                      closePrices[selectedCandleIndex];
                                      closePrices[selectedCandleIndex] = temp;
                                      adjustPrices(
                                          selectedCandleIndex, PriceType.open);
                                      adjustPrices(
                                          selectedCandleIndex, PriceType.close);
                                    });

                                    ToastService().showToastMessage("시가 종가 반전",
                                        durationInSeconds: 0.5,
                                        gravity: ToastGravity.CENTER);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(8), // 버튼 크기 조절
                                  ),
                                  child: CustomPaint(
                                    size: const Size(24, 24), // 원형 버튼의 크기
                                    painter: HalfCirclePainter(lang: lang),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -5,
                                top: 60, // 차트 높이의 절반 위치
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      highPrices[selectedCandleIndex] = max(
                                          openPrices[selectedCandleIndex],
                                          closePrices[selectedCandleIndex]);
                                      lowPrices[selectedCandleIndex] = min(
                                          openPrices[selectedCandleIndex],
                                          closePrices[selectedCandleIndex]);
                                      adjustPrices(
                                          selectedCandleIndex, PriceType.open);
                                    });

                                    ToastService().showToastMessage("꼬리 제거",
                                        durationInSeconds: 0.5,
                                        gravity: ToastGravity.CENTER);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(8), // 버튼 크기 조절
                                  ),
                                  child: Image.asset(
                                    'assets/not_tail.png',
                                    width: 24.0,
                                    height: 24.0,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -5, // 오른쪽에서 약간의 여백을 둠
                                top: 112, // 차트 높이의 절반 위치
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      openPrices[selectedCandleIndex] = 4;
                                      closePrices[selectedCandleIndex] = 5;
                                      highPrices[selectedCandleIndex] = 6;
                                      lowPrices[selectedCandleIndex] = 3;
                                      adjustPrices(
                                          selectedCandleIndex, PriceType.open);
                                    });

                                    ToastService().showToastMessage("기본 캔들",
                                        durationInSeconds: 0.5,
                                        gravity: ToastGravity.CENTER);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(8), // 버튼 크기 조절
                                  ),
                                  child: Image.asset(
                                    lang == 'ko'
                                        ? 'assets/default_red.png'
                                        : 'assets/default_green.png',
                                    width: 24.0,
                                    height: 24.0,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -5, // 오른쪽에서 약간의 여백을 둠
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

                                      ToastService().showToastMessage("전체 한칸 위",
                                          durationInSeconds: 0.5,
                                          gravity: ToastGravity.CENTER);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(8), // 버튼 크기 조절
                                    ),
                                    child: const Icon(Icons.arrow_circle_up)),
                              ),
                              Positioned(
                                right: -5, // 오른쪽에서 약간의 여백을 둠
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

                                      ToastService().showToastMessage(
                                          "전체 한칸 아래",
                                          durationInSeconds: 0.5,
                                          gravity: ToastGravity.CENTER);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(8), // 버튼 크기 조절
                                    ),
                                    child: const Icon(Icons.arrow_circle_down)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
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
                                    padding: const EdgeInsets.all(8), // 버튼 크기 조절
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
                            buildPriceInputRow(
                                PriceType.open,
                                openPrices,
                                PriceType.close,
                                closePrices,
                                selectedCandleIndex),
                            Container(
                              margin: EdgeInsets.zero,
                              height: 1.0,
                              color: Colors.black12,
                            ),
                            buildPriceInputRow(PriceType.high, highPrices,
                                PriceType.low, lowPrices, selectedCandleIndex),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: const BottomBannerAd(),
        );
      }),
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
          child: const VerticalDivider(
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
            fontSize: 17
          ),
        ),
        const SizedBox(
          width: 14,
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
              child: const Icon(Icons.arrow_circle_up, size: 34,),
            ),
            const SizedBox(width: 10), // 아이콘 사이의 간격을 좁게 설정
            InkWell(
              onTap: () {
                setState(() {
                  if (prices[index] > 0) {
                    prices[index]--;
                    adjustPrices(index, type);
                  }
                });
              },
              child: const Icon(Icons.arrow_circle_down, size: 34,),
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

  void sendPattern() async {
    // 로딩 상태를 true로 설정
    ref.read(isLoadingProvider.notifier).state = true;
    savePrices();

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
    String pattern = openPrices.join() +
        closePrices.join() +
        highPrices.join() +
        lowPrices.join();

    Map<String, dynamic> body = {
      'pattern': pattern,
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
        PatternResultManager.initializePatternResult(
            res: results, pattern: encodedDrawing, mkt: market);

        ref.read(isLoadingProvider.notifier).state = false;
        String? resultUrl = await PatternResultManager.showPatternResult(context);
        Navigator.pop(context, resultUrl); // URL을 반환하며 화면을 닫음
      } else {
        print('Failed to send data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending data to the API: $e');
    } finally {
      // 로딩 상태를 false로 설정
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }
}
