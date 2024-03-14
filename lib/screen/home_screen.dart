import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

final homeUrl = Uri.parse('https://www.similarchart.com');

class HomeScreen extends StatelessWidget {
  WebViewController controller = WebViewController()
    // ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(homeUrl);

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea( // SafeArea 추가
      child: Scaffold(
        bottomNavigationBar: BottomAppBar(
          color: Color(0xFF343a40), // 배경색 설정
          child: Row(
            children: <Widget>[
              buildBottomIcon(Icons.home, '홈', () {
                controller.loadRequest(homeUrl);
              }),
              buildBottomIcon(Icons.star , '즐겨찾기', () {
                // 즐겨찾기 기능
              }),
              buildBottomIcon(Icons.history, '방문기록', () {
                // 방문기록 기능
              }),
              buildBottomIcon(Icons.settings, '설정', () {
                // 설정 기능
              }),
            ],
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
