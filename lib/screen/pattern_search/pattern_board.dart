import 'dart:async';

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
import 'package:web_view/services/check_internet.dart';
import 'package:web_view/system/logger.dart';
import '../../l10n/app_localizations.dart';
import 'example_candle_painter.dart';

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
  String selectedMarket = '';
  List<String> countries = [];
  int selectedCandleIndex = 0; // 선택된 캔들스틱의 인덱스
  String lang = 'ko'; // 기본 언어 설정을 한국어로
  PriceType? selectedPriceType;
  GlobalKey repaintBoundaryKey = GlobalKey();
  int? highlightedRowIndex;
  Client? _httpClient;
  late AppLocalizations localizations;

  void _initializeValues() {
    selectedMarket = localizations.translate('market');
    countries = [
      localizations.translate('market'),
      localizations.translate('US'),
      localizations.translate('KR')
    ];

    // 초기화 시 selectedMarket이 리스트의 값 중 하나와 일치하는지 확인
    if (!countries.contains(selectedMarket)) {
      selectedMarket = countries.first;
    }
  }

  @override
  void initState() {
    super.initState();

    _httpClient = http.Client();

    loadPrices(); // Load prices from SharedPreferences
    loadLanguagePreference(); // 언어 설정 로드
    checkFirstLaunch();

    // 페이지가 초기화될 때 세로 모드로 설정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override // localizations 은 initState 이후 사용 가능하므로 localizations 이 필요한 초기화 코드는 여기로
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = AppLocalizations.of(context);
    _initializeValues();
    loadPreferences();

    if (!PatternResultManager.isResultExist()) {
      ToastService().showToastMessage(localizations.translate("draw_desired_pattern"));
    }
  }

  Future<void> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String storedMarket = prefs.getString('selectedMarket') ?? localizations.translate("market");
      selectedMarket = countries.contains(storedMarket) ? storedMarket : countries.first;
    });
  }

  Future<void> checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasLaunchedBefore = prefs.getBool('hasLaunchedBefore') ?? false;
    if (!hasLaunchedBefore) {
      showCandleGuideDialog();
      await prefs.setBool('hasLaunchedBefore', true);
    }
  }

  void showCandleGuideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              localizations.translate("how_to_draw_candlestick"),
              style: const TextStyle(fontSize: 22),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 13),
              SizedBox(
                height: 130,
                width: 130,
                child: CustomPaint(
                  painter: ExampleCandlePainter(),
                ),
              ),
              Text(
                '1. ${localizations.translate('lower_tail_end')}\n'
                    '2. ${localizations.translate('lower_body')}\n'
                    '3. ${localizations.translate('upper_body')}\n'
                    '4. ${localizations.translate('upper_tail_end')}\n\n'
                    '${localizations.translate('touch_and_drag')}',
                textAlign: TextAlign.center,
              ),
              const Divider(
                color: Colors.black,
                thickness: 2,
              ),
              Text(
                localizations.translate('draw_to_top_bottom'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(localizations.translate('ok')),
            ),
          ],
        );
      },
    );
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
            title: Row(
              children: [
                Text(
                  localizations.translate('pattern_search'),
                  style: const TextStyle(color: AppColors.textColor),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: showCandleGuideDialog,
                  color: AppColors.textColor,
                ),
              ],
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
                  color: (selectedMarket != localizations.translate('market') &&
                      !isLoading &&
                      !isCooldownActive &&
                      containsNumber(9, openPrices, closePrices, highPrices,
                          lowPrices) &&
                      containsNumber(0, openPrices, closePrices, highPrices,
                          lowPrices))
                      ? AppColors.textColor
                      : AppColors.secondaryColor,
                ),
                onPressed: (selectedMarket != localizations.translate('market') &&
                    !isLoading &&
                    !isCooldownActive &&
                    containsNumber(9, openPrices, closePrices, highPrices,
                        lowPrices) &&
                    containsNumber(
                        0, openPrices, closePrices, highPrices, lowPrices))
                    ? () {
                  sendPattern();
                }
                    : () {
                  if (selectedMarket == localizations.translate('market')) {
                    ToastService().showToastMessage(localizations.translate("select_market"));
                  } else if (isLoading) {
                    ToastService().showToastMessage(localizations.translate("please_wait"));
                  } else if (isCooldownActive) {
                    ToastService().showToastMessage(
                        localizations.translateWithArgs("remaining_time", [remainingTimeInSeconds]));
                  } else if (!containsNumber(9, openPrices, closePrices,
                      highPrices, lowPrices)) {
                    ToastService().showToastMessage(localizations.translate("draw_to_top_cell"));
                  } else if (!containsNumber(0, openPrices, closePrices,
                      highPrices, lowPrices)) {
                    ToastService().showToastMessage(localizations.translate("draw_to_bottom_cell"));
                  } else {
                    ToastService().showToastMessage(localizations.translate("unknown_error"));
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

                                    ToastService().showToastMessage(localizations.translate("open_close_reversal"),
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

                                    ToastService().showToastMessage(localizations.translate("remove_tail"),
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

                                    ToastService().showToastMessage(localizations.translate("default_candle"),
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

                                      ToastService().showToastMessage(localizations.translate("one_step_up"),
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
                                          localizations.translate("one_step_down"),
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
          // bottomNavigationBar: const BottomBannerAd(),
          bottomNavigationBar: Container(height: 60, color: AppColors.primaryColor),
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
      label = localizations.translate("opening_price");
    } else if (type == PriceType.close) {
      label = localizations.translate("closing_price");
    } else if (type == PriceType.high) {
      label = localizations.translate("high_price");
    } else if (type == PriceType.low) {
      label = localizations.translate("low_price");
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
        Padding(
          padding: const EdgeInsets.only(left: 8.0), // 왼쪽에 패딩 추가
          child: Text(
            '$label : ${prices[index]}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(
          width: 14,
        ), // 텍스트와 아이콘 사이의 간격 조절
        Row(
          children: [
            Container(
              width: 50, // 터치 영역 크기 설정
              height: 50,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (prices[index] < 9) {
                      prices[index]++;
                      adjustPrices(index, type);
                    }
                  });
                },
                child: const Center(
                  child: Icon(Icons.arrow_circle_up, size: 35), // 아이콘 크기 조정
                ),
              ),
            ),
            Container(
              width: 50, // 터치 영역 크기 설정
              height: 50,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (prices[index] > 0) {
                      prices[index]--;
                      adjustPrices(index, type);
                    }
                  });
                },
                child: const Center(
                  child: Icon(Icons.arrow_circle_down, size: 35), // 아이콘 크기 조정
                ),
              ),
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
    if (!await checkInternetConnection()) return;

    SearchingTimer(ref).startTimer(10);
    ref.read(isLoadingProvider.notifier).state = true;

    // API 호출 결과를 저장하기 위한 Completer
    Completer<Map<String, dynamic>> apiResultCompleter = Completer<Map<String, dynamic>>();

    // 백그라운드에서 API 호출을 수행
    _fetchPatternResult().then((apiResult) {
      apiResultCompleter.complete(apiResult);
    });

    // 전면 광고를 먼저 보여줌
    _adManager.showInterstitialAd(context, () async {
      // 광고가 닫히면 호출되는 콜백
      Map<String, dynamic> apiResult = await apiResultCompleter.future;
      _handleApiResponse(context, apiResult);
    });
  }

  Future<Map<String, dynamic>> _fetchPatternResult() async {
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
    String market = selectedMarket == localizations.translate("KR") ? 'kospi_daq' : 'nyse_naq';
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

  void _handleApiResponse(BuildContext context, Map<String, dynamic> response) async {
    ref.read(isLoadingProvider.notifier).state = false;

    if (response['success']) {
      String? resultUrl = await PatternResultManager.showPatternResult(context);
      Navigator.pop(context, resultUrl); // URL을 반환하며 화면을 닫음
    } else {
      Log.instance.e('Error: ${response['error']}');
      // 에러 메시지를 표시하는 로직 추가 가능
    }
  }
}
