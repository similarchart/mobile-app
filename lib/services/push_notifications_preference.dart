import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationPreference {
  static const _keyPushNotification = 'pushNotificationSetting';

// 푸시 알림 설정을 저장하고 로딩하는 함수 (예시는 SharedPreferences를 사용)
  static Future<bool> getPushNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPushNotification) ?? true; // 기본값은 true로 설정
  }

  static Future<void> setPushNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushNotification, value);
  }
}
