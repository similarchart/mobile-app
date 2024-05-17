import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_view/screen/home_screen_module/floating_action_button_manager.dart';
import 'package:web_view/services/preferences.dart';
import 'package:web_view/screen/splash_screen.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/screen/home_screen_module/bottom_navigation_builder.dart';
import 'package:web_view/screen/home_screen_module/web_view_manager.dart';
import 'package:web_view/screen/home_screen_module/bottom_navigation_tap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_view/constants/urls.dart';
import 'dart:async';

import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final GlobalKey webViewKey = GlobalKey();
  late String homeUrl;
  Uri myUrl = Uri.parse(Urls.naverHomeUrl);
  late final InAppWebViewController? webViewController;
  late WebViewManager webViewManager;
  late BottomNavigationTap bottomNavigationTap;
  late FloatingActionButtonManager fabManager;
  late InAppWebViewSettings options;
  bool _isFirstLoad = true; // 앱이 처음 시작될 때만 true(splash screen을 위해)
  bool _showFloatingActionButton = false; // FAB 표시 여부
  bool _isLoading = false; // 로딩바 표시 여부
  bool _isPageLoading = false; // 로딩바 표시 여부
  String subPageLabel = ''; // 하단바 홈 버튼 왼쪽의 서브 페이지 버튼 이름
  String homePageLabel = ''; // 하단바 홈 버튼 이름
  bool didScrollDown = true; // 하단 바의 초기 상태
  bool bottomBarFixedPref = true;
  double startY = 0.0; // 드래그 시작 지점의 Y 좌표
  bool isDragging = false; // 드래그 중인지 여부
  bool _isOnHomeScreen = true; // 현재 화면이 HomeScreen인지 여부

  late PullToRefreshController pullToRefreshController; // 당겨서 새로고침 컨트롤러

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override // 현재 화면(라우트)이 다른 화면에서 팝(pop)되어 다시 활성화되었을 때 호출
  Future<void> didPopNext() async {
    _loadPreferences();
    setState(() {
      _isOnHomeScreen = true;
    });
  }

  @override // 다른 화면으로 넘어갈 때 실행되는 로직
  void didPushNext() {
    setState(() {
      _isOnHomeScreen = false;
    });
  }

  Future<void> _loadPreferences() async {
    bottomBarFixedPref = await BottomBarPreference
        .getIsBottomBarFixed(); // SharedPreferences에서 설정값 불러오기
    String preferPage = await MainPagePreference.getMainPageSetting();
    if (preferPage == 'naver') {
      setState(() {
        subPageLabel = '비슷한차트';
        homePageLabel = '네이버증권';
      });
    } else if (preferPage == 'chart') {
      setState(() {
        subPageLabel = '네이버증권';
        homePageLabel = '비슷한차트';
      });
    }
    String lang = await LanguagePreference.getLanguageSetting();
    String page = await MainPagePreference.getMainPageSetting();
    if (page == 'chart') {
      homeUrl = 'https://www.similarchart.com?lang=$lang';
      options = InAppWebViewSettings(
        useShouldOverrideUrlLoading: true, // URL 로딩 제어
        mediaPlaybackRequiresUserGesture: false, // 미디어 자동 재생
        javaScriptEnabled: true, // 자바스크립트 실행 여부
        javaScriptCanOpenWindowsAutomatically: true, // 팝업 여부
        useHybridComposition: true, // 하이브리드 사용을 위한 안드로이드 웹뷰 최적화
        supportMultipleWindows: true, // 멀티 윈도우 허용
        allowsInlineMediaPlayback: true, // 웹뷰 내 미디어 재생 허용
      );
    } else {
      homeUrl = Urls.naverHomeUrl;
      options = InAppWebViewSettings(
        useShouldOverrideUrlLoading: true, // URL 로딩 제어
        mediaPlaybackRequiresUserGesture: false, // 미디어 자동 재생
        javaScriptEnabled: true, // 자바스크립트 실행 여부
        javaScriptCanOpenWindowsAutomatically: true, // 팝업 여부
        useHybridComposition: true, // 하이브리드 사용을 위한 안드로이드 웹뷰 최적화
        supportMultipleWindows: true, // 멀티 윈도우 허용
        allowsInlineMediaPlayback: true, // 웹뷰 내 미디어 재생 허용
      );
    }
  }

  void startTimer(webViewController) {
    if(webViewController == null){
      return;
    }

    Timer.periodic(Duration(seconds: 1), (Timer timer) async {
      // 여기에 반복 실행하고 싶은 함수를 호출합니다.
      WebUri? uri = await webViewController?.getUrl();
      String currentUrl = uri.toString();
      if (
          ! _isFirstLoad &&
          _isOnHomeScreen &&
          !_isLoading &&
          !_isPageLoading) {
        webViewManager.addCurrentUrlToRecent(currentUrl, webViewController);
        webViewManager.removeDuplicateRecentItem();
        updateFloatingActionButtonVisibility(currentUrl);
        await webViewManager.saveCookies(webViewController); // 앱 시작 시 쿠키 로드
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    webViewManager = WebViewManager();
    bottomNavigationTap = BottomNavigationTap((isLoading) {
      setState(() {
        _isLoading = isLoading;
      });
    });

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      // 플랫폼별 새로고침
      onRefresh: () async {
        if(webViewController != null) {
          if (Platform.isAndroid) {
            webViewController!.reload();
          } else if (Platform.isIOS) {
            WebUri uri = webViewController!.getUrl() as WebUri;
            WebViewManager.loadUrl(webViewController!, uri.toString());
          }
        }
      },
    );
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
        if (webViewController != null && await webViewController!.canGoBack()) {
          webViewController?.goBack();
          return;
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('앱 종료',
                  style: TextStyle(color: AppColors.textColor)),
              content: const Text('앱을 종료하시겠습니까?',
                  style: TextStyle(color: AppColors.textColor)),
              backgroundColor: AppColors.primaryColor,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
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
                  child: const Text('예',
                      style: TextStyle(color: AppColors.textColor)),
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
              resizeToAvoidBottomInset: false,
              body: bottomBarFixedPref
                  ? Column(
                      children: [
                        Expanded(
                          child: createWebView(),
                        ),
                        SizedBox(height: 60, child: _buildBottomNavigationBar())
                      ],
                    )
                  : Stack(
                      children: [
                        // 웹뷰를 Stack의 바닥에 위치시키기
                        Positioned.fill(
                          child: Listener(
                            onPointerDown: (PointerDownEvent event) {
                              startY = event.position.dy; // 시작 지점 저장
                              isDragging = true; // 드래그 시작
                            },
                            onPointerMove: (PointerMoveEvent event) {
                              if (isDragging) {
                                double distance =
                                    startY - event.position.dy; // 이동 거리 계산
                                if (distance > 70) {
                                  // 50픽셀 이상 위로 드래그
                                  setState(() {
                                    didScrollDown = false;
                                  });
                                  isDragging = false; // 드래그 중지
                                } else if (distance < -70) {
                                  // 50픽셀 이상 아래로 드래그
                                  setState(() {
                                    didScrollDown = true;
                                  });
                                  isDragging = false; // 드래그 중지
                                }
                              }
                            },
                            onPointerUp: (PointerUpEvent event) {
                              isDragging = false; // 드래그 종료
                            },
                            child: createWebView(),
                          ),
                        ),
                        // 하단바를 웹뷰 위에 배치하기
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: 60,
                            transform: Matrix4.translationValues(
                                0.0, didScrollDown ? 0.0 : 60, 0.0),
                            child: _buildBottomNavigationBar(),
                          ),
                        ),
                      ],
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
                ? fabManager.buildFloatingActionButton(true)
                : Container(),
          ),
          _isLoading
              ? Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5), // 반투명 오버레이
                    child: Center(
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
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  Widget createWebView() {
    return InAppWebView(
      key: webViewKey,
      // 시작 페이지
      initialUrlRequest:URLRequest(url: WebUri(homeUrl),
          headers: {
              "SimilarChart-App": "SimilarChartFinder/1.0/dev",
          }),
      initialSettings: options,
      // 당겨서 새로고침 컨트롤러 정의
      pullToRefreshController: pullToRefreshController,
      // 인앱웹뷰 생성 시 컨트롤러 정의
      onWebViewCreated: (InAppWebViewController controller) async {
        webViewController = controller;
        setUserAgent(webViewController!);

        fabManager = FloatingActionButtonManager(
          webViewController: webViewController!,
          updateLoadingStatus: (bool isLoading) {
            setState(() {
              _isLoading = isLoading;
            });
          },
        );
        startTimer(webViewController);
      },

      onCreateWindow: (controller, createWindowRequest) async {
        // 새 창 요청을 현재 웹뷰 컨트롤러를 사용하여 로드합니다.
        controller.loadUrl(urlRequest: createWindowRequest.request);
        return false;  // 새 창을 만들지 않고, 현재 창에서 처리했음을 나타냅니다.
      },
      // 페이지 로딩 시 수행 메서드 정의
      onLoadStart: (InAppWebViewController controller, url) async {
        setState(() {
          myUrl = url!;
          _isPageLoading = true;
        });
      },

      // URL 로딩 제어
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        Uri url = navigationAction.request.url!;

        // 외부 앱 실행 필요한 URL 스키마 처리
        if (!["http", "https", "file", "chrome", "data", "javascript", "about"].contains(url.scheme)) {
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
            return NavigationActionPolicy.CANCEL;  // 외부 앱 실행 후 원래 요청 취소
          }
        }

        // 모든 웹 페이지 로드 요청에 "X-Requested-With" 헤더 추가
        if (url.scheme == "http" || url.scheme == "https") {
          await controller.loadUrl(urlRequest: URLRequest(
              url: WebUri(url.toString()),
              headers: {"SimilarChart-App": "SimilarChartFinder/1.0/dev"}
          ));
          return NavigationActionPolicy.CANCEL; // 기존 요청 취소하고 새 요청 실행
        }

        return NavigationActionPolicy.ALLOW; // 요청 허용
      },
      // 페이지 로딩이 정지 시 메서드 정의
      onLoadStop: (InAppWebViewController controller, url) async {
        pullToRefreshController.endRefreshing();
        setState(() {
          _isFirstLoad = false;
          _isLoading = false;
          _isPageLoading = false;
          myUrl = url!;
        });
        updateFloatingActionButtonVisibility(url.toString());
        webViewManager.addCurrentUrlToHistory(url.toString(), webViewController);
        webViewManager.addCurrentUrlToRecent(url.toString(), webViewController);
        await webViewManager.saveCookies(webViewController);
      },
      // 페이지 로딩 중 오류 발생 시 메서드 정의
      onReceivedError: (InAppWebViewController controller, request, error) {
        // 당겨서 새로고침 중단
        pullToRefreshController.endRefreshing();
      },
      // 로딩 상태 변경 시 메서드 정의
      onProgressChanged: (InAppWebViewController controller, progress) async {
        // 로딩이 완료되면 당겨서 새로고침 중단
        if (progress >= 100) {
          pullToRefreshController.endRefreshing();
          setState(() {
            _isFirstLoad = false;
            _isLoading = false;
            _isPageLoading = false;
          });
        }
        // 현재 페이지 로딩 상태 업데이트 (0~100%)
      },
    );
  }

  Future<void> setUserAgent(InAppWebViewController controller) async {
    String userAgent = await controller.evaluateJavascript(source: "navigator.userAgent;");
    UserAgentPreference.setUserAgent(userAgent);
  }

  void updateFloatingActionButtonVisibility(String url) {
    bool isNaverHome = (url == Urls.naverHomeUrl);
    bool startsWithDomestic = url.startsWith(Urls.naverDomesticUrl);
    bool startsWithWorld = url.startsWith(Urls.naverWorldUrl);
    setState(() {
      _showFloatingActionButton = startsWithDomestic || startsWithWorld || isNaverHome;
    });
  }

  Widget _buildBottomNavigationBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        BottomNavigationBuilder.buildBottomIcon(
            Icons.brush,
            '드로잉검색',
            () => bottomNavigationTap.onDrawingSearchTap(
                context, webViewController!)),
        BottomNavigationBuilder.buildBottomIcon(
            Icons.trending_up,
            subPageLabel,
            () =>
                bottomNavigationTap.onSubPageTap(context, webViewController!)),
        BottomNavigationBuilder.buildBottomIcon(Icons.home, homePageLabel,
            () => bottomNavigationTap.onHomeTap(context, webViewController!)),
        BottomNavigationBuilder.buildBottomIcon(
            Icons.history,
            '최근본종목',
            () =>
                bottomNavigationTap.onFavoriteTap(context, webViewController!)),
        BottomNavigationBuilder.buildBottomIcon(
            Icons.settings,
            '설정',
            () =>
                bottomNavigationTap.onSettingsTap(context, webViewController!)),
      ],
    );
  }
}
