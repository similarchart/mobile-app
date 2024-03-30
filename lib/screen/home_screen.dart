import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:web_view/screen/favorite_screen.dart';
import 'package:web_view/screen/histroy_screen.dart';
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

  Future<void> loadInitialUrl(WebViewController controller) async {
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
          },
        ),
      )
      ..loadRequest(homeUrl);
  }

  _addCurrentUrlToRecent(String url) async {
    Uri uri = Uri.parse(url);
    String? title = await controller.getTitle();
    if (uri.queryParameters.containsKey('code') && title != null) {
      String codeValue = uri.queryParameters['code']!;

      // '- ' 다음에 나오는 단어를 찾기 위한 정규 표현식
      RegExp exp = RegExp(r'- ([\w가-힣]+)');

      // 정규 표현식에 매칭되는 첫 번째 결과 찾기
      RegExpMatch? match = exp.firstMatch(title);

      if (match != null) {
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
          name: match.group(1)!,
          isFav: false,
        );

// 새 아이템 추가
        await recentBox.add(recentItem);
      }
    }
  }

  _addCurrentUrlToHistory(String url) async {
    String? title = await controller.getTitle();
    final Box<HistoryItem> historyBox = Hive.box<HistoryItem>('history');
    final historyItem =
        HistoryItem(url: url, title: title ?? url, dateVisited: DateTime.now());
    await historyBox.add(historyItem);
  }

  @override
  Widget build(BuildContext context) {
    // WebView 로드를 위한 초기 설정
    Future.delayed(Duration.zero, () => loadInitialUrl(controller));

    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 65), // 이 값을 조절하여 높이를 변경하세요
          child: BottomAppBar(
            color: AppColors.primaryColor, // 배경색 설정
            child: Row(
              children: <Widget>[
                buildBottomIcon(Icons.home, '홈', () => onHomeTap(controller)),
                buildBottomIcon(
                    Icons.star, '관심종목', () => onFavoriteTap(context)),
                buildBottomIcon(
                    Icons.history, '방문기록', () => onHistoryTap(context)),
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
                style: TextStyle(
                    fontSize: 12, color: Colors.white)), // 텍스트 색상 및 스타일 설정
          ],
        ),
      ),
    );
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

  onHistoryTap(BuildContext context) async {
    String? url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen()),
    );
    if (url != null) {
      controller.loadRequest(Uri.parse(url));
    }
  }

  // '설정' 버튼 탭 처리를 위한 별도의 함수
  onSettingsTap(BuildContext context) async {
    final doRefresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );

    // 설정 화면에서 돌아온 후 반환된 데이터에 따라 필요한 작업 수행
    if (doRefresh != null && doRefresh) {
      // 현재 웹뷰의 URL을 가져옵니다.
      String? currentUrl = await controller.currentUrl();
      Uri currentUri = Uri.parse(currentUrl ?? "");

      // 선호하는 언어 설정을 가져옵니다.
      String preferLang = await LanguagePreference.getLanguageSetting();

      // 현재 URI의 쿼리 매개변수를 변경하되, lang 매개변수만 새로운 값으로 설정합니다.
      Map<String, String> newQueryParameters =
          Map.from(currentUri.queryParameters);
      newQueryParameters['lang'] = preferLang; // lang 매개변수 업데이트

      // 변경된 쿼리 매개변수를 포함하여 새로운 URI 생성
      Uri newUri = currentUri.replace(queryParameters: newQueryParameters);

      // 새로운 URI로 웹뷰를 로드합니다.
      controller.loadRequest(newUri);
    }
  }
}
