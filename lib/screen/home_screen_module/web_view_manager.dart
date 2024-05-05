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
    Uri homeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');
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
    Uri uri = Uri.parse(url);
    bool startsWithDomestic = url.startsWith(Urls.naverDomesticUrl);
    bool startsWithWorld = url.startsWith(Urls.naverWorldUrl);

    String codeValue;
    String stockName = '';
    if (uri.queryParameters.containsKey('code')) {
      codeValue = uri.queryParameters['code']!;
      String? title = await controller.getTitle();

      stockName = title!.split(' - 비슷한').first.trimRight();
      stockName = stockName.split(' - 네이버').first.trimRight();
      stockName = stockName.split(' - 미지원').first.trimRight();
      if (RegExp(r'^\d+$').hasMatch(stockName) ||
          stockName.contains('http') ||
          stockName.contains('?') ||
          stockName.contains('=')) {
        return;
      }
    } else if (startsWithWorld || startsWithDomestic) {
      String? ogTitle = (await controller.runJavaScriptReturningResult(
              "document.querySelector('meta[property=\"og:title\"]').content;"))
          as String?;
      if(ogTitle == null){
        return;
      }

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
        stockName = await controller.runJavaScriptReturningResult(jsCode) as String;
        stockName = stockName.substring(1, stockName.length - 1);
        print("Text content of the element: $stockName");
      } catch (e) {
        print("JavaScript execution failed: $e");
      }

      // 정규 표현식을 사용하여 'stock'과 'total' 사이의 값을 추출
      RegExp regExp = RegExp(r'/stock/([^/]+)/');
      final matches = regExp.firstMatch(url);
      if (matches != null && matches.groupCount >= 1) {
        codeValue = matches.group(1)!; // 1번 그룹이 'stock'과 'total' 사이의 값
        codeValue = codeValue.split('.').first.trimRight();
      } else {
        return;
      }
    } else {
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
