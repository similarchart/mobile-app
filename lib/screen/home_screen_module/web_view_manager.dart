import 'dart:async';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_view/services/preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_view/screen/home_screen_module/floating_action_button_manager.dart';
import 'package:web_view/model/history_item.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/constants/urls.dart';
import 'package:web_view/system/logger.dart';

class WebViewManager {
  late FloatingActionButtonManager fabManager;
  late PullToRefreshController pullToRefreshController; // 당겨서 새로고침 컨트롤러

  Future<void> saveCookies(webViewController) async {
    if (webViewController == null) {
      return;
    }

    final Object? result =
        await webViewController!.evaluateJavascript(source: "document.cookie");
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (result != null) {
      // Since the expected result is a string, cast it safely
      final String cookies = result.toString();
      // Save the raw cookie string
      await prefs.setString('cookies', cookies);
    }
  }

  Future<void> loadCookies(webViewController) async {
    if (webViewController == null) {
      return;
    }
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
          await webViewController!.evaluateJavascript(
              source:
                  "document.cookie = '${name}=${value}; path=/; expires=Fri, 31 Dec 9999 23:59:59 GMT';");
        }
      }
    }
  }

  addCurrentUrlToRecent(String url, webViewController) async {
    if (webViewController == null) {
      return;
    }

    final Box<RecentItem> recentBox = Hive.box<RecentItem>('recent');
    Uri uri = Uri.parse(url);
    bool startsWithDomestic = url.startsWith(Urls.naverDomesticUrl);
    bool startsWithWorld = url.startsWith(Urls.naverWorldUrl);
    bool startsWithWorldEtf = url.startsWith(Urls.naverWorldEtfUrl);
    bool startsWithYahooItem = url.startsWith(Urls.yahooItemUrl);

    String codeValue;
    String stockName = '';
    if (uri.queryParameters.containsKey('code')) {
      codeValue = uri.queryParameters['code']!;
      String? title = await webViewController.getTitle();
      if (title == null) {return;}
      stockName = title.split(' - 비슷한').first.trimRight();
      stockName = stockName.split(' - Stock').first.trimRight();
      stockName = stockName.split(' - Similar').first.trimRight();
      stockName = stockName.split(' - 네이버').first.trimRight();
      stockName = stockName.split(' - 미지원').first.trimRight();
      if (RegExp(r'^\d+$').hasMatch(stockName) ||
          stockName.contains('http') ||
          stockName.contains('Pattern Search') ||
          stockName.contains('Similar') ||
          stockName.contains('similar') ||
          stockName.contains('Validation') ||
          stockName.contains('검증') ||
          stockName.contains('?') ||
          stockName.contains('=') ||
          stockName.contains('비슷한') ||
          stockName.contains('없음') ||
          stockName.contains('네이버')){
        return;
      }

      // 항상 종합 비교 결과 페이지로 설정 (N일치 결과 페이지로 올 경우)
      String lang = await LanguagePreference.getLanguageSetting();
      url =
          'https://www.similarchart.com/stock_info/?code=$codeValue&lang=$lang';
    } else if (startsWithYahooItem){
      // 정규 표현식을 사용하여 'stock'과 'total' 사이의 값을 추출
      RegExp regExp = RegExp(r'/quote/([^/]+)/');
      final matches = regExp.firstMatch(url);
      if (matches != null && matches.groupCount >= 1) {
        codeValue = matches.group(1)!; // 1번 그룹이 'stock'과 'total' 사이의 값
      } else {
        return;
      }

      String? title = await webViewController.getTitle();
      if (title == null) {return;}
      stockName = title.split('($codeValue)').first.trimRight();
      if (RegExp(r'^\d+$').hasMatch(stockName) ||
          stockName.contains('Yahoo Finance') ||
          stockName.contains('(')){
        return;
      }

      url = Urls.yahooItemUrl + codeValue;
      codeValue = codeValue.split('.').first.trimRight();
    }
    else if (startsWithWorld || startsWithDomestic || startsWithWorldEtf) {
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
        stockName = (await webViewController.evaluateJavascript(source: jsCode))
            as String;
        Log.instance.i("Text content of the element: $stockName");
      } catch (e) {
        Log.instance.e("JavaScript execution failed: $e");
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
      if (startsWithWorldEtf) {
        url = Urls.naverWorldEtfUrl + codeValue;
      } else if (startsWithWorld) {
        url = Urls.naverWorldUrl + codeValue;
      } else if (startsWithDomestic) {
        url = Urls.naverDomesticUrl + codeValue;
      }

      codeValue = codeValue.split('.').first.trimRight();
    } else {
      return;
    }

    if (stockName.contains('없음')) {
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

  Future<void> removeDuplicateRecentItem() async {
    final Box<RecentItem> recentBox = Hive.box<RecentItem>('recent');

    Map<String, List<dynamic>> codeToKeys = {};

    // 모든 항목을 반복하여 code와 해당하는 키를 매핑
    recentBox.keys.forEach((key) {
      String code = recentBox.get(key)!.code;
      if (codeToKeys.containsKey(code)) {
        codeToKeys[code]!.add(key);
      } else {
        codeToKeys[code] = [key];
      }
    });

    // 중복된 code를 가진 키들을 찾아 첫 번째를 제외하고 삭제
    for (var entry in codeToKeys.entries) {
      if (entry.value.length > 1) {
        // 첫 번째 요소를 제외한 모든 키를 삭제
        for (var key in entry.value.sublist(1)) {
          await recentBox.delete(key);
        }
      }
    }
  }

  addCurrentUrlToHistory(String url, webViewController) async {
    if (webViewController == null) {
      return;
    }

    String? title = (await webViewController.evaluateJavascript(
            source:
                "document.querySelector('meta[property=\"og:title\"]').content;"))
        as String?;

    final Box<HistoryItem> historyBox = Hive.box<HistoryItem>('history');
    final historyItem =
        HistoryItem(url: url, title: title ?? url, dateVisited: DateTime.now());
    await historyBox.add(historyItem);
  }

  static Future<void> loadUrl(
      InAppWebViewController webViewController, String url) async {
    await webViewController.loadUrl(
        urlRequest: URLRequest(
            url: WebUri(url, forceToStringRawValue: true),
            headers: {"SimilarChart-App": Urls.appHeader}));
  }
}
