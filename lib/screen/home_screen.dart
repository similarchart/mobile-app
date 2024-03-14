import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/button/home.dart';
import 'package:web_view/button/favorites.dart';
import 'package:web_view/button/history.dart';
import 'package:web_view/button/settings.dart';

final homeUrl = Uri.parse('https://www.similarchart.com');

class HomeScreen extends StatelessWidget {
  WebViewController controller = WebViewController()
    // ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(homeUrl);

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 65), // 이 값을 조절하여 높이를 변경하세요
          child: BottomAppBar(
            color: Color(0xFF343a40), // 배경색 설정
            child: Row(
              children: <Widget>[
                buildBottomIcon(Icons.home, '홈', onHomeTap(controller, homeUrl)),
                buildBottomIcon(Icons.star, '즐겨찾기', onFavoritesTap),
                buildBottomIcon(Icons.history, '방문기록', onHistoryTap),
                buildBottomIcon(Icons.settings, '설정', onSettingsTap),
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
