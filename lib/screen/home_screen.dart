import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/screen/splash_screen.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/screen/home_screen_module/bottom_navigation_builder.dart';
import 'package:web_view/screen/home_screen_module/floating_action_button_manager.dart';
import 'package:web_view/screen/home_screen_module/web_view_manager.dart';
import 'package:web_view/screen/home_screen_module/bottom_navigation_tap.dart';

final homeUrl = Uri.parse('https://www.similarchart.com?lang=ko');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebViewController controller = WebViewController();
  late WebViewManager webViewManager;
  late FloatingActionButtonManager fabManager;
  late BottomNavigationTap bottomNavigationTap;
  bool _isFirstLoad = true; // 앱이 처음 시작될 때만 true(splash screen을 위해)
  bool _showFloatingActionButton = false; // FAB 표시 여부
  bool _isLoading = false; // 로딩바 표시 여부
  bool _isBottomBarVisible = true; // 하단 바의 초기 상태
  double startY = 0.0; // 드래그 시작 지점의 Y 좌표
  bool isDragging = false; // 드래그 중인지 여부

  @override
  void initState() {
    super.initState();
    webViewManager = WebViewManager(
        controller,
        (bool isVisible) =>
            setState(() => _showFloatingActionButton = isVisible),
        (bool isLoading) => setState(() => _isLoading = isLoading),
        (bool isFirstLoad) => setState(() => _isFirstLoad = isFirstLoad));
    fabManager = FloatingActionButtonManager(
      controller: controller,
      updateLoadingStatus: (bool isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
    );
    bottomNavigationTap = BottomNavigationTap((isLoading) {
      setState(() {
        _isLoading = isLoading;
      });
    });
    webViewManager.loadInitialUrl();
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
              body: Stack(
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
                              _isBottomBarVisible = false;
                            });
                            isDragging = false; // 드래그 중지
                          } else if (distance < -70) {
                            // 50픽셀 이상 아래로 드래그
                            setState(() {
                              _isBottomBarVisible = true;
                            });
                            isDragging = false; // 드래그 중지
                          }
                        }
                      },
                      onPointerUp: (PointerUpEvent event) {
                        isDragging = false; // 드래그 종료
                      },
                      child: WebViewWidget(
                        controller: controller,
                      ),
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
                          0.0, _isBottomBarVisible ? 0.0 : 60, 0.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          BottomNavigationBuilder.buildBottomIcon(
                              Icons.brush,
                              '드로잉검색',
                              () => bottomNavigationTap.onDrawingSearchTap(context, controller)),
                          BottomNavigationBuilder.buildBottomIcon(
                              Icons.trending_up,
                              '네이버증권',
                              () => bottomNavigationTap.onNaverHomeTap(context, controller)),
                          BottomNavigationBuilder.buildBottomIcon(Icons.home,
                              '홈', () => bottomNavigationTap.onHomeTap(context, controller)),
                          BottomNavigationBuilder.buildBottomIcon(
                              Icons.history,
                              '최근본종목',
                              () => bottomNavigationTap.onFavoriteTap(context, controller)),
                          BottomNavigationBuilder.buildBottomIcon(
                              Icons.settings,
                              '설정',
                              () => bottomNavigationTap.onSettingsTap(context, controller)),
                        ],
                      ),
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
}
