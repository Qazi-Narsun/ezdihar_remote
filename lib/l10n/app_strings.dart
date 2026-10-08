import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// App translations. Arabic locales render right-to-left, English left-to-right.
class AppStrings {
  const AppStrings._(this.locale, this._values);

  final Locale locale;
  final Map<String, String> _values;

  static const supportedLocales = [Locale('en'), Locale('ar')];
  static const delegate = _AppStringsDelegate();

  static const _en = {
    'brandName': 'MASHAEL AL FURSAN',
    'tagline': 'Discover a New Way of Living',
    'startJourney': 'Start Journey',
  };

  static const _ar = {
    'brandName': 'مشاعل الفرسان',
    'tagline': 'اكتشف طريقة جديدة للعيش',
    'startJourney': 'ابدأ الرحلة',
  };

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  bool get isArabic => locale.languageCode == 'ar';

  String get brandName => _values['brandName']!;
  String get tagline => _values['tagline']!;
  String get startJourney => _values['startJourney']!;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => const ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) {
    final isArabic = locale.languageCode == 'ar';
    return SynchronousFuture(
      AppStrings._(locale, isArabic ? AppStrings._ar : AppStrings._en),
    );
  }

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
