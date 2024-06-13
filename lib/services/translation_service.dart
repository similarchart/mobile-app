import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';

class TranslationService {
  static Map<String, String> _localizedStrings = {};

  static Future<void> loadTranslations(Locale locale) async {
    String jsonString =
    await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
  }

  static String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
