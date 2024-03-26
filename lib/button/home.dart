import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/services/language_preference.dart';

void onHomeTap(WebViewController controller) async {
  // 현재 웹뷰의 URL을 가져옵니다.
  String? currentUrl = await controller.currentUrl();
  Uri uri = Uri.parse(currentUrl ?? "");

  String prefer_lang = await LanguagePreference.getLanguageSetting();
  // 현재 URL에서 언어 쿼리 매개변수(lang)를 확인합니다.
  String lang = uri.queryParameters['lang'] ?? prefer_lang; // 기본값은 'ko'

  // 새로운 홈 URL을 만들되, 현재 언어 설정을 유지합니다.
  Uri newHomeUrl = Uri.parse('https://www.similarchart.com?lang=$lang');

  // 새로운 홈 URL로 페이지를 로드합니다.
  controller.loadRequest(newHomeUrl);
}