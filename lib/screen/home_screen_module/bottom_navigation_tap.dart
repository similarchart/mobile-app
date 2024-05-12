import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:math';
import 'package:web_view/screen/home_screen_module/web_view_manager.dart';
import 'package:web_view/services/preferences.dart';
import 'package:web_view/constants/urls.dart';
import 'package:web_view/screen/favorite_screen.dart';
import 'package:web_view/screen/settings_screen.dart';
import 'package:web_view/screen/drawing_board.dart';
import 'package:web_view/screen/drawing_result.dart';

class BottomNavigationTap {
  final Function(bool) updateLoadingStatus;
  BottomNavigationTap(this.updateLoadingStatus);

  onFavoriteTap(BuildContext context, InAppWebViewController webViewController) async {
    String? url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoriteScreen()),
    );
    if (url != null) {
      updateLoadingStatus(true);
      WebViewManager.loadUrl(webViewController, url);
    }
  }

  void onHomeTap(
      BuildContext context, InAppWebViewController webViewController) async {
    updateLoadingStatus(true);
    String page = await MainPagePreference.getMainPageSetting();
    if (page == 'chart') {
      String lang = await LanguagePreference.getLanguageSetting();
      WebViewManager.loadUrl(webViewController, 'https://www.similarchart.com?lang=$lang');
    } else if (page == 'naver') {
      WebViewManager.loadUrl(webViewController, Urls.naverHomeUrl);
    }
  }

  // '설정' 버튼 탭 처리를 위한 별도의 함수
  onSettingsTap(BuildContext context, InAppWebViewController webViewController) async {
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
      WebUri? uri = await webViewController.getUrl();
      String currentUrl = uri.toString();
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
    WebViewManager.loadUrl(webViewController, newUri.toString());
  }

  void onDrawingSearchTap(
      BuildContext context, InAppWebViewController webViewController) {
    double width = min(
        MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
    double appBarHeight = AppBar().preferredSize.height; // AppBar의 기본 높이를 가져옴
    double adHeight = 60; // 하단 광고 배너 높이
    double height = width + appBarHeight + adHeight; // 여기에 AppBar 높이를 추가

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
    ).then((url) {
      if (url != null) {
        updateLoadingStatus(true);
        WebViewManager.loadUrl(webViewController, url);
      }
    });

    if (DrawingResultManager.isResultExist()) {
      // 드로잉 화면 위에 결과 화면 띄우기
      DrawingResultManager.showDrawingResult(context);
    }
  }

  onSubPageTap(BuildContext context, InAppWebViewController webViewController) async {
    updateLoadingStatus(true);
    String page = await MainPagePreference.getMainPageSetting();
    if (page == 'chart') {
      WebViewManager.loadUrl(webViewController, Urls.naverHomeUrl);
    } else if (page == 'naver') {
      String lang = await LanguagePreference.getLanguageSetting();
      WebViewManager.loadUrl(webViewController, 'https://www.similarchart.com?lang=$lang');
    }
  }
}
