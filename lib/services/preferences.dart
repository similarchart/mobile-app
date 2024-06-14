import 'dart:ui';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreference {
  static const _keyLang = 'languageSetting';

  static Future<String> getLanguageSetting() async {
    // 사용자의 핸드폰 언어 설정을 가져옴
    Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
    // 사용자의 언어가 한국어인지 확인
    Locale locale = deviceLocale.languageCode == 'ko' ? deviceLocale : const Locale('en');

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLang) ?? locale.languageCode;
  }

  static Future<void> setLanguageSetting(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, lang);
  }
}

class BottomBarPreference {
  static const _keyLang = 'isBottomBarFix';

  static Future<void> setIsBottomBarFixed(bool isVisible) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLang, isVisible);
  }

  static Future<bool> getIsBottomBarFixed() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLang) ?? false;
  }
}

class MainPagePreference {
  static const _key = 'mainPageSetting';

  static Future<String> getMainPageSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'chart';
  }

  static Future<void> setMainPageSetting(String page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, page);
  }
}
