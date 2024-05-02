import 'package:flutter/material.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/constants/urls.dart';
import 'package:web_view/screen/favorite_screen.dart';
import 'package:web_view/screen/settings_screen.dart';
import 'package:web_view/screen/drawing_board.dart';

class BottomNavigationTap {
  final Function(bool) updateLoadingStatus;
  BottomNavigationTap(this.updateLoadingStatus);

  onFavoriteTap(BuildContext context, WebViewController controller) async {
    String? url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoriteScreen()),
    );
    if (url != null) {
      updateLoadingStatus(true);
      controller.loadRequest(Uri.parse(url));
    }
  }

  void onHomeTap(BuildContext context, WebViewController controller) async {
    // 현재 웹뷰의 URL을 가져옵니다.
    String? currentUrl = await controller.currentUrl();
    Uri uri = Uri.parse(currentUrl ?? "");

    String prefer_lang = await LanguagePreference.getLanguageSetting();
    // 현재 URL에서 언어 쿼리 매개변수(lang)를 확인합니다.
    String lang = uri.queryParameters['lang'] ?? prefer_lang; // 기본값은 'ko'

    // 새로운 홈 URL을 만들되, 현재 언어 설정을 유지합니다.
    Uri newHomeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');

    // 새로운 홈 URL로 페이지를 로드합니다.
    updateLoadingStatus(true);
    controller.loadRequest(newHomeUrl);
  }

  // '설정' 버튼 탭 처리를 위한 별도의 함수
  onSettingsTap(BuildContext context, WebViewController controller) async {
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
    updateLoadingStatus(true);
    controller.loadRequest(newUri);
  }

  void onDrawingSearchTap(BuildContext context, WebViewController controller) {
    double width = MediaQuery.of(context).size.width;
    double appBarHeight = AppBar().preferredSize.height; // AppBar의 기본 높이를 가져옴
    double height =
        MediaQuery.of(context).size.width + appBarHeight; // 여기에 AppBar 높이를 추가

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(0),
          child: SizedBox(
            width: width,
            height: height,
            child: DrawingBoard(
              screenHeight: height - appBarHeight,
            ),
          ),
        );
      },
    );
  }

  onNaverHomeTap(BuildContext context, WebViewController controller) {
    updateLoadingStatus(true);
    controller.loadRequest(Uri.parse(Urls.naverHomeUrl));
  }
}