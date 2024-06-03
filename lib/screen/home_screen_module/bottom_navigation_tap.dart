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
import 'package:web_view/providers/home_screen_state_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomNavigationTap {
  Future<void> onFavoriteTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) async {
    String? url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoriteScreen()),
    );
    if (url != null) {
      ref.read(isLoadingProvider.notifier).state = true;
      WebViewManager.loadUrl(webViewController, url);
    }
  }

  Future<void> onHomeTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) async {
    ref.read(isLoadingProvider.notifier).state = true;
    String page = await MainPagePreference.getMainPageSetting();
    if (page == 'chart') {
      String lang = await LanguagePreference.getLanguageSetting();
      WebViewManager.loadUrl(
          webViewController, 'https://www.similarchart.com?lang=$lang');
    } else if (page == 'naver') {
      WebViewManager.loadUrl(webViewController, Urls.naverHomeUrl);
    }
  }

  Future<void> onSettingsTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) async {
    String originalLang = await LanguagePreference.getLanguageSetting();

    final url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );

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
      currentUri = Uri.parse(url);
    }

    Map<String, String> newQueryParameters =
        Map.from(currentUri.queryParameters);
    newQueryParameters['lang'] = currentLang;

    Uri newUri = currentUri.replace(queryParameters: newQueryParameters);

    ref.read(isLoadingProvider.notifier).state = true;
    WebViewManager.loadUrl(webViewController, newUri.toString());
  }

  void onDrawingSearchTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) {
    double width = min(
        MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
    double appBarHeight = AppBar().preferredSize.height;
    double adHeight = 60;
    double height = width + appBarHeight + adHeight;

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
        ref.read(isLoadingProvider.notifier).state = true;
        WebViewManager.loadUrl(webViewController, url);
      }
    });

    if (DrawingResultManager.isResultExist()) {
      DrawingResultManager.showDrawingResult(context);
    }
  }

  Future<void> onSubPageTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) async {
    ref.read(isLoadingProvider.notifier).state = true;
    String page = await MainPagePreference.getMainPageSetting();
    if (page == 'chart') {
      WebViewManager.loadUrl(webViewController, Urls.naverHomeUrl);
    } else if (page == 'naver') {
      String lang = await LanguagePreference.getLanguageSetting();
      WebViewManager.loadUrl(
          webViewController, 'https://www.similarchart.com?lang=$lang&app=1');
    }
  }
}
