import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_view/services/toast_service.dart';
import 'package:web_view/screen/home_screen_module/web_view_manager.dart';
import 'package:web_view/constants/urls.dart';
import 'package:web_view/services/preferences.dart';
import 'package:web_view/providers/home_screen_state_providers.dart';
import 'package:web_view/system/logger.dart';
import 'package:web_view/services/check_internet.dart';

class FloatingActionButtonManager {
  InAppWebViewController webViewController;

  FloatingActionButtonManager({
    required this.webViewController,
  });

  Widget buildFloatingActionButton(
      bool showFloatingActionButton, WidgetRef ref) {
    return Positioned(
      right: 16,
      bottom: 60 + 18, // 예시로 BottomNavigationBar의 높이와 FAB 반지름을 사용
      child: showFloatingActionButton
          ? FloatingActionButton(
              onPressed: () async {
                await onFloatingActionButtonPressed(ref);
              },
              child: Image.asset('assets/logo_2.png'), // 로컬 에셋 이미지 사용
              backgroundColor: Colors.transparent, // 배경색 투명하게 설정
              elevation: 0, // 그림자 제거
            )
          : Container(),
    );
  }

  Future<void> onFloatingActionButtonPressed(WidgetRef ref) async {
    if (!await checkInternetConnection()) return;

    WebUri? uri = await webViewController.getUrl();
    String currentUrl = uri.toString();
    Log.instance.i("currentUrl = $currentUrl");
    if (currentUrl.startsWith(Urls.naverDomesticUrl) ||
        currentUrl.startsWith(Urls.naverWorldUrl)) {
      await _goStockInfoPage(ref);
    } else {
      ToastService().showToastMessage("특정 종목 정보 페이지에서 터치해 보세요!");
    }
  }

  Future<void> _goStockInfoPage(WidgetRef ref) async {
    ref.read(isLoadingProvider.notifier).state = true;

    // 현재 웹뷰의 URL을 가져옵니다.
    WebUri? uri = await webViewController.getUrl();
    String currentUrl = uri.toString();

    // CodeValue를 추출하기 위한 정규 표현식입니다.
    RegExp regExp = RegExp(r'/stock/([^/]+)/');
    final matches = regExp.firstMatch(currentUrl);

    if (matches != null && matches.groupCount >= 1) {
      String codeValue = matches.group(1)!; // 'stock'과 'total' 사이의 값입니다.
      codeValue = codeValue.split('.')[0];

      // 사용자의 언어 설정을 가져옵니다.
      String currentLang = await LanguagePreference.getLanguageSetting();

      // 최종 URL을 구성합니다.
      String finalUrl =
          'https://www.similarchart.com/stock_info/?code=$codeValue&lang=$currentLang';

      // 구성한 URL로 웹뷰를 이동시킵니다.
      WebViewManager.loadUrl(webViewController, finalUrl);
    }
  }
}
