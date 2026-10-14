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
    'buildingTypeTitle': 'Building Type {type}',
    'buildingNo': 'Building no.',
    'floors': 'Floors',
    'numberOfApartments': 'Numbers of Apartment',
    'apartmentType': 'Apartment Type',
    'totalArea': 'Total Area',
    'areaUnit': 'M²',
    'restart': 'Restart',
    'buildingInfo': 'Building info',
    'floorDetails': 'Floor Details',
    'apartments': 'Apartments',
    'selectApartment': 'Select your preferred apartment to start tour',
    'apartmentDetails': 'Apartment Details',
    'type': 'Type',
    'brochure': 'Brochure',
    'brochureError': 'Could not open the brochure',
    'previous': 'Previous page',
    'next': 'Next page',
    'registerInterest': 'Register Interest',
    'yourInformation': 'Your Information',
    'yourName': 'Your Name',
    'yourNameHint': 'Faisal Al Saud',
    'emailAddress': 'Email Address',
    'emailHint': 'faisal.saud@email.com',
    'contactNumber': 'Contact Number',
    'phoneHint': 'Type here...',
    'interestRegistered': 'Interest Registered!',
    'interestRegisteredBody':
        'Thank you for expressing your interest. Our team will contact you via phone or email with the next steps.',
    'restartExperience': 'Restart Experience',
    'masterplan': 'Masterplan',
    'collapse': 'Collapse',
    'tapBuildingHint': 'Tap a building to explore it',
    'tapFloorHint': 'Tap a floor to see its apartments',
    'matchCount': '{n} of {total} buildings match',
    'noMatch': 'No buildings match your filters',
    'clearFilters': 'Clear filters',
    'restartConfirmTitle': 'Restart the experience?',
    'restartConfirmBody': 'You will return to the start screen.',
    'cancel': 'Cancel',
    'stillThereTitle': 'Still there?',
    'stillThereBody': 'Returning to the start in {s}s',
    'stillHere': "I'm here",
    'bedrooms': '{n} Bedroom',
    'previousFloor': 'Floor above',
    'nextFloor': 'Floor below',
    'scrollBack': 'Scroll back',
    'scrollForward': 'Scroll forward',
    'nameError': 'Please enter your name',
    'emailError': 'Enter a valid email address',
    'phoneError': 'Enter a valid phone number',
    'browseMore': 'Browse more units',
    'loadError': 'Could not load building data',
    'retry': 'Retry',
    'ground': 'Ground',
    'groundFloor': 'Ground Floor',
    'floorArea': 'Floor Area',
    'area': 'Area',
    'available': 'Available',
    'unavailable': 'Not Available',
    'noApartmentsOnFloor': 'There are no apartments on this floor',
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
    'buildingTypeTitle': 'نوع المبنى {type}',
    'buildingNo': 'رقم المبنى',
    'floors': 'الطوابق',
    'numberOfApartments': 'عدد الشقق',
    'apartmentType': 'نوع الشقة',
    'totalArea': 'المساحة الإجمالية',
    'areaUnit': 'م²',
    'restart': 'إعادة',
    'buildingInfo': 'معلومات المبنى',
    'floorDetails': 'تفاصيل الطابق',
    'apartments': 'الشقق',
    'selectApartment': 'اختر الشقة المفضلة لديك لبدء الجولة',
    'apartmentDetails': 'تفاصيل الشقة',
    'type': 'النوع',
    'brochure': 'الكتيب',
    'brochureError': 'تعذر فتح الكتيب',
    'previous': 'الصفحة السابقة',
    'next': 'الصفحة التالية',
    'registerInterest': 'سجل اهتمامك',
    'yourInformation': 'معلوماتك',
    'yourName': 'الاسم',
    'yourNameHint': 'فيصل آل سعود',
    'emailAddress': 'البريد الإلكتروني',
    'emailHint': 'faisal.saud@email.com',
    'contactNumber': 'رقم التواصل',
    'phoneHint': 'اكتب هنا...',
    'interestRegistered': 'تم تسجيل اهتمامك!',
    'interestRegisteredBody':
        'شكراً لإبداء اهتمامك. سيتواصل معك فريقنا عبر الهاتف أو البريد الإلكتروني لإبلاغك بالخطوات التالية.',
    'restartExperience': 'إعادة التجربة',
    'masterplan': 'المخطط العام',
    'collapse': 'طيّ',
    'tapBuildingHint': 'اضغط على مبنى لاستكشافه',
    'tapFloorHint': 'اضغط على طابق لعرض شققه',
    'matchCount': '{n} من {total} مبنى مطابق',
    'noMatch': 'لا توجد مبانٍ مطابقة للتصفية',
    'clearFilters': 'مسح التصفية',
    'restartConfirmTitle': 'إعادة التجربة؟',
    'restartConfirmBody': 'ستعود إلى الشاشة الرئيسية.',
    'cancel': 'إلغاء',
    'stillThereTitle': 'هل ما زلت هنا؟',
    'stillThereBody': 'العودة إلى البداية خلال {s} ث',
    'stillHere': 'أنا هنا',
    'bedrooms': '{n} غرف نوم',
    'previousFloor': 'الطابق الأعلى',
    'nextFloor': 'الطابق الأسفل',
    'scrollBack': 'السابق',
    'scrollForward': 'التالي',
    'nameError': 'الرجاء إدخال الاسم',
    'emailError': 'أدخل بريداً إلكترونياً صحيحاً',
    'phoneError': 'أدخل رقم هاتف صحيحاً',
    'browseMore': 'تصفح المزيد من الوحدات',
    'loadError': 'تعذّر تحميل بيانات المباني',
    'retry': 'إعادة المحاولة',
    'ground': 'الأرضي',
    'groundFloor': 'الطابق الأرضي',
    'floorArea': 'مساحة الطابق',
    'area': 'المساحة',
    'available': 'متاحة',
    'unavailable': 'غير متاحة',
    'noApartmentsOnFloor': 'لا توجد شقق في هذا الطابق',
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
  String get buildingNo => _values['buildingNo']!;
  String get floors => _values['floors']!;
  String get numberOfApartments => _values['numberOfApartments']!;
  String get apartmentType => _values['apartmentType']!;
  String get totalArea => _values['totalArea']!;
  String get areaUnit => _values['areaUnit']!;
  String get restart => _values['restart']!;
  String get buildingInfo => _values['buildingInfo']!;
  String get floorDetails => _values['floorDetails']!;
  String get apartments => _values['apartments']!;
  String get selectApartment => _values['selectApartment']!;
  String get apartmentDetails => _values['apartmentDetails']!;
  String get type => _values['type']!;
  String get brochure => _values['brochure']!;
  String get brochureError => _values['brochureError']!;
  String get previous => _values['previous']!;
  String get next => _values['next']!;
  String get registerInterest => _values['registerInterest']!;
  String get yourInformation => _values['yourInformation']!;
  String get yourName => _values['yourName']!;
  String get yourNameHint => _values['yourNameHint']!;
  String get emailAddress => _values['emailAddress']!;
  String get emailHint => _values['emailHint']!;
  String get contactNumber => _values['contactNumber']!;
  String get phoneHint => _values['phoneHint']!;
  String get interestRegistered => _values['interestRegistered']!;
  String get interestRegisteredBody => _values['interestRegisteredBody']!;
  String get restartExperience => _values['restartExperience']!;
  String get masterplan => _values['masterplan']!;
  String get collapse => _values['collapse']!;
  String get tapBuildingHint => _values['tapBuildingHint']!;
  String get tapFloorHint => _values['tapFloorHint']!;
  String get noMatch => _values['noMatch']!;
  String get clearFilters => _values['clearFilters']!;
  String get restartConfirmTitle => _values['restartConfirmTitle']!;
  String get restartConfirmBody => _values['restartConfirmBody']!;
  String get cancel => _values['cancel']!;
  String get stillThereTitle => _values['stillThereTitle']!;
  String get stillHere => _values['stillHere']!;
  String get previousFloor => _values['previousFloor']!;
  String get nextFloor => _values['nextFloor']!;
  String get scrollBack => _values['scrollBack']!;
  String get scrollForward => _values['scrollForward']!;
  String get nameError => _values['nameError']!;
  String get emailError => _values['emailError']!;
  String get phoneError => _values['phoneError']!;
  String get browseMore => _values['browseMore']!;
  String get loadError => _values['loadError']!;
  String get retry => _values['retry']!;
  String get floorArea => _values['floorArea']!;
  String get area => _values['area']!;
  String get available => _values['available']!;
  String get unavailable => _values['unavailable']!;
  String get noApartmentsOnFloor => _values['noApartmentsOnFloor']!;

  /// Short floor value for a sheet floor code: "Ground" for "GF", "3" for "3F".
  String floorNumber(String code) => code == 'GF' ? _values['ground']! : code.replaceAll(RegExp(r'\D'), '');

  /// Floor name for a sheet floor code: "Ground Floor" or "Floor 3".
  String floorName(String code) => code == 'GF' ? _values['groundFloor']! : '$floor ${floorNumber(code)}';
  String matchCount(int n, int total) =>
      _values['matchCount']!.replaceAll('{n}', '$n').replaceAll('{total}', '$total');
  String stillThereBody(int seconds) => _values['stillThereBody']!.replaceAll('{s}', '$seconds');
  String bedrooms(String n) => _values['bedrooms']!.replaceAll('{n}', n);
  String buildingTypeTitle(String type) => _values['buildingTypeTitle']!.replaceAll('{type}', type);
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
