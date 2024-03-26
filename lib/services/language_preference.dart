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