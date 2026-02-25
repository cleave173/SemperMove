import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _key = 'locale';
  Locale _locale = const Locale('ru');

  Locale get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('ru'),
    Locale('kk'),
    Locale('en'),
  ];

  static const Map<String, String> localeNames = {
    'ru': 'Русский',
    'kk': 'Қазақша',
    'en': 'English',
  };

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'ru';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    notifyListeners();
  }
}
