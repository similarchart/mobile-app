import 'package:webview_flutter/webview_flutter.dart';

// 설정 기능에 대한 콜백 함수
void Function() onHomeTap(WebViewController controller, Uri homeUrl) {
  // 설정 기능 구현
  return () {
    controller.loadRequest(homeUrl);
  };
}