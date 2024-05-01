import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_view/screen/favorite_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/screen/settings_screen.dart';
import 'package:web_view/screen/splash_screen.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/screen/home_screen_module/bottom_navigation_builder.dart';
import 'package:web_view/screen/home_screen_module/floating_action_button_manager.dart';
import 'package:web_view/screen/home_screen_module/web_view_manager.dart';
import 'package:web_view/constants/urls.dart';
import 'package:web_view/screen/drawing_board.dart';

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
  bool _isFirstLoad = true; // 앱이 처음 시작될 때만 true
  bool _showFloatingActionButton = false; // FAB 표시 여부
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    webViewManager = WebViewManager(
        controller,
            (bool isVisible) => setState(() => _showFloatingActionButton = isVisible),
            (bool isLoading) => setState(() => _isLoading = isLoading),
            (bool isFirstLoad) => setState(() => _isFirstLoad = isFirstLoad)
    );
    fabManager = FloatingActionButtonManager(
      controller: controller,
      updateLoadingStatus: (bool isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
    );
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
              title: const Text('앱 종료', style: TextStyle(color: AppColors.textColor)),
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
                  child:
                      const Text('예', style: TextStyle(color: AppColors.textColor)),
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
              body: Column(
                children: [
                  Expanded(
                    child: WebViewWidget(
                      controller: controller,
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        BottomNavigationBuilder.buildBottomIcon(
                            Icons.brush, '드로잉검색', () => onDrawingSearchTap()),
                        BottomNavigationBuilder.buildBottomIcon(Icons.trending_up, '네이버증권',
                            () => onNaverHomeTap()),
                        BottomNavigationBuilder.buildBottomIcon(
                            Icons.home, '홈', () => onHomeTap()),
                        BottomNavigationBuilder.buildBottomIcon(Icons.history, '최근본종목',
                            () => onFavoriteTap(context)),
                        BottomNavigationBuilder.buildBottomIcon(
                            Icons.settings, '설정', () => onSettingsTap(context)),
                      ],
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

  onFavoriteTap(BuildContext context) async {
    String? url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoriteScreen()),
    );
    if (url != null) {
      setState(() {
        _isLoading = true;
      });
      controller.loadRequest(Uri.parse(url));
    }
  }

  void onHomeTap() async {
    // 현재 웹뷰의 URL을 가져옵니다.
    String? currentUrl = await controller.currentUrl();
    Uri uri = Uri.parse(currentUrl ?? "");

    String prefer_lang = await LanguagePreference.getLanguageSetting();
    // 현재 URL에서 언어 쿼리 매개변수(lang)를 확인합니다.
    String lang = uri.queryParameters['lang'] ?? prefer_lang; // 기본값은 'ko'

    // 새로운 홈 URL을 만들되, 현재 언어 설정을 유지합니다.
    Uri newHomeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');

    // 새로운 홈 URL로 페이지를 로드합니다.
    setState(() {
      _isLoading = true;
    });
    controller.loadRequest(newHomeUrl);
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
    setState(() {
      _isLoading = true;
    });
    controller.loadRequest(newUri);
  }

  void onDrawingSearchTap() {
    double width = MediaQuery.of(context).size.width;
    double appBarHeight = AppBar().preferredSize.height; // AppBar의 기본 높이를 가져옴
    double height = MediaQuery.of(context).size.width + appBarHeight; // 여기에 AppBar 높이를 추가

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(0),
          child: SizedBox(
            width: width,
            height: height,
            child: DrawingBoard(),
          ),
        );
      },
    );
  }

  onNaverHomeTap() {
    setState(() {
      _isLoading = true;
    });

    controller.loadRequest(Uri.parse(Urls.naverHomeUrl));
  }
}
