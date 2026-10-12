import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_strings.dart';
import '../widgets/brand_title.dart';
import 'city_context_screen.dart';
import '../widgets/language_toggle.dart';
import '../widgets/overlay_background.dart';
import '../widgets/pill_button.dart';

class InitialScreen extends StatelessWidget {
  const InitialScreen({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: OverlayBackground(
        image: 'assets/images/initial_screen.png',
        overlayImage: 'assets/images/overlay_frame.png',
        child: SafeArea(
          minimum: const EdgeInsets.all(32),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                // Row follows the ambient Directionality, so it mirrors in RTL.
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset('assets/images/logo.svg'),
                    LanguageToggle(
                      selected: strings.isArabic
                          ? AppLanguage.arabic
                          : AppLanguage.english,
                      onChanged: (language) => onLocaleChanged(
                        Locale(language == AppLanguage.arabic ? 'ar' : 'en'),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandTitle(
                      name: strings.brandName,
                      tagline: strings.tagline,
                      isArabic: strings.isArabic,
                    ),
                    const SizedBox(height: 40),
                    PillButton(
                      label: strings.startJourney,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CityContextScreen(onLocaleChanged: onLocaleChanged),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
