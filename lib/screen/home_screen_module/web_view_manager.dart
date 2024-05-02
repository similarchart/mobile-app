import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/model/history_item.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/constants/urls.dart';

class WebViewManager {
  WebViewController controller;
  Function(bool) updateFABVisibility;
  Function(bool) updateLoadingStatus;
  Function(bool) updateFirstLoad;

  WebViewManager(this.controller, this.updateFABVisibility, this.updateLoadingStatus, this.updateFirstLoad);

  void updateFloatingActionButtonVisibility(String url) {
    bool isNaverHome = (url == Urls.naverHomeUrl);
    bool startsWithDomestic = url.startsWith(Urls.naverDomesticUrl);
    bool startsWithWorld = url.startsWith(Urls.naverWorldUrl);
    updateFABVisibility(startsWithDomestic || startsWithWorld || isNaverHome);
  }

  Future<void> loadInitialUrl() async {
    String lang = await LanguagePreference.getLanguageSetting();
    Uri homeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("SimilarChartFinder/1.0/dev")
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            updateFloatingActionButtonVisibility(request.url);
            updateLoadingStatus(true);
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            updateFloatingActionButtonVisibility(url);
            updateLoadingStatus(false);
            updateFirstLoad(false);
            addCurrentUrlToHistory(url);
            addCurrentUrlToRecent(url);
          },
        ),
      )
      ..loadRequest(homeUrl);
  }

  addCurrentUrlToRecent(String url) async {
    Uri uri = Uri.parse(url);
    bool startsWithDomestic =
    url.startsWith(Urls.naverDomesticUrl);
    bool startsWithWorld =
    url.startsWith(Urls.naverWorldUrl);

    String codeValue;
    String? title;
    if (uri.queryParameters.containsKey('code')) {
      codeValue = uri.queryParameters['code']!;
      title = await controller.getTitle();
    } else if (startsWithWorld || startsWithDomestic) {
      String? ogTitle = (await controller.runJavaScriptReturningResult(
          "document.querySelector('meta[property=\"og:title\"]').content;"))
      as String?;

      // JavaScript에서 반환된 JSON 문자열에서 실제 문자열 값을 추출합니다.
      title = jsonDecode(ogTitle!);
      // 정규 표현식을 사용하여 'stock'과 'total' 사이의 값을 추출
      RegExp regExp = RegExp(r'stock/(\d+)/total');
      final matches = regExp.firstMatch(url);
      if (matches != null && matches.groupCount >= 1) {
        codeValue = matches.group(1)!; // 1번 그룹이 'stock'과 'total' 사이의 값
      } else {
        return;
      }
    } else {
      return;
    }
    if (title == null) {
      return;
    }

    String stockName = title.split(' - ').first.trimRight();
    if(RegExp(r'^\d+$').hasMatch(stockName) || stockName.contains('/') || stockName.contains('?') || stockName.contains('&')){
      return;
    }
    final Box<RecentItem> recentBox = Hive.box<RecentItem>('recent');

// 똑같은 code를 가진 element의 키를 찾기
    dynamic existingItemKey;
    recentBox.toMap().forEach((key, item) {
      if (item.code == codeValue) {
        existingItemKey = key;
      }
    });

// 만약 존재한다면, 기존 아이템 삭제
    if (existingItemKey != null) {
      await recentBox.delete(existingItemKey);
    }

// 새로운 RecentItem 생성
    final recentItem = RecentItem(
      dateVisited: DateTime.now(),
      code: codeValue,
      name: stockName,
      isFav: false,
    );

// 새 아이템 추가
    await recentBox.add(recentItem);
  }

  addCurrentUrlToHistory(String url) async {
    String? title = await controller.getTitle();
    final Box<HistoryItem> historyBox = Hive.box<HistoryItem>('history');
    final historyItem =
    HistoryItem(url: url, title: title ?? url, dateVisited: DateTime.now());
    await historyBox.add(historyItem);
  }
}
