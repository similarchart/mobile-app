import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:web_view/screen/favorite_screen.dart';
import 'package:web_view/utils/utils.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/button/home.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/screen/settings_screen.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/model/history_item.dart';

import '../model/recent_item.dart';

final homeUrl = Uri.parse('https://www.similarchart.com?lang=ko');

class HomeScreen extends StatelessWidget {
  final WebViewController controller = WebViewController();
  final Function() onLoaded;
  bool loadedCalled = false; // 이 플래그는 onLoaded가 호출되었는지 추적합니다.(앱 시작시 한번만 실행되기 위함)

  HomeScreen({required this.onLoaded});

  Future<void> loadInitialUrl() async {
    String lang =
        await LanguagePreference.getLanguageSetting(); // 현재 설정된 언어를 불러옵니다.
    Uri homeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("SimilarChartFinder/1.0/dev")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            _addCurrentUrlToHistory(url);
            _addCurrentUrlToRecent(url);
            if(!loadedCalled) { // 앱 시작시 한번만 로딩완료를 스플래시 스크린에 알리기
              onLoaded();
              loadedCalled = true;
            }
          },
        ),
      )
      ..loadRequest(homeUrl);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 67), // 이 값을 조절하여 높이를 변경하세요
          child: BottomAppBar(
            color: AppColors.primaryColor, // 배경색 설정
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                buildBottomIcon(
                    Icons.brush, '드로잉검색', () => onDrawingSearchTap()),
                buildBottomIcon(
                    Icons.find_replace, '실시간검색', () => onRealTimeSearchTap()),
                buildBottomIcon(Icons.home, '홈', () => onHomeTap(controller)),
                buildBottomIcon(
                    Icons.history, '최근본종목', () => onFavoriteTap(context)),
                buildBottomIcon(
                    Icons.settings, '설정', () => onSettingsTap(context)),
              ],
            ),
          ),
        ),
        body: WebViewWidget(
          controller: controller,
        ),
      ),
    );
  }

  Widget buildBottomIcon(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: Colors.white), // 아이콘 색상 설정
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Colors.white)), // 텍스트 색상 및 스타일 설정
          ],
        ),
      ),
    );
  }

  _addCurrentUrlToRecent(String url) async {
    Uri uri = Uri.parse(url);
    bool startsWithDomestic = url.startsWith('https://m.stock.naver.com/domestic/stock/');
    bool startsWithWorld = url.startsWith('https://m.stock.naver.com/worldstock/stock/');

    String codeValue;
    String? title;
    if (uri.queryParameters.containsKey('code')) {
      codeValue = uri.queryParameters['code']!;
      title = await controller.getTitle();
    }
    else if (startsWithWorld || startsWithDomestic) {
      String? ogTitle = (await controller.runJavaScriptReturningResult(
          "document.querySelector('meta[property=\"og:title\"]').content;"
      )) as String?;

      // JavaScript에서 반환된 JSON 문자열에서 실제 문자열 값을 추출합니다.
      title = jsonDecode(ogTitle!);
      // 정규 표현식을 사용하여 'stock'과 'total' 사이의 값을 추출
      RegExp regExp = RegExp(r'stock/(\d+)/total');
      final matches = regExp.firstMatch(url);
      if (matches != null && matches.groupCount >= 1) {
        codeValue = matches.group(1)!; // 1번 그룹이 'stock'과 'total' 사이의 값
      }
      else {
        return;
      }
    }
    else {
      return;
    }
    if (title == null) {
      return;
    }

    String stockName = title.split('-').first.trimRight();

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

  _addCurrentUrlToHistory(String url) async {
    String? title = await controller.getTitle();
    final Box<HistoryItem> historyBox = Hive.box<HistoryItem>('history');
    final historyItem =
    HistoryItem(url: url, title: title ?? url, dateVisited: DateTime.now());
    await historyBox.add(historyItem);
  }

  onFavoriteTap(BuildContext context) async {
    String? url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoriteScreen()),
    );
    if (url != null) {
      controller.loadRequest(Uri.parse(url));
    }
  }

  // '설정' 버튼 탭 처리를 위한 별도의 함수
  onSettingsTap(BuildContext context) async {
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
      String? currentUrl = await controller.currentUrl();
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
    controller.loadRequest(newUri);
  }

  onDrawingSearchTap() {
    showToastMessage("곧 공개됩니다");
  }

  onRealTimeSearchTap() {
    showToastMessage("곧 공개됩니다");
  }
}
