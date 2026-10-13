import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/building_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/language_toggle.dart';
import 'register_interest_screen.dart';

/// Exterior view of a single building with an info panel.
///
/// Figma: "Exterior" with the panel open (81:2) and closed (225:184), authored
/// on a 1920x1081 canvas. Opened from a building button on [MasterplanScreen].
///
/// The panel starts open; its X closes it and leaves an info button at the
/// bottom-start corner that opens it again. Rotate buttons slide the picture
/// (placeholder for 360 frames) and Restart returns to the first page.
class BuildingDetailScreen extends StatefulWidget {
  const BuildingDetailScreen({
    super.key,
    required this.type,
    required this.buildingId,
    required this.onLocaleChanged,
  });

  final BuildingType type;
  final String buildingId;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<BuildingDetailScreen> createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen> {
  static const _assets = 'assets/images/building';
  static const _canvas = Size(1920, 1081);

  /// Exterior frames the rotate buttons cycle through (one for now). The floor
  /// outlines are registered to the first frame only.
  static const _frames = ['$_assets/exterior.jpg'];

  bool _panelOpen = true;
  int _frame = 0;

  /// Index of the selected floor outline, or null when none is selected.
  int? _floor;
  int? _apartment;

  void _selectFloor(int? floor) => setState(() {
        _floor = floor;
        _apartment = null;
      });

  void _rotate(int delta) =>
      setState(() => _frame = (_frame + delta) % _frames.length);

  /// Restart: clear the stack and return to the first page.
  void _restart() => Navigator.of(context).popUntil((route) => route.isFirst);

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
              child: _ExteriorCanvas(
                frame: _frames[_frame],
                showOutlines: _frame == 0,
                selected: _floor,
                onSelect: _selectFloor,
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(32),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassIconButton(
                        size: 48,
                        tooltip: strings.back,
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Transform.flip(
                          flipX: isArabic,
                          child: SvgPicture.asset('assets/images/city/arrow_left.svg'),
                        ),
                      ),
                      LanguageToggle(
                        selected: isArabic ? AppLanguage.arabic : AppLanguage.english,
                        onChanged: (language) => widget.onLocaleChanged(
                          Locale(language == AppLanguage.arabic ? 'ar' : 'en'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Physical left/right: the rotate direction must not mirror in RTL.
                // Hidden on the floor screen (a floor is selected).
                if (_floor == null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GlassIconButton(
                      size: 48,
                      tooltip: strings.rotateLeft,
                      onPressed: () => _rotate(-1),
                      child: SvgPicture.asset('assets/images/masterplan/icon_rotate.svg'),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GlassIconButton(
                      size: 48,
                      tooltip: strings.rotateRight,
                      onPressed: () => _rotate(1),
                      child: Transform.flip(
                        flipX: true,
                        child: SvgPicture.asset('assets/images/masterplan/icon_rotate.svg'),
                      ),
                    ),
                  ),
                ],
                Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: _apartment != null
                      ? _ApartmentDetailsPanel(
                          strings: strings,
                          floor: _floor! + 1,
                          type: widget.type.apartmentTypes[_apartment!],
                          onClose: () => setState(() => _apartment = null),
                        )
                      : _panelOpen
                      ? _InfoPanel(
                          title: _floor != null
                              ? strings.floorDetails
                              : strings.buildingTypeTitle(widget.type.type),
                          strings: strings,
                          type: widget.type,
                          buildingId: widget.buildingId,
                          floor: _floor == null ? null : _floor! + 1,
                          // Only collapses the panel; the floor stays selected.
                          onClose: () => setState(() => _panelOpen = false),
                        )
                      : GlassIconButton(
                          tooltip: strings.buildingInfo,
                          onPressed: () => setState(() => _panelOpen = true),
                          child: SvgPicture.asset('$_assets/icon_info.svg'),
                        ),
                ),
                if (_floor != null && _apartment == null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _ApartmentsPanel(
                      strings: strings,
                      apartmentTypes: widget.type.apartmentTypes,
                      selected: _apartment,
                      onSelect: (i) => setState(() => _apartment = i),
                      onClose: () => _selectFloor(null),
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: GlassIconButton(
                    size: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    onPressed: _restart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset('$_assets/icon_restart.svg'),
                        const SizedBox(width: 8),
                        Text(
                          strings.restart,
                          style: _text(strings, 14, FontWeight.w400, spacing: 0.28),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _text(
  AppStrings strings,
  double size,
  FontWeight weight, {
  Color color = Colors.white,
  double spacing = 0,
}) =>
    strings.isArabic
        ? GoogleFonts.notoSansArabic(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing)
        : GoogleFonts.rubik(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);

/// The building photo with the floor outlines drawn over it, on the Figma
/// canvas so the outlines stay registered to the photo.
class _ExteriorCanvas extends StatelessWidget {
  const _ExteriorCanvas({
    required this.frame,
    required this.showOutlines,
    required this.selected,
    required this.onSelect,
  });

  final String frame;
  final bool showOutlines;
  final int? selected;
  final ValueChanged<int?> onSelect;

  static const _assets = _BuildingDetailScreenState._assets;

  /// Per outline: Figma box (left, top, width, height) and the SVG's overflow
  /// beyond that box in percent (top, right, bottom, left).
  static const _outlines = [
    (box: Rect.fromLTWH(300, 197, 853, 193), inset: (1.6, 0.54, 4.08, 0.82)),
    (box: Rect.fromLTWH(595, 345.5, 226, 74), inset: (4.13, 1.33, 9.52, 3.1)),
    (box: Rect.fromLTWH(605, 414, 213, 70), inset: (4.34, 1.41, 10.31, 3.29)),
    (box: Rect.fromLTWH(605.5, 484, 211.5, 64.5), inset: (4.69, 1.42, 11.11, 3.31)),
    (box: Rect.fromLTWH(608, 550.5, 210, 63), inset: (4.79, 1.43, 11.29, 3.33)),
    (box: Rect.fromLTWH(608, 616, 210, 63), inset: (5.05, 1.43, 11.22, 3.33)),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Tapping empty space clears the selection.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(null),
          child: Image.asset(frame, fit: BoxFit.cover),
        ),
        if (showOutlines)
          for (var i = 0; i < _outlines.length; i++)
          _positioned(i, _outlines[i].box, _outlines[i].inset, '$_assets/floor_outline_${i + 1}.svg'),
      ],
    );
  }

  Widget _positioned(int index, Rect box, (double, double, double, double) inset, String asset) {
    final (top, right, bottom, left) = inset;
    final dimmed = selected != null && selected != index;
    return Positioned(
      left: box.left - box.width * left / 100,
      top: box.top - box.height * top / 100,
      width: box.width * (1 + (left + right) / 100),
      height: box.height * (1 + (top + bottom) / 100),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(index),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? 0.4 : 1,
          child: SvgPicture.asset(asset, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.strings,
    required this.title,
    required this.type,
    required this.buildingId,
    required this.onClose,
    this.floor,
  });

  final AppStrings strings;
  final String title;
  final BuildingType type;
  final String buildingId;
  final VoidCallback onClose;

  /// When set the panel shows floor details instead of building details.
  final int? floor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    final rows = [
      (strings.buildingNo, buildingId),
      if (floor != null) (strings.floor, '$floor') else (strings.floors, '${type.floors}'),
      (strings.numberOfApartments, '${type.apartmentsPerBuilding}'),
      (strings.apartmentType, type.apartmentTypes.join(', ')),
      (strings.totalArea, '${type.totalArea} ${strings.areaUnit}'),
    ];
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          width: 472,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: AppColors.glass, borderRadius: radius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: _text(strings, 24, FontWeight.w500, spacing: -0.24),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.close,
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    icon: SvgPicture.asset('assets/images/masterplan/icon_close.svg', width: 32, height: 32),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 32),
                _InfoRow(strings: strings, label: rows[i].$1, value: rows[i].$2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Details of the tapped apartment (Figma 59:454). Availability is skipped.
class _ApartmentDetailsPanel extends StatelessWidget {
  const _ApartmentDetailsPanel({
    required this.strings,
    required this.floor,
    required this.type,
    required this.onClose,
  });

  final AppStrings strings;
  final int floor;

  /// Apartment type id, e.g. "2BR"; names the plan image.
  final String type;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    final rows = [(strings.floor, '$floor'), (strings.type, type)];
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          width: 472,
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
          decoration: BoxDecoration(color: AppColors.glass, borderRadius: radius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.apartmentDetails,
                      style: _text(strings, 24, FontWeight.w500, spacing: -0.24),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.close,
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    icon: SvgPicture.asset('assets/images/masterplan/icon_close.svg', width: 32, height: 32),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _InfoRow(strings: strings, label: rows[i].$1, value: rows[i].$2),
              ],
              const SizedBox(height: 48),
              Container(
                height: 206,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.apartmentCard,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/apartments/${type.toLowerCase()}.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: _PanelButton(label: strings.brochure, onTap: () {}),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PanelButton(label: strings.registerInterest, filled: true, onTap: () => RegisterInterestScreen.open(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(80),
          border: filled ? null : Border.all(color: AppColors.glassBorder),
        ),
        child: Text(label, style: _text(strings, 18, FontWeight.w500, spacing: -0.18)),
      ),
    );
  }
}

/// Apartment picker shown when a floor is selected (Figma 73:1079).
class _ApartmentsPanel extends StatelessWidget {
  const _ApartmentsPanel({
    required this.strings,
    required this.apartmentTypes,
    required this.selected,
    required this.onSelect,
    required this.onClose,
  });

  final AppStrings strings;

  /// Apartment type ids (e.g. "2BR"); the plan image is
  /// `assets/images/apartments/<id lower-case>.png`.
  final List<String> apartmentTypes;
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  static const _cardWidth = _ApartmentCard.width;
  static const _gap = 16.0;
  static const _minContent = 420.0;
  static const _maxContent = 611.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(40);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          // Figma: 40 padding around a row of 179 cards with 16 gaps (max 611
          // wide); the box hugs the cards, never narrower than the header.
          width: (apartmentTypes.length * _cardWidth + (apartmentTypes.length - 1) * _gap)
                  .clamp(_minContent, _maxContent) +
              80,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(color: AppColors.glass, borderRadius: radius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.apartments, style: _text(strings, 24, FontWeight.w500, spacing: -0.24)),
                        const SizedBox(height: 12),
                        Text(
                          strings.selectApartment,
                          style: _text(strings, 16, FontWeight.w400,
                              color: AppColors.panelSubtitle, spacing: -0.16),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: strings.close,
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    icon: SvgPicture.asset('assets/images/masterplan/icon_close.svg', width: 32, height: 32),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: _ApartmentCard.height,
                // Mouse drag must scroll too (desktop/web default excludes it).
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
                  ),
                  // Centred when the cards fit, scrolls when they overflow.
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < apartmentTypes.length; i++) ...[
                              if (i > 0) const SizedBox(width: _gap),
                              _ApartmentCard(
                                asset: 'assets/images/apartments/${apartmentTypes[i].toLowerCase()}.png',
                                selected: selected == i,
                                onTap: () => onSelect(i),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApartmentCard extends StatelessWidget {
  const _ApartmentCard({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  static const width = 179.0;
  static const height = 180.0;

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: AppColors.apartmentCard, borderRadius: radius),
        foregroundDecoration: selected
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: AppColors.accent, width: 3),
              )
            : null,
        child: ClipRRect(
          borderRadius: radius,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.strings, required this.label, required this.value});

  final AppStrings strings;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = _text(strings, 16, FontWeight.w400, color: Colors.white.withValues(alpha: 0.64), spacing: -0.16);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 18),
        Text(value, style: style),
      ],
    );
  }
}
