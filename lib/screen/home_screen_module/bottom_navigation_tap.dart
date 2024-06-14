import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:math';
import 'package:web_view/screen/home_screen_module/web_view_manager.dart';
import 'package:web_view/services/preferences.dart';
import 'package:web_view/constants/urls.dart';
import 'package:web_view/screen/favorite_screen.dart';
import 'package:web_view/screen/settings_screen.dart';
import 'package:web_view/screen/drawing_search/drawing_board.dart';
import 'package:web_view/screen/pattern_search/pattern_board.dart';
import 'package:web_view/screen/drawing_search/drawing_result.dart';
import 'package:web_view/screen/pattern_search/pattern_result.dart';
import 'package:web_view/providers/home_screen_state_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_view/services/check_internet.dart';

class BottomNavigationTap {
  Future<void> onFavoriteTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) async {
    String? url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoriteScreen()),
    );
    if (url != null) {
      if (!await checkInternetConnection()) return;

      ref.read(isLoadingProvider.notifier).state = true;
      WebViewManager.loadUrl(webViewController, url);
    }
  }

  Future<void> onHomeTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) async {
    if (!await checkInternetConnection()) return;

    ref.read(isLoadingProvider.notifier).state = true;
    String page = await MainPagePreference.getMainPageSetting();
    if (page == 'chart') {
      String lang = await LanguagePreference.getLanguageSetting();
      WebViewManager.loadUrl(
          webViewController, 'https://www.similarchart.com?lang=$lang&app=1');
    } else if (page == 'naver') {
      WebViewManager.loadUrl(webViewController, Urls.naverHomeUrl);
    } else if (page == 'yahoo') {
      WebViewManager.loadUrl(webViewController, Urls.yahooHomeUrl);
    }
  }

  Future<void> onSettingsTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) async {
    String originalLang = await LanguagePreference.getLanguageSetting();

    final url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );

    if (!await checkInternetConnection()) return;

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

    Uri newUri = currentUri;
    if(currentUri.toString().contains("similarchart.com")) {
      Map<String, String> newQueryParameters =
      Map.from(currentUri.queryParameters);
      newQueryParameters['lang'] = currentLang;

      newUri = currentUri.replace(queryParameters: newQueryParameters);
    }

    ref.read(isLoadingProvider.notifier).state = true;
    WebViewManager.loadUrl(webViewController, newUri.toString());
  }

  void onDrawingSearchTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) {
    if (DrawingResultManager.isResultExist()) {
      DrawingResultManager.showDrawingResult(context).then((url) async {
        if (url != null) {
          if (!await checkInternetConnection()) return;

          ref.read(isLoadingProvider.notifier).state = true;
          WebViewManager.loadUrl(webViewController, url);
        }
      });
    }
    else {
      double width = min(
          MediaQuery
              .of(context)
              .size
              .height, MediaQuery
          .of(context)
          .size
          .width);
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
      ).then((url) async {
        if (url != null) {
          if (!await checkInternetConnection()) return;

          ref.read(isLoadingProvider.notifier).state = true;
          WebViewManager.loadUrl(webViewController, url);
        }
      });
    }
  }

  void onPatternSearchTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) {
    if (PatternResultManager.isResultExist()) {
      PatternResultManager.showPatternResult(context).then((url) async {
        if (url != null) {
          if (!await checkInternetConnection()) return;

          ref.read(isLoadingProvider.notifier).state = true;
          WebViewManager.loadUrl(webViewController, url);
        }
      });
    } else {
      double width = min(MediaQuery.of(context).size.height,
          MediaQuery.of(context).size.width);
      double height = MediaQuery.of(context).size.height * 0.75;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(0),
            child: SizedBox(
              width: width,
              height: height,
              child: const PatternBoard(),
            ),
          );
        },
      ).then((url) async {
        if (url != null) {
          if (!await checkInternetConnection()) return;

          ref.read(isLoadingProvider.notifier).state = true;
          WebViewManager.loadUrl(webViewController, url);
        }
      });
    }
  }


  Future<void> onSubPageTap(BuildContext context, WidgetRef ref,
      InAppWebViewController webViewController) async {
    ref.read(isLoadingProvider.notifier).state = true;
    String page = await MainPagePreference.getMainPageSetting();
    if (page == 'chart') {
      WebViewManager.loadUrl(webViewController, Urls.naverHomeUrl);
    } else if (page == 'naver' || page == 'yahoo') {
      String lang = await LanguagePreference.getLanguageSetting();
      WebViewManager.loadUrl(
          webViewController, 'https://www.similarchart.com?lang=$lang&app=1');
    }
  }
}
