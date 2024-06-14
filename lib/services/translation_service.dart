import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TranslationService {
  static Map<String, String> _localizedStrings = {};

  static Future<void> loadTranslations() async {
    Locale locale = Locale(Intl.getCurrentLocale().split('_')[0]);
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
