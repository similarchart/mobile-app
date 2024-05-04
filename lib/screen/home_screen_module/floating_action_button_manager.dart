import 'package:flutter/material.dart';
import 'package:web_view/services/toast_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/constants/urls.dart';
import 'package:web_view/services/preferences.dart';

class FloatingActionButtonManager {
  WebViewController controller;
  Function(bool) updateLoadingStatus;

  FloatingActionButtonManager({
    required this.controller,
    required this.updateLoadingStatus,
  });

  Widget buildFloatingActionButton(bool showFloatingActionButton) {
    return Positioned(
      right: 16,
      bottom: 60 + 18,  // 예시로 BottomNavigationBar의 높이와 FAB 반지름을 사용
      child: showFloatingActionButton ? FloatingActionButton(
        onPressed: () async {
          await onFloatingActionButtonPressed();
        },
        child: Image.asset('assets/logo_2.png'),  // 로컬 에셋 이미지 사용
        backgroundColor: Colors.transparent,      // 배경색 투명하게 설정
        elevation: 0,                             // 그림자 제거
      ) : Container(),
    );
  }

  Future<void> onFloatingActionButtonPressed() async {
    String currentUrl = await controller.currentUrl() ?? '';
    if (currentUrl.startsWith(Urls.naverDomesticUrl) || currentUrl.startsWith(Urls.naverWorldUrl)) {
      await _goStockInfoPage();
    } else {
      ToastService().showToastMessage("특정 종목 정보 페이지에서 터치해 보세요!");
    }
  }

  Future<void> _goStockInfoPage() async {
    updateLoadingStatus(true); // 콜백을 통해 로딩 상태 업데이트

    // 현재 웹뷰의 URL을 가져옵니다.
    String currentUrl = await controller.currentUrl() ?? '';

    // CodeValue를 추출하기 위한 정규 표현식입니다.
    RegExp regExp = RegExp(r'stock/([A-Z0-9.]+)/total');
    final matches = regExp.firstMatch(currentUrl);

    if (matches != null && matches.groupCount >= 1) {
      String codeValue = matches.group(1)!; // 'stock'과 'total' 사이의 값입니다.

      if (codeValue.contains('.')) {
        codeValue = codeValue.split('.')[0]; // '.'을 기준으로 분할하여 첫 번째 값을 사용합니다.
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
}
