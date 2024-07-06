import 'dart:ui';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreference {
  static const _keyLang = 'languageSetting';
  static const _defaultLang = 'en';
  static const _allowedLanguages = ['ko', 'en'];

  static Future<String> getLanguageSetting() async {
    // 사용자의 핸드폰 언어 설정을 가져옴
    Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
    // 사용자의 언어가 한국어인지 확인
    String localeCode = deviceLocale.languageCode == 'ko' ? 'ko' : _defaultLang;

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_keyLang) ?? localeCode;
    return _validateLanguage(lang);
  }

  static Future<void> setLanguageSetting(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    final validatedLang = _validateLanguage(lang);
    await prefs.setString(_keyLang, validatedLang);
  }

  static String _validateLanguage(String lang) {
    if (_allowedLanguages.contains(lang)) {
      return lang;
    } else {
      return _defaultLang;
    }
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
  static const _defaultPage = 'chart';
  static const _allowedPages = ['chart', 'naver', 'yahoo'];

  static Future<String> getMainPageSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final page = prefs.getString(_key) ?? _defaultPage;
    return _validatePage(page);
  }

  static Future<void> setMainPageSetting(String page) async {
    final prefs = await SharedPreferences.getInstance();
    final validatedPage = _validatePage(page);
    await prefs.setString(_key, validatedPage);
  }

  static String _validatePage(String page) {
    if (_allowedPages.contains(page)) {
      return page;
    } else {
      return _defaultPage;
    }
  }
}
