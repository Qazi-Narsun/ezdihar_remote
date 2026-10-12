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
    'projectName': 'Mashael\nAlfursan',
    'tagline': 'Discover a New Way of Living',
    'startJourney': 'Start Journey',
    'back': 'Back',
    'horseRacingTrack': 'Horse Racing Track',
    'kingKhalidAirport': 'King Khalid International Airport',
    'khuzamDistrict': 'Khuzam District',
    'equestrianClub': 'Equestrian Club',
    'princessNourahUniversity': 'Princess Nourah Bint Abdulrahman University ',
    'kingSalmanAirport': 'King Salman International Airport',
    'imamUniversity': 'Imam Muhammad Ibn Saud Islamic University',
    'expo2030': 'Expo 2030 Riyadh',
    'filters': 'Filters',
    'filtersSubtitle': 'Refine your search to discover the project property',
    'gallery': 'Gallery',
    'floor': 'Floor',
    'surface': 'Surface',
    'sqm': 'sqm',
    'availability': 'Availability',
    'hideUnavailableUnits': 'Hide unavailable units',
    'buildingType': 'Building Type',
    'close': 'Close',
    'rotateLeft': 'Rotate left',
    'rotateRight': 'Rotate right',
    'resetView': 'Reset view',
  };

  static const _ar = {
    'brandName': 'مشاعل الفرسان',
    'projectName': 'مشاعل\nالفرسان',
    'tagline': 'اكتشف طريقة جديدة للعيش',
    'startJourney': 'ابدأ الرحلة',
    'back': 'رجوع',
    'horseRacingTrack': 'مضمار سباق الخيل',
    'kingKhalidAirport': 'مطار الملك خالد الدولي',
    'khuzamDistrict': 'حي خزام',
    'equestrianClub': 'نادي الفروسية',
    'princessNourahUniversity': 'جامعة الأميرة نورة بنت عبدالرحمن',
    'kingSalmanAirport': 'مطار الملك سلمان الدولي',
    'imamUniversity': 'جامعة الإمام محمد بن سعود الإسلامية',
    'expo2030': 'إكسبو 2030 الرياض',
    'filters': 'التصفية',
    'filtersSubtitle': 'حدّد بحثك لاكتشاف العقار المناسب في المشروع',
    'gallery': 'المعرض',
    'floor': 'الطابق',
    'surface': 'المساحة',
    'sqm': 'م²',
    'availability': 'التوفر',
    'hideUnavailableUnits': 'إخفاء الوحدات غير المتاحة',
    'buildingType': 'نوع المبنى',
    'close': 'إغلاق',
    'rotateLeft': 'تدوير لليسار',
    'rotateRight': 'تدوير لليمين',
    'resetView': 'إعادة ضبط العرض',
  };

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  bool get isArabic => locale.languageCode == 'ar';

  String get brandName => _values['brandName']!;
  String get projectName => _values['projectName']!;
  String get tagline => _values['tagline']!;
  String get startJourney => _values['startJourney']!;
  String get back => _values['back']!;
  String get horseRacingTrack => _values['horseRacingTrack']!;
  String get kingKhalidAirport => _values['kingKhalidAirport']!;
  String get khuzamDistrict => _values['khuzamDistrict']!;
  String get equestrianClub => _values['equestrianClub']!;
  String get princessNourahUniversity => _values['princessNourahUniversity']!;
  String get kingSalmanAirport => _values['kingSalmanAirport']!;
  String get imamUniversity => _values['imamUniversity']!;
  String get expo2030 => _values['expo2030']!;
  String get filters => _values['filters']!;
  String get filtersSubtitle => _values['filtersSubtitle']!;
  String get gallery => _values['gallery']!;
  String get floor => _values['floor']!;
  String get surface => _values['surface']!;
  String get sqm => _values['sqm']!;
  String get availability => _values['availability']!;
  String get hideUnavailableUnits => _values['hideUnavailableUnits']!;
  String get buildingType => _values['buildingType']!;
  String get close => _values['close']!;
  String get rotateLeft => _values['rotateLeft']!;
  String get rotateRight => _values['rotateRight']!;
  String get resetView => _values['resetView']!;
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
