import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:web_view/screen/favorite_screen.dart';
import 'package:web_view/services/toast_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/button/home.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/screen/settings_screen.dart';
import 'package:web_view/screen/splash_screen.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/model/history_item.dart';

import '../model/recent_item.dart';
import 'drawing_board.dart';

final homeUrl = Uri.parse('https://www.similarchart.com?lang=ko');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebViewController controller = WebViewController();
  bool _isFirstLoad = true; // 앱이 처음 시작될 때만 true
  bool _showFloatingActionButton = false; // FAB 표시 여부
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadInitialUrl(); // 초기 URL 로드
  }

  Future<void> loadInitialUrl() async {
    String lang =
        await LanguagePreference.getLanguageSetting(); // 현재 설정된 언어를 불러옵니다.
    Uri homeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("SimilarChartFinder/1.0/dev")
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // URL 변경을 감지하여 FAB 표시 여부를 결정
            bool startsWithDomestic = request.url
                .startsWith('https://m.stock.naver.com/domestic/stock/');
            bool startsWithWorld = request.url
                .startsWith('https://m.stock.naver.com/worldstock/stock/');
            setState(() {
              _showFloatingActionButton = startsWithDomestic || startsWithWorld;
              _isLoading = true;
            });
            return NavigationDecision.navigate; // 네비게이션을 계속 진행
          },
          onPageStarted: (String url) {
            print('yes');
            setState(() {
              _isLoading = false;
            });
          },
          onPageFinished: (String url) async {
            // 현재 URL에 따라 플로팅 버튼의 표시 여부를 결정
            bool startsWithDomestic =
                url.startsWith('https://m.stock.naver.com/domestic/stock/');
            bool startsWithWorld =
                url.startsWith('https://m.stock.naver.com/worldstock/stock/');
            setState(() {
              _showFloatingActionButton = startsWithDomestic || startsWithWorld;
            });

            if (_isFirstLoad) {
              setState(() {
                _isFirstLoad = false; // 첫 페이지 로드가 완료되면 false로 설정
              });
            }
            _addCurrentUrlToHistory(url);
            _addCurrentUrlToRecent(url);
          },
        ),
      )
      ..loadRequest(homeUrl);
  }

  @override
  Widget build(BuildContext context) {
    // BottomNavigationBar의 높이를 정의합니다. 실제 높이에 따라 조정할 수 있습니다.
    const double bottomNavigationBarHeight = 60;
    // FloatingActionButton의 반지름입니다. 실제 크기에 따라 조정할 수 있습니다.
    const double fabRadius = 18;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (await controller.canGoBack()) {
          controller.goBack();
          return;
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('앱 종료', style: TextStyle(color: AppColors.textColor)),
              content: Text('앱을 종료하시겠습니까?',
                  style: TextStyle(color: AppColors.textColor)),
              backgroundColor: AppColors.primaryColor,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '아니오',
                    style: TextStyle(
                      color: AppColors.textColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child:
                      Text('예', style: TextStyle(color: AppColors.textColor)),
                ),
              ],
            ),
          );
        }
      },
      child: Stack(
        // Stack을 Scaffold 바깥에 배치
        children: [
          SafeArea(
            child: Scaffold(
              bottomNavigationBar: ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: bottomNavigationBarHeight),
                child: BottomAppBar(
                  color: AppColors.primaryColor,
                  child: Row(
                    children: <Widget>[
                      buildBottomIcon(
                          Icons.brush, '드로잉검색', () => onDrawingSearchTap()),
                      buildBottomIcon(Icons.trending_up, '패턴 검색',
                          () => onRealTimeSearchTap()),
                      buildBottomIcon(
                          Icons.home, '홈', () => onHomeTap(controller)),
                      buildBottomIcon(
                          Icons.history, '최근본종목', () => onFavoriteTap(context)),
                      buildBottomIcon(
                          Icons.settings, '설정', () => onSettingsTap(context)),
                    ],
                  ),
                ),
              ),
              body: WebViewWidget(
                controller: controller,
              ),
            ),
          ),
          _isFirstLoad
              ? const SplashScreen()
              : Container(), // 첫 로드면 스플래시 화면 띄우기
          Positioned(
            right: 16,
            bottom: bottomNavigationBarHeight +
                fabRadius, // FAB를 BottomNavigationBar 바로 위에 위치시킵니다.
            child: _showFloatingActionButton
                ? FloatingActionButton(
                    onPressed: () {
                      // FAB 클릭 시 실행될 동작
                      _goStockInfoPage();
                    },
                    child: Image.asset('assets/logo_2.png'), // 로컬 에셋 이미지를 사용
                    backgroundColor: Colors.transparent, // 배경색을 투명하게 설정
                    elevation: 0, // 그림자 제거
                  )
                : Container(),
          ),
          _isLoading
              ? Positioned.fill(
            child: IgnorePointer(
              ignoring: true, // 모든 터치 이벤트 무시
              child: Container(
                color: Colors.black.withOpacity(0.5), // 반투명 오버레이
                child: Center(
                  child: FutureBuilder<String>(
                    future: LanguagePreference.getLanguageSetting(), // 현재 언어 설정을 가져옵니다.
                    builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // 언어 설정을 로딩 중이면 기본 로딩 인디케이터 표시
                      } else if (snapshot.hasData) {
                        String lang = snapshot.data!;
                        // 언어 설정에 따라 다른 GIF 이미지 로드
                        return Image.asset(lang == 'ko'
                            ? 'assets/loading_image.gif'
                            : 'assets/loading_image_en.gif');
                      } else {
                        return Text('로딩 이미지를 불러올 수 없습니다.');
                      }
                    },
                  ),
                ),
              ),
            ),
          )
              : Container(),

        ],
      ),
    );
  }

  Widget buildBottomIcon(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: Colors.white,
              size: 20,), // 아이콘 색상 설정
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: Colors.white)), // 텍스트 색상 및 스타일 설정
          ],
        ),
      ),
    );
  }

  Future<void> _goStockInfoPage() async {
    // 현재 웹뷰의 URL을 가져옵니다.
    String currentUrl = await controller.currentUrl() ?? '';
    print('현재 URL: $currentUrl'); // 현재 URL 로그 출력

    // CodeValue를 추출하기 위한 정규 표현식입니다.
    RegExp regExp = RegExp(r'stock/([A-Z0-9.]+)/total');
    final matches = regExp.firstMatch(currentUrl);

    if (matches != null && matches.groupCount >= 1) {
      String codeValue = matches.group(1)!; // 'stock'과 'total' 사이의 값입니다.
      print('추출된 CodeValue: $codeValue'); // 추출된 CodeValue 로그 출력

      if (codeValue.contains('.')) {
        codeValue = codeValue.split('.')[0]; // '.'을 기준으로 분할하여 첫 번째 값을 사용합니다.
        print('수정된 CodeValue: $codeValue'); // 수정된 CodeValue 로그 출력
      }

      // 사용자의 언어 설정을 가져옵니다.
      String currentLang = await LanguagePreference.getLanguageSetting();

      // 최종 URL을 구성합니다.
      String finalUrl =
          'https://www.similarchart.com/stock_info/?code=$codeValue&lang=$currentLang';

      // 구성한 URL로 웹뷰를 이동시킵니다.
      controller.loadRequest(Uri.parse(finalUrl));
    }
  }

  _addCurrentUrlToRecent(String url) async {
    Uri uri = Uri.parse(url);
    bool startsWithDomestic =
        url.startsWith('https://m.stock.naver.com/domestic/stock/');
    bool startsWithWorld =
        url.startsWith('https://m.stock.naver.com/worldstock/stock/');

    String codeValue;
    String? title;
    if (uri.queryParameters.containsKey('code')) {
      codeValue = uri.queryParameters['code']!;
      title = await controller.getTitle();
    } else if (startsWithWorld || startsWithDomestic) {
      String? ogTitle = (await controller.runJavaScriptReturningResult(
              "document.querySelector('meta[property=\"og:title\"]').content;"))
          as String?;

      // JavaScript에서 반환된 JSON 문자열에서 실제 문자열 값을 추출합니다.
      title = jsonDecode(ogTitle!);
      // 정규 표현식을 사용하여 'stock'과 'total' 사이의 값을 추출
      RegExp regExp = RegExp(r'stock/(\d+)/total');
      final matches = regExp.firstMatch(url);
      if (matches != null && matches.groupCount >= 1) {
        codeValue = matches.group(1)!; // 1번 그룹이 'stock'과 'total' 사이의 값
      } else {
        return;
      }
    } else {
      return;
    }
    if (title == null) {
      return;
    }

    String stockName = title.split(' - ').first.trimRight();

    final Box<RecentItem> recentBox = Hive.box<RecentItem>('recent');

// 똑같은 code를 가진 element의 키를 찾기
    dynamic existingItemKey;
    recentBox.toMap().forEach((key, item) {
      if (item.code == codeValue) {
        existingItemKey = key;
      }
    });

// 만약 존재한다면, 기존 아이템 삭제
    if (existingItemKey != null) {
      await recentBox.delete(existingItemKey);
    }

// 새로운 RecentItem 생성
    final recentItem = RecentItem(
      dateVisited: DateTime.now(),
      code: codeValue,
      name: stockName,
      isFav: false,
    );

// 새 아이템 추가
    await recentBox.add(recentItem);
  }

  _addCurrentUrlToHistory(String url) async {
    String? title = await controller.getTitle();
    final Box<HistoryItem> historyBox = Hive.box<HistoryItem>('history');
    final historyItem =
        HistoryItem(url: url, title: title ?? url, dateVisited: DateTime.now());
    await historyBox.add(historyItem);
  }

  onFavoriteTap(BuildContext context) async {
    String? url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoriteScreen()),
    );
    if (url != null) {
      controller.loadRequest(Uri.parse(url));
    }
  }

  // '설정' 버튼 탭 처리를 위한 별도의 함수
  onSettingsTap(BuildContext context) async {
    // 원래 설정된 언어를 저장
    String originalLang = await LanguagePreference.getLanguageSetting();

    // 설정 화면으로 이동
    final url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );

    // 설정에서 돌아온 후 언어 설정이 변경되었는지 확인
    String currentLang = await LanguagePreference.getLanguageSetting();
    if (url == null && originalLang == currentLang) {
      return;
    }

    Uri currentUri;
    if (url == null) {
      String? currentUrl = await controller.currentUrl();
      currentUri = Uri.parse(currentUrl ?? "");
    } else {
      // 방문기록을 눌렀으면 url문자열 반환
      currentUri = Uri.parse(url);
    }

    // 현재 URI의 쿼리 매개변수를 변경하되, lang 매개변수만 새로운 값으로 설정합니다.
    Map<String, String> newQueryParameters =
        Map.from(currentUri.queryParameters);
    newQueryParameters['lang'] = currentLang; // lang 매개변수 업데이트

    // 변경된 쿼리 매개변수를 포함하여 새로운 URI 생성
    Uri newUri = currentUri.replace(queryParameters: newQueryParameters);

    // 새로운 URI로 웹뷰를 로드합니다.
    controller.loadRequest(newUri);
  }

  void onDrawingSearchTap() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height * 2 / 3;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(0),
          child: Container(
            width: width,
            height: height,
            child: DrawingBoard(),
          ),
        );
      },
    );
  }

  onRealTimeSearchTap() {
    ToastService().showToastMessage("곧 공개됩니다");
  }
}
