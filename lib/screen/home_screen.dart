import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/button/home.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/screen/settings_screen.dart';
import 'package:web_view/constants/colors.dart';

final homeUrl = Uri.parse('https://www.similarchart.com?lang=ko');

class HomeScreen extends StatelessWidget {
  final WebViewController controller = WebViewController();

  Future<void> loadInitialUrl(WebViewController controller) async {
    String lang = await LanguagePreference.getLanguageSetting(); // 현재 설정된 언어를 불러옵니다.
    Uri homeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(homeUrl);
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
                buildBottomIcon(Icons.history, '방문기록', () => {}),
                buildBottomIcon(Icons.settings, '설정', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                }),
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
            Text(label, style: TextStyle(fontSize: 12, color: Colors.white)), // 텍스트 색상 및 스타일 설정
          ],
        ),
      ),
    );
  }
}
