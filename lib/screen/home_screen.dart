import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/constants/urls.dart';
import 'package:web_view/screen/home_screen_module/bottom_navigation_builder.dart';
import 'package:web_view/screen/home_screen_module/bottom_navigation_tap.dart';
import 'package:web_view/screen/home_screen_module/floating_action_button_manager.dart';
import 'package:web_view/screen/home_screen_module/web_view_manager.dart';
import 'package:web_view/screen/splash_screen.dart';
import 'package:web_view/services/preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';
import 'package:web_view/providers/home_screen_state_providers.dart';
import 'package:web_view/main.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web_view/services/check_internet.dart';
import 'package:web_view/system/logger.dart';
import '../l10n/app_localizations.dart';
import 'loading_overlay.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  static const double bottomNavigationBarHeight = 55;
  final GlobalKey webViewKey = GlobalKey();
  late String homeUrl;
  String? previousUrl;
  late final InAppWebViewController? webViewController;
  late WebViewManager webViewManager;
  late BottomNavigationTap bottomNavigationTap;
  late FloatingActionButtonManager fabManager;
  late PullToRefreshController pullToRefreshController; // 당겨서 새로고침 컨트롤러
  late Future<void> _initializationFuture; // 초기화 작업 Future
  int? loadingProgress;

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
    await _loadPreferences();
    ref.read(isOnHomeScreenProvider.notifier).state = true;
  }

  @override // 다른 화면으로 넘어갈 때 실행되는 로직
  void didPushNext() {
    ref.read(isOnHomeScreenProvider.notifier).state = false;
  }

  Future<void> _loadPreferences() async {
    bool bottomBarFixedPref = await BottomBarPreference
        .getIsBottomBarFixed(); // SharedPreferences에서 설정값 불러오기
    ref.read(bottomBarFixedPrefProvider.notifier).state = bottomBarFixedPref;

    String preferPage = await MainPagePreference.getMainPageSetting();
    if (preferPage == 'chart') {
      String lang = await LanguagePreference.getLanguageSetting();
      if (lang == 'ko') {
        ref.read(subPageLabelProvider.notifier).state = "naver";
      } else {
        ref.read(subPageLabelProvider.notifier).state = "yahoo";
      }
      ref.read(homePageLabelProvider.notifier).state = "chart";
    } else if (preferPage == 'naver') {
      ref.read(subPageLabelProvider.notifier).state = "chart";
      ref.read(homePageLabelProvider.notifier).state = "naver";
    } else if (preferPage == 'yahoo') {
      ref.read(subPageLabelProvider.notifier).state = "chart";
      ref.read(homePageLabelProvider.notifier).state = "yahoo";
    }

    String lang = await LanguagePreference.getLanguageSetting();
    String page = await MainPagePreference.getMainPageSetting();
    if (page == 'chart') {
      homeUrl = 'https://www.similarchart.com?lang=$lang&app=1';
    } else if (page == 'naver') {
      homeUrl = Urls.naverHomeUrl;
    } else if (page == 'yahoo') {
      homeUrl = Urls.yahooHomeUrl;
    }
  }

  void startTimer(webViewController) {
    if (webViewController == null) {
      return;
    }

    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      WebUri? uri = await webViewController?.getUrl();
      String currentUrl = uri.toString();
      bool isFirstLoad = ref.read(isFirstLoadProvider);
      bool isOnHomeScreen = ref.read(isOnHomeScreenProvider);
      bool isLoading = ref.read(isLoadingProvider);
      bool isPageLoading = ref.read(isPageLoadingProvider);

      if (!isFirstLoad && isOnHomeScreen && !isLoading && !isPageLoading) {
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
    _initializationFuture = _loadPreferences(); // 초기화 작업 Future 설정
    webViewManager = WebViewManager();
    bottomNavigationTap = BottomNavigationTap();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      // 플랫폼별 새로고침
      onRefresh: () async {
        if (webViewController != null) {
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
    final bool isLoading = ref.watch(isLoadingProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isLoading) {
        LoadingOverlay().show(context);
      } else {
        LoadingOverlay().hide();
      }
    });

    final bool isFirstLoad = ref.watch(isFirstLoadProvider);
    final bool showFloatingActionButton =
        ref.watch(showFloatingActionButtonProvider);
    final bool didScrollDown = ref.watch(didScrollDownProvider);
    final bool bottomBarFixedPref = ref.watch(bottomBarFixedPrefProvider);
    final double startY = ref.watch(startYProvider);
    final bool isDragging = ref.watch(isDraggingProvider);

    // FloatingActionButton의 반지름입니다. 실제 크기에 따라 조정할 수 있습니다.
    const double fabRadius = 18;

    return FutureBuilder<void>(
      future: _initializationFuture, // 초기화 작업 Future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (webViewController != null &&
                  await webViewController!.canGoBack()) {
                webViewController?.goBack();
                return;
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                        AppLocalizations.of(context).translate("exit_app"),
                        style: const TextStyle(color: AppColors.textColor)),
                    content: Text(
                        AppLocalizations.of(context)
                            .translate("confirm_exit_app"),
                        style: const TextStyle(color: AppColors.textColor)),
                    backgroundColor: AppColors.primaryColor,
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('No',
                            style: TextStyle(color: AppColors.textColor)),
                      ),
                      TextButton(
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                        child: const Text('Yes',
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
                              SizedBox(
                                  height: bottomNavigationBarHeight,
                                  child: _buildBottomNavigationBar())
                            ],
                          )
                        : Stack(
                            children: [
                              // 웹뷰를 Stack의 바닥에 위치시키기
                              Positioned.fill(
                                child: Listener(
                                  onPointerDown: (PointerDownEvent event) {
                                    ref.read(startYProvider.notifier).state =
                                        event.position.dy; // 시작 지점 저장
                                    ref
                                        .read(isDraggingProvider.notifier)
                                        .state = true; // 드래그 시작
                                  },
                                  onPointerMove: (PointerMoveEvent event) {
                                    if (isDragging) {
                                      double distance = startY -
                                          event.position.dy; // 이동 거리 계산
                                      if (distance > 70) {
                                        // 50픽셀 이상 위로 드래그
                                        ref
                                            .read(
                                                didScrollDownProvider.notifier)
                                            .state = false;
                                        ref
                                            .read(isDraggingProvider.notifier)
                                            .state = false; // 드래그 중지
                                      } else if (distance < -70) {
                                        // 50픽셀 이상 아래로 드래그
                                        ref
                                            .read(
                                                didScrollDownProvider.notifier)
                                            .state = true;
                                        ref
                                            .read(isDraggingProvider.notifier)
                                            .state = false; // 드래그 중지
                                      }
                                    }
                                  },
                                  onPointerUp: (PointerUpEvent event) {
                                    ref
                                        .read(isDraggingProvider.notifier)
                                        .state = false; // 드래그 종료
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
                                  height: bottomNavigationBarHeight,
                                  transform: Matrix4.translationValues(
                                      0.0,
                                      didScrollDown
                                          ? 0.0
                                          : bottomNavigationBarHeight,
                                      0.0),
                                  child: _buildBottomNavigationBar(),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                isFirstLoad
                    ? const SplashScreen()
                    : Container(), // 첫 로드면 스플래시 화면 띄우기
                Positioned(
                  right: 16,
                  bottom: 85, // FAB를 BottomNavigationBar 바로 위에 위치시킵니다.
                  child: showFloatingActionButton
                      ? fabManager.buildFloatingActionButton(context, true, ref)
                      : Container(),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget createWebView() {
    return InAppWebView(
      key: webViewKey,
      // 시작 페이지
      initialUrlRequest: URLRequest(
          url: WebUri(homeUrl), headers: {"SimilarChart-App": Urls.appHeader}),
      initialSettings: InAppWebViewSettings(
        useShouldOverrideUrlLoading: true, // URL 로딩 제어
        mediaPlaybackRequiresUserGesture: false, // 미디어 자동 재생
        javaScriptEnabled: true, // 자바스크립트 실행 여부
        javaScriptCanOpenWindowsAutomatically: true, // 팝업 여부
        useHybridComposition: true, // 하이브리드 사용을 위한 안드로이드 웹뷰 최적화
        supportMultipleWindows: true, // 멀티 윈도우 허용
        allowsInlineMediaPlayback: true, // 웹뷰 내 미디어 재생 허용
      ),
      // 당겨서 새로고침 컨트롤러 정의
      pullToRefreshController: pullToRefreshController,
      // 인앱웹뷰 생성 시 컨트롤러 정의
      onWebViewCreated: (InAppWebViewController controller) async {
        webViewController = controller;
        fabManager =
            FloatingActionButtonManager(webViewController: webViewController!);
        startTimer(webViewController);
      },
      onCreateWindow: (controller, createWindowRequest) async {
        ref.read(isPageLoadingProvider.notifier).state = true;
        ref.read(isLoadingProvider.notifier).state = true;
        // 새 창 요청을 현재 웹뷰 컨트롤러를 사용하여 로드합니다.
        controller.loadUrl(urlRequest: createWindowRequest.request);
        return false; // 새 창을 만들지 않고, 현재 창에서 처리했음을 나타냅니다.
      },
      // 페이지 로딩 시 수행 메서드 정의
      onLoadStart: (InAppWebViewController controller, url) async {
        if (!await checkInternetConnection()) {
          controller.stopLoading();
          return;
        }

        ref.read(isPageLoadingProvider.notifier).state = true;
        previousUrl = url.toString();
      },

      // URL 로딩 제어
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        Uri url = navigationAction.request.url!;

        if (!await checkInternetConnection()) {
          return NavigationActionPolicy.CANCEL;
        }

        if (url.toString().startsWith('intent:kakaolink://send')) {
          if (previousUrl != null) {
            await shareUrl(previousUrl!);
          }
          return NavigationActionPolicy.CANCEL;
        }

        if (!["http", "https", "file", "chrome", "data", "javascript", "about"]
            .contains(url.scheme)) {
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
            return NavigationActionPolicy.CANCEL;
          }
        }

        await controller.loadUrl(
            urlRequest: URLRequest(
                url: WebUri(url.toString()),
                headers: {"SimilarChart-App": Urls.appHeader}));
        return NavigationActionPolicy.CANCEL;
      },
      // 페이지 로딩이 정지 시 메서드 정의
      onLoadStop: (InAppWebViewController controller, url) async {
        pullToRefreshController.endRefreshing();
        ref.read(isFirstLoadProvider.notifier).state = false;
        ref.read(isLoadingProvider.notifier).state = false;
        ref.read(isPageLoadingProvider.notifier).state = false;
        updateFloatingActionButtonVisibility(url.toString());
        webViewManager.addCurrentUrlToHistory(
            url.toString(), webViewController);
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
        loadingProgress = progress;
        // 로딩이 완료되면 당겨서 새로고침 중단
        if (progress >= 100) {
          pullToRefreshController.endRefreshing();
          ref.read(isFirstLoadProvider.notifier).state = false;
          ref.read(isLoadingProvider.notifier).state = false;
          ref.read(isPageLoadingProvider.notifier).state = false;
        }
        // 현재 페이지 로딩 상태 업데이트 (0~100%)
      },
    );
  }

  Future<void> shareUrl(String url) async {
    try {
      await Share.share(url);
    } catch (e) {
      Log.instance.e('URL 공유 중 오류 발생: $e');
    }
  }

  void updateFloatingActionButtonVisibility(String url) {
    if (loadingProgress != 100){
      return;
    }

    bool isNaverHome = (url == Urls.naverHomeUrl);
    bool startsWithDomestic = url.startsWith(Urls.naverDomesticUrl);
    bool startsWithWorld = url.startsWith(Urls.naverWorldUrl);
    bool isYahooHome = (url == Urls.yahooHomeUrl);
    bool startsWithYahooItem = url.startsWith(Urls.yahooItemUrl);
    ref.read(showFloatingActionButtonProvider.notifier).state =
        startsWithYahooItem ||
            isYahooHome ||
            startsWithDomestic ||
            startsWithWorld ||
            isNaverHome;
  }

  Widget _buildBottomNavigationBar() {
    String subPageLabel = ref.watch(subPageLabelProvider);
    subPageLabel = AppLocalizations.of(context).translate(subPageLabel);

    String homePageLabel = ref.watch(homePageLabelProvider);
    homePageLabel = AppLocalizations.of(context).translate(homePageLabel);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        BottomNavigationBuilder.buildBottomIcon(
            Icons.brush,
            AppLocalizations.of(context).translate("drawing"),
            () => bottomNavigationTap.onDrawingSearchTap(
                context, ref, webViewController!)),
        BottomNavigationBuilder.buildBottomIcon(
            Icons.candlestick_chart,
            AppLocalizations.of(context).translate("pattern"),
            () => bottomNavigationTap.onPatternSearchTap(
                context, ref, webViewController!)),
        BottomNavigationBuilder.buildBottomIcon(
            Icons.trending_up,
            subPageLabel,
            () => bottomNavigationTap.onSubPageTap(
                context, ref, webViewController!)),
        BottomNavigationBuilder.buildBottomIcon(
            Icons.home,
            homePageLabel,
            () => bottomNavigationTap.onHomeTap(
                context, ref, webViewController!)),
        BottomNavigationBuilder.buildBottomIcon(
            Icons.history,
            AppLocalizations.of(context).translate("recents"),
            () => bottomNavigationTap.onFavoriteTap(
                context, ref, webViewController!)),
        BottomNavigationBuilder.buildBottomIcon(
            Icons.settings,
            AppLocalizations.of(context).translate("settings"),
            () => bottomNavigationTap.onSettingsTap(
                context, ref, webViewController!)),
      ],
    );
  }
}
