import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:web_view/screen/histroy_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/button/home.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/screen/settings_screen.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/model/history_item.dart';

final homeUrl = Uri.parse('https://www.similarchart.com?lang=ko');

class HomeScreen extends StatelessWidget {
  final WebViewController controller = WebViewController();

  Future<void> loadInitialUrl(WebViewController controller) async {
    String lang =
        await LanguagePreference.getLanguageSetting(); // 현재 설정된 언어를 불러옵니다.
    Uri homeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');
    controller
      //..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("SimilarChartFinder/1.0/dev")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            String? title = await controller.getTitle();
            _addCurrentUrlToHistory(url,title??url);
          },
        ),
      )
      ..loadRequest(homeUrl);
  }
  
  Future<void> _addCurrentUrlToHistory(String url,String title) async {
    final Box<HistoryItem> historyBox = Hive.box<HistoryItem>('history');
    final historyItem = HistoryItem(url: url,title: title, dateVisited: DateTime.now(), isFav: false);
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
                buildBottomIcon(Icons.star, '즐겨찾기', () => {}),
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

  onHistoryTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen()),
    );
  }

// '설정' 버튼 탭 처리를 위한 별도의 함수
  Future<void> onSettingsTap(BuildContext context) async {
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
