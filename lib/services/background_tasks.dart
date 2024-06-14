import 'dart:ui';

import 'package:web_view/services/push_notifications_preference.dart';
import 'package:background_fetch/background_fetch.dart'; // 추가: 백그라운드 플러그인 import
import 'package:http/http.dart' as http; // 추가: HTTP 클라이언트 import
import 'dart:convert'; // 추가: JSON 파싱을 위한 import
import 'package:intl/intl.dart';
import 'package:web_view/services/notification.dart';
import 'package:web_view/services/translation_service.dart';

void _onBackgroundFetch(String taskId) async {
  if (!await PushNotificationPreference.getPushNotificationSetting()) {
    BackgroundFetch.finish(taskId);
    return;
  }

  DateTime now = DateTime.now().toUtc();
  // 특정 시간대(한국시간 오전 8~9(utc로는 23~24)시 사이)에만 서버에 요청을 보냄
  if (now.hour == 23 && now.minute >= 20 && now.minute <= 34) {
    // 서버에 요청을 보내는 부분
    // 현재 날짜를 yyyy-MM-dd 형식으로 포맷
    now = now.add(const Duration(days: 1)); // uct는 하루가 늦으니 하루 +
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    // 현재 날짜를 사용하여 서버에 요청을 보냄
    var response = await http.get(Uri.parse(
        'https://www.similarchart.com/api/market_status/$formattedDate/kospi_daq'));
    var body = json.decode(response.body);
    if (body['is_open']) {
      await TranslationService.loadTranslations();
      String title = TranslationService.translate('latest_update_completed');
      String message = TranslationService.translate('stock_chart_score');
      FlutterLocalNotification.showNotification(title, message);
    }

  }
  BackgroundFetch.finish(taskId);
}

Future<void> configureBackgroundFetch() async {
  FlutterLocalNotification.init();

  // 백그라운드 페치 플러그인 설정
  await BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15,
      // 1시간 마다 실행되도록 설정 (iOS 최소 간격 15분 고려)
      stopOnTerminate: false,
      // 앱 종료 시 백그라운드 작업 중지 여부
      enableHeadless: true,
      // 헤드리스 모드 사용 여부
      requiredNetworkType: NetworkType.ANY,
      // 필요한 네트워크 유형
      startOnBoot: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      requiresDeviceIdle: false,
    ),
    _onBackgroundFetch,
  );
}
