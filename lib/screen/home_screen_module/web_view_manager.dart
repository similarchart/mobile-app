import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_view/services/preferences.dart';
import 'package:web_view/model/history_item.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/constants/urls.dart';

class WebViewManager {
  WebViewController controller;
  Function(bool) updateFABVisibility;
  Function(bool) updateLoadingStatus;
  Function(bool) updateFirstLoad;

  WebViewManager(this.controller, this.updateFABVisibility,
      this.updateLoadingStatus, this.updateFirstLoad);

  Future<void> saveCookies() async {
    final Object? result =
        await controller.runJavaScriptReturningResult("document.cookie");
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (result != null) {
      // Since the expected result is a string, cast it safely
      final String cookies = result.toString();
      // Save the raw cookie string
      await prefs.setString('cookies', cookies);
    }
  }

  Future<void> loadCookies() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cookiesString = prefs.getString('cookies');
    if (cookiesString != null) {
      // Split the cookie string and reconstruct each cookie
      List<String> allCookies = cookiesString.split('; ');
      for (var cookie in allCookies) {
        // Assuming each cookie string is in 'key=value' format
        List<String> cookieParts = cookie.split('=');
        if (cookieParts.length >= 2) {
          String name = cookieParts[0];
          String value = cookieParts.sublist(1).join('=');
          // JavaScript to set the cookie back in the WebView
          await controller.runJavaScript(
              "document.cookie = '${name}=${value}; path=/; expires=Fri, 31 Dec 9999 23:59:59 GMT';");
        }
      }
    }
  }

  void updateFloatingActionButtonVisibility(String url) {
    bool isNaverHome = (url == Urls.naverHomeUrl);
    bool startsWithDomestic = url.startsWith(Urls.naverDomesticUrl);
    bool startsWithWorld = url.startsWith(Urls.naverWorldUrl);
    updateFABVisibility(startsWithDomestic || startsWithWorld || isNaverHome);
  }

  Future<void> loadInitialUrl() async {
    await loadCookies(); // 앱 시작 시 쿠키 로드
    String lang = await LanguagePreference.getLanguageSetting();
    String page = await MainPagePreference.getMainPageSetting();
    Uri homeUrl;
    if (page == 'chart') {
      homeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');
    } else {
      homeUrl = Uri.parse(Urls.naverHomeUrl);
    }
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("SimilarChartFinder/1.0/dev")
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            updateLoadingStatus(false);
          },
          onPageFinished: (String url) {
            updateFloatingActionButtonVisibility(url);
            updateFirstLoad(false);
            addCurrentUrlToHistory(url);
            addCurrentUrlToRecent(url);
            saveCookies(); // 페이지 로드 완료 후 쿠키 저장
          },
        ),
      )
      ..loadRequest(homeUrl);
  }

  addCurrentUrlToRecent(String url) async {
    final Box<RecentItem> recentBox = Hive.box<RecentItem>('recent');
    Uri uri = Uri.parse(url);
    bool startsWithDomestic = url.startsWith(Urls.naverDomesticUrl);
    bool startsWithWorld = url.startsWith(Urls.naverWorldUrl);
    bool startsWithWorldEtf = url.startsWith(Urls.naverWorldEtfUrl);

    String codeValue;
    String stockName = '';
    if (uri.queryParameters.containsKey('code')) {
      codeValue = uri.queryParameters['code']!;
      String? title = await controller.getTitle();

      stockName = title!.split(' - 비슷한').first.trimRight();
      stockName = stockName.split(' - Stock').first.trimRight();
      stockName = stockName.split(' - Similar').first.trimRight();
      stockName = stockName.split(' - 네이버').first.trimRight();
      stockName = stockName.split(' - 미지원').first.trimRight();
      if (RegExp(r'^\d+$').hasMatch(stockName) ||
          stockName.contains('http') ||
          stockName.contains('?') ||
          stockName.contains('=') ||
          stockName.contains('비슷한') ||
          stockName.contains('네이버')) {
        return;
      }

      // 항상 종합 비교 결과 페이지로 설정 (N일치 결과 페이지로 올 경우)
      String lang = await LanguagePreference.getLanguageSetting();
      url =
          'https://www.similarchart.com/stock_info/?code=$codeValue&lang=$lang';
    } else if (startsWithWorld || startsWithDomestic || startsWithWorldEtf) {
      String jsCode = """
      var element = document.querySelector('[class^="GraphMain_name"]');
      if (element) {
          var textContent = '';
          // Loop through child nodes
          for (var node of element.childNodes) {
              // Check if the node is a text node
              if (node.nodeType === Node.TEXT_NODE) {
                  textContent += node.nodeValue.trim(); // Add text content, trim for removing whitespace
              }
          }
          textContent; // This will be the direct text content of the element
      } else {
          'Element not found';
      }
      """;

      try {
        stockName =
            await controller.runJavaScriptReturningResult(jsCode) as String;
        stockName = stockName.substring(1, stockName.length - 1);
        print("Text content of the element: $stockName");
      } catch (e) {
        print("JavaScript execution failed: $e");
      }

      if (stockName == 'Element not found') {
        return;
      }

      // 정규 표현식을 사용하여 'stock'과 'total' 사이의 값을 추출
      RegExp regExp = RegExp(r'/stock/([^/]+)/');
      RegExp regExpEtf = RegExp(r'/etf/([^/]+)/');
      final matches = regExp.firstMatch(url);
      final matchesEtf = regExpEtf.firstMatch(url);
      if (matches != null && matches.groupCount >= 1) {
        codeValue = matches.group(1)!; // 1번 그룹이 'stock'과 'total' 사이의 값
      } else if (matchesEtf != null && matchesEtf.groupCount >= 1) {
        codeValue = matchesEtf.group(1)!;
      } else {
        return;
      }
      codeValue = codeValue.split('.').first.trimRight();
    } else {
      return;
    }

    // Check if the first item is the one you're looking for
    if (recentBox.isNotEmpty &&
        recentBox.getAt(recentBox.length - 1)?.url == url &&
        recentBox.getAt(recentBox.length - 1)?.name == stockName) {
      // If the first item is the desired item, simply return
      return;
    }

// 똑같은 code를 가진 element의 키를 찾기
    dynamic existingItemKey;
    recentBox.toMap().forEach((key, item) {
      if (item.code == codeValue) {
        existingItemKey = key;
      }
    });

    bool isFav = false;
// 만약 존재한다면, 기존 아이템 삭제
    if (existingItemKey != null) {
      isFav = recentBox.get(existingItemKey)!.isFav;
      await recentBox.delete(existingItemKey);
    }

// 새로운 RecentItem 생성
    final recentItem = RecentItem(
      dateVisited: DateTime.now(),
      code: codeValue,
      name: stockName,
      url: url,
      isFav: isFav,
    );

// 새 아이템 추가
    await recentBox.add(recentItem);
  }

  addCurrentUrlToHistory(String url) async {
    String? title = (await controller.runJavaScriptReturningResult(
            "document.querySelector('meta[property=\"og:title\"]').content;"))
        as String?;
    title = title?.substring(1, title.length - 1);

    final Box<HistoryItem> historyBox = Hive.box<HistoryItem>('history');
    final historyItem =
        HistoryItem(url: url, title: title ?? url, dateVisited: DateTime.now());
    await historyBox.add(historyItem);
  }
}
