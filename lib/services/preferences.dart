import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreference {
  static const _keyLang = 'languageSetting';

  static Future<String> getLanguageSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLang) ?? 'ko';
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
    return prefs.getString(_key) ?? 'naver';
  }

  static Future<void> setMainPageSetting(String page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, page);
  }
}

class UserAgentPreference{
  static const _key = 'UserAgentSetting';

  static Future<String> getUserAgent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '';
  }

  static Future<void> setUserAgent(String userAgent) async {
    if(userAgent.startsWith('SimilarChartFinder')){
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, userAgent);
  }
}
