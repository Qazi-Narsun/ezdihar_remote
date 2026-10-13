import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

/// App-wide language state, persisted across restarts. Arabic is the default.
class LocaleController extends ChangeNotifier {
  LocaleController._(this._prefs, this._locale);

  static const _key = 'language_code';
  static const _default = Locale('ar');

  final SharedPreferences _prefs;
  Locale _locale;

  Locale get locale => _locale;

  /// Reads the saved language; call once before `runApp`.
  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    final saved = AppStrings.supportedLocales.where((l) => l.languageCode == code);
    return LocaleController._(prefs, saved.isEmpty ? _default : saved.first);
  }

  void setLocale(Locale locale) {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = Locale(locale.languageCode);
    _prefs.setString(_key, _locale.languageCode);
    notifyListeners();
  }
}
