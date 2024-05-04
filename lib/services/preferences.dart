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