import 'package:flutter/material.dart';
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
    final languageCode = prefs.getString('languageSetting') ?? 'ko';
    state = Locale(languageCode);
  }

  void _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('languageSetting', locale.languageCode);
  }
}