import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/language_toggle.dart';
import '../widgets/map_pin.dart';
import '../widgets/overlay_background.dart';

/// Satellite map of Riyadh showing the project site and nearby landmarks.
/// Opened from [InitialScreen]'s "Start Journey"; the back button pops to it.
///
/// Figma: "City Context" (node 3:1716), authored on a 1920x1081 canvas. The map
/// is laid out on that canvas and scaled to cover the screen; the header sits
/// outside the canvas so it stays pinned to the screen edges.
class CityContextScreen extends StatelessWidget {
  const CityContextScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  static const _canvas = Size(1920, 1081);
  static const _assets = 'assets/images/city';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isArabic = strings.isArabic;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.fromSize(
              size: _canvas,
              child: _MapCanvas(strings: strings),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(32),
            child: Align(
              alignment: Alignment.topCenter,
              // Row follows the ambient Directionality, so it mirrors in RTL.
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassIconButton(
                    tooltip: strings.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Transform.flip(
                      flipX: isArabic,
                      child: SvgPicture.asset('$_assets/arrow_left.svg'),
                    ),
                  ),
                  LanguageToggle(
                    selected: isArabic ? AppLanguage.arabic : AppLanguage.english,
                    onChanged: (language) => onLocaleChanged(
                      Locale(language == AppLanguage.arabic ? 'ar' : 'en'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({required this.strings});

  final AppStrings strings;

  static const _assets = CityContextScreen._assets;

  @override
  Widget build(BuildContext context) {
    final isArabic = strings.isArabic;
    return OverlayBackground(
      image: '$_assets/map_background.png',
      overlayGradient: const RadialGradient(
        radius: 0.5, // of the shorter side: 540.5px vertically, stretched below
        colors: [Color(0x33000000), Color(0xCC000000)],
        transform: _EllipseTransform(scaleX: 1301.7 / 540.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Project site polygon.
          Positioned(
            left: 1241.24,
            top: 256.82,
            width: 186.779,
            height: 251.047,
            child: Image.asset('$_assets/site_polygon.png', fit: BoxFit.fill),
          ),
          const _ProjectCallout(),
          MapPin(
            markerLeft: 896, markerTop: 144, labelWidth: 178,
            label: strings.kingSalmanAirport, isArabic: isArabic,
            icon: _glyph('icon_tree.svg'),
          ),
          MapPin(
            markerLeft: 1082, markerTop: 160, labelWidth: 147,
            labelSide: PinLabelSide.right,
            label: strings.equestrianClub, isArabic: isArabic,
            icon: _glyph('icon_equestrian.svg', top: 1.908),
          ),
          MapPin(
            markerLeft: 1184, markerTop: 299, labelWidth: 159,
            label: strings.horseRacingTrack, isArabic: isArabic,
            icon: _glyph('icon_horse_racing.svg', top: 0.99),
          ),
          MapPin(
            markerLeft: 863, markerTop: 293, labelWidth: 179,
            label: strings.kingKhalidAirport, isArabic: isArabic,
            icon: _glyph('icon_tree.svg'),
          ),
          MapPin(
            markerLeft: 582, markerTop: 416, labelWidth: 141,
            labelSide: PinLabelSide.right,
            label: strings.khuzamDistrict, isArabic: isArabic,
            icon: _graduationCap(),
          ),
          MapPin(
            markerLeft: 929, markerTop: 545, labelWidth: 150,
            label: strings.expo2030, isArabic: isArabic,
            icon: const _ExpoGlyph(),
          ),
          MapPin(
            markerLeft: 991, markerTop: 667, labelWidth: 184,
            labelSide: PinLabelSide.right,
            label: strings.princessNourahUniversity, isArabic: isArabic,
            icon: _graduationCap(),
          ),
          MapPin(
            markerLeft: 919, markerTop: 784, labelWidth: 181,
            label: strings.imamUniversity, isArabic: isArabic,
            icon: _graduationCap(),
          ),
        ],
      ),
    );
  }

  /// Glyph SVG at its natural size, [top] px from the top of the 24x24 slot.
  static Widget _glyph(String name, {double top = 0}) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: top, left: 0, child: SvgPicture.asset('$_assets/$name')),
        ],
      );

  static Widget _graduationCap() => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 1.472,
            top: 5.642,
            child: SvgPicture.asset('$_assets/icon_graduation.svg'),
          ),
        ],
      );
}

/// Callout linking the site polygon to the project logo card.
class _ProjectCallout extends StatelessWidget {
  const _ProjectCallout();

  static const _assets = CityContextScreen._assets;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Leader line, mirrored so it runs from the card down-left to the dot.
        Positioned(
          left: 1366.5,
          top: 232,
          child: Transform.flip(
            flipX: true,
            child: SvgPicture.asset('$_assets/callout_line.svg'),
          ),
        ),
        Positioned(
          left: 1359,
          top: 302.5,
          child: SvgPicture.asset('$_assets/callout_dot.svg'),
        ),
        Positioned(
          left: 1481,
          top: 198,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 22, 14),
            decoration: BoxDecoration(
              color: AppColors.calloutCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x29FFFFFF)),
              boxShadow: const [BoxShadow(color: Color(0x3D000000), blurRadius: 6)],
            ),
            child: const _ProjectLogo(),
          ),
        ),
      ],
    );
  }
}

/// Project wordmark (localized text) beside the flame emblem; follows ambient
/// text direction so the emblem stays at the end of the line.
class _ProjectLogo extends StatelessWidget {
  const _ProjectLogo();

  static const _assets = CityContextScreen._assets;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final style = strings.isArabic
        ? GoogleFonts.notoSansArabic(fontSize: 18, height: 1.1, fontWeight: FontWeight.w600, color: Colors.white)
        : GoogleFonts.baskervville(fontSize: 19, height: 1.05, color: Colors.white);
    return SizedBox(
      width: 101.93,
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(strings.projectName, style: style),
            ),
          ),
          const SizedBox(width: 5),
          SvgPicture.asset('$_assets/project_emblem.svg'),
        ],
      ),
    );
  }
}

/// Expo 2030 glyph, assembled from nine vector pieces whose positions are the
/// Figma insets (top, right, bottom, left as fractions of the 48x55 marker).
class _ExpoGlyph extends StatelessWidget {
  const _ExpoGlyph();

  static const _assets = CityContextScreen._assets;

  // (file, top, right, bottom, left) — Figma insets in percent.
  static const _pieces = [
    ('expo_0.svg', 25.47, 28.80, 56.36, 49.99),
    ('expo_1.svg', 43.62, 28.82, 38.20, 49.97),
    ('expo_2.svg', 25.46, 50.00, 56.37, 28.82),
    ('expo_3.svg', 43.64, 50.00, 38.18, 28.80),
    ('expo_4.svg', 35.20, 44.43, 47.92, 44.40),
    ('expo_5.svg', 52.39, 52.86, 38.20, 34.79),
    ('expo_6.svg', 52.41, 34.82, 38.19, 52.83),
    ('expo_7.svg', 25.45, 52.86, 65.17, 34.81),
    ('expo_8.svg', 25.46, 34.84, 65.17, 52.83),
  ];

  @override
  Widget build(BuildContext context) {
    // The pieces are positioned against the 48x55 marker body; this glyph slot
    // is offset (11.95, 12) inside it, so shift back.
    const w = 48.0, h = 55.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (file, t, r, b, l) in _pieces)
          Positioned(
            left: w * l / 100 - 11.95,
            top: h * t / 100 - 12,
            width: w * (1 - (l + r) / 100),
            height: h * (1 - (t + b) / 100),
            child: SvgPicture.asset('$_assets/$file', fit: BoxFit.fill),
          ),
      ],
    );
  }
}

/// Stretches a radial gradient horizontally around the box centre so a circle
/// becomes the ellipse Figma specifies.
class _EllipseTransform extends GradientTransform {
  const _EllipseTransform({required this.scaleX});

  final double scaleX;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final c = bounds.center;
    // x' = scaleX * (x - cx) + cx
    return Matrix4.identity()
      ..setEntry(0, 0, scaleX)
      ..setEntry(0, 3, c.dx * (1 - scaleX));
  }
}
