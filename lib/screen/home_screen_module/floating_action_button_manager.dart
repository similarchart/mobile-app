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

import '../../l10n/app_localizations.dart';

class FloatingActionButtonManager {
  InAppWebViewController webViewController;

  FloatingActionButtonManager({
    required this.webViewController,
  });

  Widget buildFloatingActionButton(BuildContext context,
      bool showFloatingActionButton, WidgetRef ref) {
    return Positioned(
      right: 16,
      bottom: 85, // 예시로 BottomNavigationBar의 높이와 FAB 반지름을 사용
      child: showFloatingActionButton
          ? FloatingActionButton(
              onPressed: () async {
                await onFloatingActionButtonPressed(context, ref);
              }, // 로컬 에셋 이미지 사용
              backgroundColor: Colors.transparent, // 배경색 투명하게 설정
              elevation: 0,
              child: Image.asset(AppLocalizations.of(context).translate('floating_img')), // 그림자 제거
            )
          : Container(),
    );
  }

  Future<void> onFloatingActionButtonPressed(BuildContext context, WidgetRef ref) async {
    if (!await checkInternetConnection()) return;

    WebUri? uri = await webViewController.getUrl();
    String currentUrl = uri.toString();
    Log.instance.i("currentUrl = $currentUrl");
    if (currentUrl.startsWith(Urls.naverDomesticUrl) ||
        currentUrl.startsWith(Urls.naverWorldUrl) ||
        currentUrl.startsWith(Urls.yahooItemUrl)){
      await _goStockInfoPage(ref);
    } else {
      ToastService().showToastMessage(AppLocalizations.of(context).translate("touch_specific_stock_info_page"));
    }
  }

  Future<void> _goStockInfoPage(WidgetRef ref) async {
    ref.read(isLoadingProvider.notifier).state = true;

    // 현재 웹뷰의 URL을 가져옵니다.
    WebUri? uri = await webViewController.getUrl();
    String currentUrl = uri.toString();
    String? codeValue;

    if (currentUrl.startsWith(Urls.naverHomeUrl)) {
      // CodeValue를 추출하기 위한 정규 표현식입니다.
      RegExp regExp = RegExp(r'/stock/([^/]+)/');
      final matches = regExp.firstMatch(currentUrl);

      if (matches != null && matches.groupCount >= 1) {
        codeValue = matches.group(1)!; // 'stock'과 'total' 사이의 값입니다.
        codeValue = codeValue.split('.')[0];
      }
    }
    else if (currentUrl.startsWith(Urls.yahooItemUrl)) {
      // CodeValue를 추출하기 위한 정규 표현식입니다.
      RegExp regExp = RegExp(r'/quote/([^/]+)/');
      final matches = regExp.firstMatch(currentUrl);

      if (matches != null && matches.groupCount >= 1) {
        codeValue = matches.group(1)!; // 'stock'과 'total' 사이의 값입니다.
        codeValue = codeValue.split('.')[0];
      }
    }
    else{
      return;
    }

    // 사용자의 언어 설정을 가져옵니다.
    String currentLang = await LanguagePreference.getLanguageSetting();

    // 최종 URL을 구성합니다.
    String finalUrl =
        'https://www.similarchart.com/stock_info/?code=$codeValue&lang=$currentLang';

    // 구성한 URL로 웹뷰를 이동시킵니다.
    WebViewManager.loadUrl(webViewController, finalUrl);
  }
}
