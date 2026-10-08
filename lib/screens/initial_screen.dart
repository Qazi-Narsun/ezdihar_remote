import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/brand_title.dart';
import '../widgets/language_toggle.dart';
import '../widgets/overlay_background.dart';
import '../widgets/pill_button.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  AppLanguage _language = AppLanguage.arabic;

  @override
  Widget build(BuildContext context) {
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset('assets/images/logo.svg'),
                    LanguageToggle(
                      selected: _language,
                      onChanged: (value) => setState(() => _language = value),
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandTitle(),
                    const SizedBox(height: 40),
                    PillButton(label: 'Start Journey', onPressed: () {}),
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
