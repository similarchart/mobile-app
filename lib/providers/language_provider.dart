import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale?>((ref) => LanguageNotifier());

class LanguageNotifier extends StateNotifier<Locale?> {
  LanguageNotifier() : super(null) {
    _loadLocale();
  }

  void setLocale(Locale locale) {
    state = locale;
    _saveLocale(locale);
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? prefLang = prefs.getString('languageSetting');
    if (prefLang == null){
      // 사용자의 핸드폰 언어 설정을 가져옴
      Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
      // 사용자의 언어가 한국어인지 확인
      Locale locale = deviceLocale.languageCode == 'ko' ? deviceLocale : const Locale('en');
      _saveLocale(locale);
      prefLang = locale.languageCode;
    }

    state = Locale(prefLang);
  }

  void _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('languageSetting', locale.languageCode);
  }
}