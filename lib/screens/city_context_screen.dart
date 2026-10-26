import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../services/player_connection.dart';
import '../services/ui_feedback.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/fit_panel.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/language_toggle.dart';
import '../widgets/map_pin.dart';
import '../widgets/mirror_state.dart';
import '../widgets/overlay_background.dart';
import '../widgets/panel_close_button.dart';
import 'masterplan_screen.dart';

/// Satellite map of Riyadh showing the project site and nearby landmarks.
/// Opened from [InitialScreen]'s "Start Journey"; the back button pops to it.
///
/// Figma: "City Context" (node 3:1716), authored on a 1920x1081 canvas. The map
/// is laid out on that canvas and scaled to cover the screen; the header sits
/// outside the canvas so it stays pinned to the screen edges.
///
/// Landmarks are tiles; tapping one opens its state (Figma 401:2 .. 401:2018,
/// one frame per landmark): the screen dims, the landmark is shown as a pin
/// with its info card (bottom-start) and Previous / Next (bottom-end) step
/// through [_landmarks]. X, a tap on the dimmed map, Back or Esc close it.
class CityContextScreen extends StatefulWidget {
  const CityContextScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  static const _canvas = Size(1920, 1081);
  static const _assets = 'assets/images/city';

  @override
  State<CityContextScreen> createState() => _CityContextScreenState();
}

class _CityContextScreenState extends State<CityContextScreen> {
  static const _canvas = CityContextScreen._canvas;
  static const _assets = CityContextScreen._assets;

  ValueChanged<Locale> get onLocaleChanged => widget.onLocaleChanged;

  /// Index into [_landmarks] of the open landmark, or null.
  int? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up the masterplan photo so it does not pop in after the tap.
    precacheImage(
      const AssetImage('assets/images/masterplan/background.png'),
      context,
    );
  }

  void _select(int? index) {
    if (index != null) precacheImage(AssetImage(_landmarks[index].image), context);
    if (index == null && _selected != null) PlayerConnection.instance.hideModal();
    setState(() => _selected = index);
  }

  /// The main screen shows the open landmark as a modal over `city_context`, with the
  /// card's texts in the current language. Called after every build, so a language
  /// change updates it; repeats are dropped by [PlayerConnection.showModal].
  void _mirrorLandmark(AppStrings strings) {
    final index = _selected;
    if (!mounted || index == null) return;
    final landmark = _landmarks[index];
    PlayerConnection.instance.showModal({
      'kind': 'landmark',
      'id': landmark.id,
      'title': landmark.name(strings).trim(),
      'description': strings.landmarkDescription,
      'metadata': strings.landmarkDistance(landmark.km, landmark.minutes),
      'locale': strings.locale.languageCode,
    });
  }

  @override
  void dispose() {
    if (_selected != null) PlayerConnection.instance.hideModal();
    super.dispose();
  }

  /// Previous (-1) / next (+1) landmark, wrapping around.
  void _step(int delta) {
    final current = _selected;
    if (current == null) return;
    _select((current + delta) % _landmarks.length);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isArabic = strings.isArabic;
    final selected = _selected == null ? null : _landmarks[_selected!];
    if (selected != null) WidgetsBinding.instance.addPostFrameCallback((_) => _mirrorLandmark(strings));
    return MirrorState(
      state: 'city_context',
      child: PopScope(
        canPop: selected == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _select(null);
        },
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (_selected != null) {
                UiFeedback.dismiss();
                _select(null);
              }
            },
            // Previous / Next follow the reading direction, like the buttons.
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
              UiFeedback.step();
              _step(isArabic ? 1 : -1);
            },
            const SingleActivator(LogicalKeyboardKey.arrowRight): () {
              UiFeedback.step();
              _step(isArabic ? -1 : 1);
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox.fromSize(
                      size: _canvas,
                      child: _MapCanvas(
                        strings: strings,
                        hidden: _selected,
                        onLandmarkTap: _select,
                        onProjectTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                MasterplanScreen(onLocaleChanged: onLocaleChanged),
                          ),
                        ),
                      ),
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
                            size: 48,
                            tooltip: strings.back,
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: Transform.flip(
                              flipX: isArabic,
                              child: SvgPicture.asset('$_assets/arrow_left.svg'),
                            ),
                          ),
                          LanguageToggle(
                            selected: isArabic
                                ? AppLanguage.arabic
                                : AppLanguage.english,
                            onChanged: (language) => onLocaleChanged(
                              Locale(language == AppLanguage.arabic ? 'ar' : 'en'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [...previous, ?current],
                    ),
                    child: selected == null
                        ? const SizedBox.shrink(key: ValueKey('none'))
                        : _Spotlight(
                            key: const ValueKey('spotlight'),
                            landmark: selected,
                            strings: strings,
                            onClose: () => _select(null),
                            onStep: _step,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A landmark on the city map: its tile (base state) and its pin (open state)
/// share one spot, the tile's top-left on the 1920x1081 canvas. Positions,
/// label widths and sides are from Figma 401:2 .. 401:2018.
class _Landmark {
  const _Landmark({
    required this.id,
    required this.name,
    required this.icon,
    required this.tileLeft,
    required this.tileTop,
    required this.tileLabelWidth,
    required this.pinLabelWidth,
    this.labelSide = PinLabelSide.left,
  });

  /// Also the photo's file name and the main screen's landmark modal id.
  final String id;
  final String Function(AppStrings) name;

  /// Glyph in a 24x24 box; [tile] is true on the tile, false on the pin.
  final Widget Function({required bool tile}) icon;
  final double tileLeft;
  final double tileTop;
  final double tileLabelWidth;
  final double pinLabelWidth;
  final PinLabelSide labelSide;

  /// Drive from the project. Figma placeholder, the same for every landmark:
  /// replace with each landmark's figures.
  int get km => 28;
  int get minutes => 26;

  String get image => '${CityContextScreen._assets}/landmarks/$id.jpg';

  /// The pin's 48px marker is centred on the 56px tile.
  double get markerLeft => tileLeft + 4;
  double get markerTop => tileTop;
}

/// Glyph SVG at its natural size, [top] px from the top of the 24x24 slot.
Widget _glyph(String name, {double top = 0}) => Stack(
  clipBehavior: Clip.none,
  children: [
    Positioned(
      top: top,
      left: 0,
      child: SvgPicture.asset('${CityContextScreen._assets}/$name'),
    ),
  ],
);

Widget _plane({required bool tile}) => _glyph('icon_tree.svg');

Widget _graduationCap({required bool tile}) => Stack(
  clipBehavior: Clip.none,
  children: [
    Positioned(
      left: 1.472,
      top: 5.642,
      child: SvgPicture.asset('${CityContextScreen._assets}/icon_graduation.svg'),
    ),
  ],
);

Widget _expo({required bool tile}) => tile ? const _ExpoGlyph.tile() : const _ExpoGlyph.pin();

/// In the order of the Figma state frames, which Previous / Next follow.
final _landmarks = <_Landmark>[
  _Landmark(
    id: 'king_salman_airport',
    name: (s) => s.kingSalmanAirport,
    icon: _plane,
    tileLeft: 894,
    tileTop: 142,
    tileLabelWidth: 166,
    pinLabelWidth: 178,
  ),
  _Landmark(
    id: 'equestrian_club',
    name: (s) => s.equestrianClub,
    icon: ({required tile}) => _glyph('icon_equestrian.svg', top: 1.908),
    tileLeft: 1075,
    tileTop: 150,
    tileLabelWidth: 138,
    pinLabelWidth: 147,
    labelSide: PinLabelSide.right,
  ),
  _Landmark(
    id: 'king_khalid_airport',
    name: (s) => s.kingKhalidAirport,
    icon: _plane,
    tileLeft: 855,
    tileTop: 284,
    tileLabelWidth: 166,
    pinLabelWidth: 179,
  ),
  _Landmark(
    id: 'horse_racing_track',
    name: (s) => s.horseRacingTrack,
    icon: ({required tile}) => _glyph('icon_horse_racing.svg', top: 0.99),
    tileLeft: 1175,
    tileTop: 293,
    tileLabelWidth: 156,
    pinLabelWidth: 159,
  ),
  _Landmark(
    id: 'khuzam_district',
    name: (s) => s.khuzamDistrict,
    icon: ({required tile}) => _glyph('icon_house.svg'),
    tileLeft: 578,
    tileTop: 410,
    tileLabelWidth: 138,
    pinLabelWidth: 141,
    labelSide: PinLabelSide.right,
  ),
  _Landmark(
    id: 'expo_2030',
    name: (s) => s.expo2030,
    icon: _expo,
    tileLeft: 926,
    tileTop: 540,
    tileLabelWidth: 150,
    pinLabelWidth: 150,
  ),
  _Landmark(
    id: 'princess_nourah_university',
    name: (s) => s.princessNourahUniversity,
    icon: _graduationCap,
    tileLeft: 989,
    tileTop: 657,
    tileLabelWidth: 187,
    pinLabelWidth: 184,
    labelSide: PinLabelSide.right,
  ),
  _Landmark(
    id: 'imam_university',
    name: (s) => s.imamUniversity,
    icon: _graduationCap,
    tileLeft: 915,
    tileTop: 785,
    tileLabelWidth: 183,
    pinLabelWidth: 181,
  ),
];

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.strings,
    required this.hidden,
    required this.onLandmarkTap,
    required this.onProjectTap,
  });

  final AppStrings strings;

  /// Landmark drawn as a pin above the dimmed map instead of as a tile.
  final int? hidden;
  final ValueChanged<int> onLandmarkTap;
  final VoidCallback onProjectTap;

  static const _assets = CityContextScreen._assets;

  @override
  Widget build(BuildContext context) {
    final isArabic = strings.isArabic;
    return OverlayBackground(
      image: '$_assets/map_background.png',
      overlayGradient: const RadialGradient(
        radius: 0.5, // of the shorter side: 540.5px vertically, stretched below
        // Edge darkening eased from Figma's 80% to 56% so more map shows.
        colors: [Color(0x26000000), Color(0x8F000000)],
        transform: _EllipseTransform(scaleX: 1301.7 / 540.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Project site polygon; tapping inside its outline opens the
          // masterplan, like the logo card.
          Positioned(
            left: 1241.24,
            top: 256.82,
            width: 186.779,
            height: 251.047,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('$_assets/site_polygon.png', fit: BoxFit.fill),
                // Hit area only (the clip draws nothing): the polygon's outline.
                ClipPath(
                  clipper: const _SitePolygonClipper(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        UiFeedback.select();
                        onProjectTap();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ProjectCallout(onTap: onProjectTap),
          for (final (i, landmark) in _landmarks.indexed)
            if (i != hidden)
              MapTile(
                tileLeft: landmark.tileLeft,
                tileTop: landmark.tileTop,
                labelWidth: landmark.tileLabelWidth,
                labelSide: landmark.labelSide,
                label: landmark.name(strings),
                isArabic: isArabic,
                icon: landmark.icon(tile: true),
                onTap: () => onLandmarkTap(i),
              ),
        ],
      ),
    );
  }
}

/// The open landmark: dimmed, blurred screen (Figma "Frame 14"), the landmark's
/// pin on top of it, its card and the Previous / Next buttons.
class _Spotlight extends StatelessWidget {
  const _Spotlight({
    super.key,
    required this.landmark,
    required this.strings,
    required this.onClose,
    required this.onStep,
  });

  final _Landmark landmark;
  final AppStrings strings;
  final VoidCallback onClose;
  final ValueChanged<int> onStep;

  static const _fade = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = appText(strings, 16, FontWeight.w400, color: AppColors.mapLabelText, spacing: 0.32);
    Widget navButton(String label, int delta, {Color color = AppColors.glass}) => GlassIconButton(
      size: 56,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      onPressed: () => onStep(delta),
      child: SizedBox(
        width: 68,
        child: Text(label, textAlign: TextAlign.center, maxLines: 1, style: buttonStyle),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        // Tap the dimmed map to close.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            UiFeedback.dismiss();
            onClose();
          },
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.scrim),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // Figma: clear centre to black @ 40% from 55% outwards, on
                    // an 1142 x 643 ellipse over the 1920 x 1080 frame.
                    gradient: RadialGradient(
                      radius: 0.595,
                      stops: [0, 0.55484],
                      colors: [Color(0x00000000), Color(0x66000000)],
                      transform: _EllipseTransform(scaleX: 1142.3 / 642.57),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // The pin on the same canvas as the map, so it lands on its tile.
        IgnorePointer(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.fromSize(
              size: CityContextScreen._canvas,
              child: AnimatedSwitcher(
                duration: _fade,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: Stack(
                  key: ValueKey(landmark.id),
                  clipBehavior: Clip.none,
                  children: [
                    MapPin(
                      markerLeft: landmark.markerLeft,
                      markerTop: landmark.markerTop,
                      labelWidth: landmark.pinLabelWidth,
                      labelSide: landmark.labelSide,
                      label: landmark.name(strings),
                      isArabic: strings.isArabic,
                      icon: landmark.icon(tile: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(32),
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.bottomStart,
                child: FitPanel(
                  maxWidthFactor: 0.45,
                  alignment: AlignmentDirectional.bottomStart,
                  child: AnimatedSwitcher(
                    duration: _fade,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: AlignmentDirectional.bottomStart,
                      children: [...previous, ?current],
                    ),
                    child: _LandmarkCard(
                      key: ValueKey(landmark.id),
                      landmark: landmark,
                      strings: strings,
                      onClose: onClose,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    navButton(strings.previousLandmark, -1),
                    const SizedBox(width: 8),
                    navButton(strings.nextLandmark, 1, color: AppColors.accentDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Photo, name, drive time and description of a landmark (Figma "Frame 139").
class _LandmarkCard extends StatelessWidget {
  const _LandmarkCard({
    super.key,
    required this.landmark,
    required this.strings,
    required this.onClose,
  });

  final _Landmark landmark;
  final AppStrings strings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    final secondary = AppColors.textSecondary;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.25, sigmaY: 30.25),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.formPanel,
            borderRadius: radius,
            border: Border.all(color: AppColors.panelBorder, width: 0.64),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 298,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(landmark.image, fit: BoxFit.cover, gaplessPlayback: true),
                      // 32px round X, 12px from the corner; the 48px target
                      // reaches 8px further out.
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: PanelCloseButton(
                          tooltip: strings.close,
                          onPressed: onClose,
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.panelBorder,
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset('${CityContextScreen._assets}/icon_close.svg'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.landmarkInfo,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Figma wraps the name at about 284px.
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 284),
                            child: Text(
                              landmark.name(strings).trim(),
                              style: appText(strings, 24, FontWeight.w500).copyWith(height: 32 / 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          strings.landmarkDistance(landmark.km, landmark.minutes),
                          style: appText(strings, 16, FontWeight.w400, color: secondary).copyWith(height: 28 / 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.landmarkDescription,
                      style: appText(strings, 20, FontWeight.w400, color: secondary).copyWith(height: 28 / 20),
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

/// Outline of `site_polygon.png` (traced on its 374x503 pixels), so only taps
/// on the highlighted site count, not on the map around it.
class _SitePolygonClipper extends CustomClipper<Path> {
  const _SitePolygonClipper();

  static const _image = Size(374, 503);
  static const _points = [
    Offset(97, 45),
    Offset(262, 3),
    Offset(281, 22),
    Offset(362, 225),
    Offset(195, 497),
    Offset(176, 497),
    Offset(6, 318),
    Offset(122, 163),
    Offset(92, 73),
  ];

  @override
  Path getClip(Size size) => Path()
    ..addPolygon([
      for (final p in _points)
        Offset(
          p.dx * size.width / _image.width,
          p.dy * size.height / _image.height,
        ),
    ], true);

  @override
  bool shouldReclip(_SitePolygonClipper oldClipper) => false;
}

/// Callout linking the site polygon to the project logo card.
class _ProjectCallout extends StatelessWidget {
  const _ProjectCallout({required this.onTap});

  /// Tapping the logo card opens the masterplan.
  final VoidCallback onTap;

  static const _assets = CityContextScreen._assets;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Leader line, mirrored so it runs from the card down-left to the dot.
        // Line and dot lie over the site polygon: let taps reach it.
        Positioned(
          left: 1366.5,
          top: 232,
          child: IgnorePointer(
            child: Transform.flip(
              flipX: true,
              child: SvgPicture.asset('$_assets/callout_line.svg'),
            ),
          ),
        ),
        Positioned(
          left: 1359,
          top: 302.5,
          child: IgnorePointer(
            child: SvgPicture.asset('$_assets/callout_dot.svg'),
          ),
        ),
        Positioned(
          left: 1481,
          top: 198,
          child: GestureDetector(
            onTap: () {
              UiFeedback.select();
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 22, 14),
              decoration: BoxDecoration(
                color: AppColors.calloutCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.panelBorder),
                boxShadow: const [
                  BoxShadow(color: Color(0x3D000000), blurRadius: 6),
                ],
              ),
              child: const _ProjectLogo(),
            ),
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
        ? GoogleFonts.notoSansArabic(
            fontSize: 18,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          )
        : GoogleFonts.baskervville(
            fontSize: 19,
            height: 1.05,
            color: Colors.white,
          );
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
/// Figma insets (top, right, bottom, left as percentages of a box): the 48x55
/// marker body on the pin, the 56x56 tile on the tile.
class _ExpoGlyph extends StatelessWidget {
  const _ExpoGlyph.pin() : _box = const Size(48, 55), _origin = const Offset(11.95, 12), _pieces = _pinPieces;
  const _ExpoGlyph.tile() : _box = const Size(56, 56), _origin = const Offset(16, 16), _pieces = _tilePieces;

  /// Box the insets are relative to, and where this glyph's 24x24 slot sits in it.
  final Size _box;
  final Offset _origin;
  final List<(String, double, double, double, double)> _pieces;

  static const _assets = CityContextScreen._assets;

  // (file, top, right, bottom, left) — Figma insets in percent.
  static const _pinPieces = [
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

  // Figma 401:250 (tile).
  static const _tilePieces = [
    ('expo_0.svg', 32.16, 31.83, 50.00, 49.99),
    ('expo_1.svg', 49.99, 31.85, 32.16, 49.98),
    ('expo_2.svg', 32.15, 50.00, 50.01, 31.85),
    ('expo_3.svg', 50.00, 50.00, 32.14, 31.83),
    ('expo_4.svg', 41.71, 45.22, 41.71, 45.20),
    ('expo_5.svg', 58.60, 52.45, 32.16, 36.96),
    ('expo_6.svg', 58.62, 36.99, 32.16, 52.42),
    ('expo_7.svg', 32.14, 52.45, 58.65, 36.98),
    ('expo_8.svg', 32.15, 37.01, 58.65, 52.43),
  ];

  @override
  Widget build(BuildContext context) {
    final w = _box.width, h = _box.height;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (file, t, r, b, l) in _pieces)
          Positioned(
            left: w * l / 100 - _origin.dx,
            top: h * t / 100 - _origin.dy,
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
