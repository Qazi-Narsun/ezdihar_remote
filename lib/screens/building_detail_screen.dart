import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/building_data.dart';
import '../l10n/app_strings.dart';
import '../services/ui_feedback.dart';
import '../theme/app_colors.dart';
import '../widgets/fade_in_asset.dart';
import '../widgets/fit_panel.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/language_toggle.dart';
import '../widgets/panel_close_button.dart';
import '../widgets/restart_dialog.dart';
import '../widgets/status_chip.dart';
import 'brochure_screen.dart';
import 'register_interest_screen.dart';

/// Exterior view of a single building with an info panel.
///
/// Figma: "Exterior" with the panel open (81:2) and closed (225:184), authored
/// on a 1920x1081 canvas. Opened from a building button on [MasterplanScreen].
///
/// The panel starts open; its collapse button closes it and leaves an info
/// button at the bottom-start corner that opens it again. Rotate buttons slide
/// the picture (placeholder for 360 frames) and Restart (after a confirmation)
/// returns to the first page.
///
/// Back (button, system gesture or Esc) closes the topmost layer first: the
/// apartment, then the floor, and only then leaves the screen.
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

  /// Index into [_floors] of the selected floor, or null when none is selected.
  int? _floor;
  int? _apartment;

  /// "Tap a floor" hint; dropped on the first selection or after a while.
  bool _hintVisible = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer(const Duration(seconds: 12), _dismissHint);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _dismissHint() {
    _hintTimer?.cancel();
    if (_hintVisible && mounted) setState(() => _hintVisible = false);
  }

  bool get _hasLayer => _floor != null || _apartment != null;

  /// The building's floors from the data, top floor first, so [_floor]
  /// indexes this list and outline i (drawn top to bottom) is floor i. The
  /// data is the source of truth: a floor without an outline on the photo
  /// is reached with the floor stepper.
  late final List<FloorDetails> _floors = widget.type.floorDetails.reversed.toList();

  /// Apartment types on the selected floor.
  List<String> get _floorTypes => _floors[_floor!].apartmentTypes;

  void _selectFloor(int? floor) {
    if (floor != null) _dismissHint();
    setState(() {
      _floor = floor;
      _apartment = null;
      // A collapsed info panel comes back with the new floor's details.
      if (floor != null) _panelOpen = true;
    });
  }

  /// Closes the apartment details and brings the floor details back.
  void _closeApartment() => setState(() {
        _apartment = null;
        _panelOpen = true;
      });

  /// Steps the selected floor by [delta] (-1 is the floor above).
  void _stepFloor(int delta) {
    final next = _floor! + delta;
    if (next >= 0 && next < _floors.length) _selectFloor(next);
  }

  void _closeTopLayer() {
    if (_apartment != null) {
      _closeApartment();
    } else if (_floor != null) {
      _selectFloor(null);
    }
  }

  void _rotate(int delta) =>
      setState(() => _frame = (_frame + delta) % _frames.length);

  /// Restart: confirm, then clear the stack and return to the first page.
  void _restart() => confirmRestart(context);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isArabic = strings.isArabic;
    final floorStepper = _floor != null;
    return PopScope(
      canPop: !_hasLayer,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeTopLayer();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
            if (_floor == null) {
              UiFeedback.step();
              _rotate(-1);
            }
          },
          const SingleActivator(LogicalKeyboardKey.arrowRight): () {
            if (_floor == null) {
              UiFeedback.step();
              _rotate(1);
            }
          },
          const SingleActivator(LogicalKeyboardKey.arrowUp): () {
            if (_floor != null) {
              UiFeedback.step();
              _stepFloor(-1);
            }
          },
          const SingleActivator(LogicalKeyboardKey.arrowDown): () {
            if (_floor != null) {
              UiFeedback.step();
              _stepFloor(1);
            }
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            _hasLayer ? _closeTopLayer() : Navigator.of(context).maybePop();
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
                    child: _ExteriorCanvas(
                      pulse: _floor == null,
                      frame: _frames[_frame],
                      showOutlines: _frame == 0,
                      floorCount: _floors.length,
                      selected: _floor,
                      onSelect: _selectFloor,
                      floorLabel: (i) => strings.floorName(_floors[i].code),
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
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: _Breadcrumb(
                                    strings: strings,
                                    buildingId: widget.buildingId,
                                    floor: _floor == null ? null : strings.floorName(_floors[_floor!].code),
                                    onMasterplan: () => Navigator.of(context).pop(),
                                    onBuilding: () => _selectFloor(null),
                                  ),
                                ),
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
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 72),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _hintVisible && _floor == null
                                ? StatusChip(
                                    key: const ValueKey('hint'),
                                    label: strings.tapFloorHint,
                                    icon: Icons.touch_app_outlined,
                                  )
                                : const SizedBox.shrink(key: ValueKey('none')),
                          ),
                        ),
                      ),
                      // Physical left/right: the rotate direction must not mirror in RTL.
                      // Hidden on the floor screen (a floor is selected).
                      if (!floorStepper) ...[
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
                      ] else
                        // Opposite the start-side panels, so it never covers them.
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: _FloorStepper(
                            strings: strings,
                            floor: strings.floorName(_floors[_floor!].code),
                            onUp: _floor! > 0 ? () => _stepFloor(-1) : null,
                            onDown: _floor! < _floors.length - 1 ? () => _stepFloor(1) : null,
                          ),
                        ),
                      // Keyed: the rotate buttons / stepper above change the
                      // child count, and an unkeyed panel slot would then take
                      // over its neighbour's switcher (the outgoing building
                      // panel faded out at bottom-centre).
                      Align(
                        key: const ValueKey('startPanel'),
                        alignment: AlignmentDirectional.bottomStart,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: _panelTransition,
                          layoutBuilder: (current, previous) => Stack(
                            alignment: AlignmentDirectional.bottomStart,
                            children: [...previous, ?current],
                          ),
                          child: _startPanel(strings),
                        ),
                      ),
                      Align(
                        key: const ValueKey('apartmentsPanel'),
                        alignment: Alignment.bottomCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: _panelTransition,
                          // Hidden on a floor without apartments (type C's GF).
                          child: _floor != null && _apartment == null && _floorTypes.isNotEmpty
                              ? FitPanel(
                                  key: const ValueKey('apartments'),
                                  child: _ApartmentsPanel(
                                    strings: strings,
                                    apartmentTypes: _floorTypes,
                                    selected: _apartment,
                                    onSelect: (i) => setState(() => _apartment = i),
                                    onClose: () => _selectFloor(null),
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('none')),
                        ),
                      ),
                      Align(
                        key: const ValueKey('restart'),
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
          ),
        ),
      ),
    );
  }

  /// Fade plus a short rise for panels swapping in and out.
  static Widget _panelTransition(Widget child, Animation<double> animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
          child: child,
        ),
      );

  /// The bottom-start slot: apartment details, building/floor info, or the
  /// info button when the panel is collapsed.
  Widget _startPanel(AppStrings strings) {
    if (_apartment != null) {
      return FitPanel(
        key: const ValueKey('apartment'),
        maxWidthFactor: 0.45,
        alignment: AlignmentDirectional.bottomStart,
        child: _ApartmentDetailsPanel(
          strings: strings,
          floor: strings.floorName(_floors[_floor!].code),
          type: _floorTypes[_apartment!],
          details: widget.type.apartments[_floorTypes[_apartment!]],
          onClose: _closeApartment,
        ),
      );
    }
    if (_panelOpen) {
      return FitPanel(
        key: ValueKey(_floor == null ? 'building' : 'floor'),
        maxWidthFactor: 0.45,
        alignment: AlignmentDirectional.bottomStart,
        child: _InfoPanel(
          title: _floor != null ? strings.floorDetails : strings.buildingDetails,
          strings: strings,
          type: widget.type,
          buildingId: widget.buildingId,
          floor: _floor == null ? null : _floors[_floor!].code,
          floorDetails: _floor == null ? null : _floors[_floor!],
          // Only collapses the panel; the floor stays selected.
          onCollapse: () => setState(() => _panelOpen = false),
        ),
      );
    }
    return GlassIconButton(
      key: const ValueKey('info'),
      tooltip: strings.buildingInfo,
      onPressed: () => setState(() => _panelOpen = true),
      child: SvgPicture.asset('$_assets/icon_info.svg'),
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

/// Masterplan › Building › Floor trail. Earlier segments are tappable.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    required this.strings,
    required this.buildingId,
    required this.floor,
    required this.onMasterplan,
    required this.onBuilding,
  });

  final AppStrings strings;
  final String buildingId;

  /// Floor name (e.g. "Floor 3"), or null when no floor is selected.
  final String? floor;
  final VoidCallback onMasterplan;
  final VoidCallback onBuilding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(40);
    final segments = [
      (strings.masterplan, onMasterplan),
      ('${strings.buildingNo} $buildingId', floor == null ? null : onBuilding),
      if (floor != null) (floor!, null),
    ];
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: radius,
            border: Border.all(color: AppColors.glassBorder, width: 0.48),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0)
                  Transform.flip(
                    flipX: strings.isArabic,
                    child: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: segments[i].$2 == null
                      ? null
                      : () {
                          UiFeedback.dismiss();
                          segments[i].$2!();
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      segments[i].$1,
                      style: _text(
                        strings,
                        14,
                        i == segments.length - 1 ? FontWeight.w500 : FontWeight.w400,
                        color: i == segments.length - 1 ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Up / down buttons that move the floor selection without tapping the photo.
class _FloorStepper extends StatelessWidget {
  const _FloorStepper({
    required this.strings,
    required this.floor,
    required this.onUp,
    required this.onDown,
  });

  final AppStrings strings;

  /// Floor name, e.g. "Floor 3".
  final String floor;
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, String tooltip, VoidCallback? onTap) => Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: GlassIconButton(
            size: 48,
            tooltip: tooltip,
            onPressed: onTap,
            child: Icon(icon, color: Colors.white),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(Icons.keyboard_arrow_up_rounded, strings.previousFloor, onUp),
        const SizedBox(height: 8),
        Text(floor, style: _text(strings, 14, FontWeight.w500, spacing: 0.28)),
        const SizedBox(height: 8),
        arrow(Icons.keyboard_arrow_down_rounded, strings.nextFloor, onDown),
      ],
    );
  }
}

/// The building photo with the floor outlines drawn over it, on the Figma
/// canvas so the outlines stay registered to the photo.
class _ExteriorCanvas extends StatefulWidget {
  const _ExteriorCanvas({
    required this.pulse,
    required this.frame,
    required this.showOutlines,
    required this.floorCount,
    required this.selected,
    required this.onSelect,
    required this.floorLabel,
  });

  final String frame;
  final bool showOutlines;

  /// Floors in the data; outline i (top to bottom) is floor i, and outlines
  /// beyond the data's floors are not drawn.
  final int floorCount;
  final int? selected;
  final ValueChanged<int?> onSelect;

  /// Tooltip text (shown on hover / long-press) for the outline at an index.
  final String Function(int index) floorLabel;

  static const _assets = _BuildingDetailScreenState._assets;

  /// Raises the outline SVG's near-transparent fill (3%, the same in every
  /// outline) to a 60% fill in its colour, so the facade shows through as in
  /// Figma 35:2647; the stroke stays opaque. Keep the outlines' fill-opacity
  /// equal, or floors highlight differently.
  static const _selectedFill = ColorFilter.matrix([
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 20, 0, //
  ]);

  /// Per outline: Figma box (left, top, width, height) and the SVG's overflow
  /// beyond that box in percent (top, right, bottom, left).
  static const _outlines = [
    (box: Rect.fromLTWH(300, 197, 853, 193), inset: (1.6, 0.54, 4.08, 0.82)),
    (box: Rect.fromLTWH(595, 345.5, 226, 74), inset: (4.13, 1.33, 9.52, 3.1)),
    (box: Rect.fromLTWH(605, 414, 213, 70), inset: (4.34, 1.41, 10.31, 3.29)),
    (box: Rect.fromLTWH(605.5, 484, 211.5, 64.5), inset: (4.69, 1.42, 11.11, 3.31)),
    (box: Rect.fromLTWH(608, 550.5, 210, 63), inset: (4.79, 1.43, 11.29, 3.33)),
    (box: Rect.fromLTWH(608, 616, 210, 63), inset: (5.05, 1.43, 11.22, 3.33)),
    // GF: a placeholder box over the storey below 1F, until a traced outline exists.
    (box: Rect.fromLTWH(608, 684, 210, 56), inset: (0.0, 0.0, 0.0, 0.0)),
  ];

  /// Draws the attention pulse around the outlines (first-visit hint).
  final bool pulse;

  @override
  State<_ExteriorCanvas> createState() => _ExteriorCanvasState();
}

class _ExteriorCanvasState extends State<_ExteriorCanvas> with SingleTickerProviderStateMixin {
  static const _assets = _ExteriorCanvas._assets;
  static const _outlines = _ExteriorCanvas._outlines;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _pulse.repeat();
  }

  @override
  void didUpdateWidget(_ExteriorCanvas old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.pulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Tapping empty space clears the selection.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelect(null),
          child: FadeInAsset(widget.frame),
        ),
        if (widget.showOutlines)
          for (var i = 0; i < _outlines.length && i < widget.floorCount; i++)
            _positioned(i, _outlines[i].box, _outlines[i].inset, '$_assets/floor_outline_${i + 1}.svg'),
      ],
    );
  }

  Widget _positioned(int index, Rect box, (double, double, double, double) inset, String asset) {
    final (top, right, bottom, left) = inset;
    return Positioned(
      left: box.left - box.width * left / 100,
      top: box.top - box.height * top / 100,
      width: box.width * (1 + (left + right) / 100),
      height: box.height * (1 + (top + bottom) / 100),
      child: _FloorOutline(
        asset: asset,
        label: widget.floorLabel(index),
        selected: widget.selected == index,
        dimmed: widget.selected != null && widget.selected != index,
        pulse: _pulse,
        onTap: () {
          UiFeedback.select();
          widget.onSelect(index);
        },
      ),
    );
  }
}

/// One tappable floor outline. Same feedback as the masterplan building
/// buttons: a pulse ring while the hint is showing, a solid fill and slight
/// grow on hover / press, and dimmed when another floor is selected.
class _FloorOutline extends StatefulWidget {
  const _FloorOutline({
    required this.asset,
    required this.label,
    required this.selected,
    required this.dimmed,
    required this.pulse,
    required this.onTap,
  });

  final String asset;
  final String label;
  final bool selected;
  final bool dimmed;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  State<_FloorOutline> createState() => _FloorOutlineState();
}

class _FloorOutlineState extends State<_FloorOutline> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(widget.asset, fit: BoxFit.fill);
    final active = _hovered || _pressed;
    return Tooltip(
      message: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            setState(() => _pressed = false);
            widget.onTap();
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.dimmed ? 0.4 : 1,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                if (!widget.selected)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: widget.pulse,
                      builder: (context, _) {
                        final t = widget.pulse.value;
                        return Opacity(
                          opacity: widget.pulse.isAnimating ? 1 - t : 0,
                          child: Transform.scale(scale: 1 + 0.18 * t, child: svg),
                        );
                      },
                    ),
                  ),
                AnimatedScale(
                  duration: const Duration(milliseconds: 120),
                  scale: active && !widget.selected ? 1.03 : 1,
                  // The selected floor is filled, not just outlined.
                  child: widget.selected ? ColorFiltered(colorFilter: _ExteriorCanvas._selectedFill, child: svg) : svg,
                ),
              ],
            ),
          ),
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
    required this.onCollapse,
    this.floor,
    this.floorDetails,
  });

  final AppStrings strings;
  final String title;
  final BuildingType type;
  final String buildingId;
  final VoidCallback onCollapse;

  /// Sheet floor code ("GF", "1F"...). When set the panel shows floor details
  /// instead of building details.
  final String? floor;

  /// Data for [floor]; the building's figures are shown when it is missing.
  final FloorDetails? floorDetails;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    final f = floorDetails;
    final rows = [
      (strings.buildingNo, buildingId),
      if (floor != null) (strings.floor, strings.floorName(floor!)) else (strings.floors, '${type.floors}'),
      if (f != null) ...[
        (strings.numberOfApartments, '${f.apartments}'),
        (strings.apartmentTypes, f.apartmentTypes.isEmpty ? '-' : f.apartmentTypes.join(', ')),
        (strings.floorArea, '${f.area} ${strings.areaUnit}'),
      ] else ...[
        (strings.numberOfApartments, '${type.apartmentsPerBuilding}'),
        (strings.apartmentTypes, type.apartmentTypes.join(', ')),
        (strings.totalArea, '${type.totalArea} ${strings.areaUnit}'),
      ],
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
                  // A chevron, not an X: this only tucks the panel away.
                  PanelCloseButton(
                    tooltip: strings.collapse,
                    onPressed: onCollapse,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 28),
                _InfoRow(strings: strings, label: rows[i].$1, value: rows[i].$2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Details of the tapped apartment (Figma 59:454).
class _ApartmentDetailsPanel extends StatelessWidget {
  const _ApartmentDetailsPanel({
    required this.strings,
    required this.floor,
    required this.type,
    required this.details,
    required this.onClose,
  });

  final AppStrings strings;

  /// Floor name in the sheet's convention, e.g. "3F" or "GF".
  final String floor;

  /// Apartment type id, e.g. "2BR"; names the plan image.
  final String type;

  /// Area and availability of [type]; those rows are left out when missing.
  final ApartmentDetails? details;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    final d = details;
    final rows = [
      (strings.floor, floor),
      (strings.type, type),
      if (d != null) (strings.size, '${d.area} ${strings.areaUnit}'),
    ];
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          width: 472,
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
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
                  PanelCloseButton(tooltip: strings.close, onPressed: onClose),
                ],
              ),
              const SizedBox(height: 32),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _InfoRow(strings: strings, label: rows[i].$1, value: rows[i].$2),
              ],
              if (d != null) ...[
                const SizedBox(height: 16),
                _AvailabilityRow(strings: strings, available: d.available),
              ],
              const SizedBox(height: 32),
              Container(
                height: 190,
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
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _PanelButton(label: strings.brochure, onTap: () => BrochureScreen.open(context)),
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
    final radius = BorderRadius.circular(80);
    return Material(
      color: filled ? AppColors.accent : Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: filled ? BorderSide.none : const BorderSide(color: AppColors.glassBorder),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          UiFeedback.select();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(child: Text(label, style: _text(strings, 18, FontWeight.w500, spacing: -0.18))),
        ),
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

  /// Apartment type ids (e.g. "2BR"), never empty: the panel is hidden on a
  /// floor without apartments. The plan image is
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
                  PanelCloseButton(tooltip: strings.close, onPressed: onClose),
                ],
              ),
              const SizedBox(height: 24),
              _CardsRow(
                strings: strings,
                apartmentTypes: apartmentTypes,
                selected: selected,
                onSelect: onSelect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drag-scrollable row of apartment cards that fades at the edges it can still
/// scroll past and offers arrow buttons (mouse users cannot see drag-scroll).
class _CardsRow extends StatefulWidget {
  const _CardsRow({
    required this.strings,
    required this.apartmentTypes,
    required this.selected,
    required this.onSelect,
  });

  final AppStrings strings;
  final List<String> apartmentTypes;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  State<_CardsRow> createState() => _CardsRowState();
}

class _CardsRowState extends State<_CardsRow> {
  final _controller = ScrollController();
  bool _canBack = false;
  bool _canForward = false;

  static const _fade = 0.12;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final back = position.pixels > 1;
    final forward = position.pixels < position.maxScrollExtent - 1;
    if (back != _canBack || forward != _canForward) {
      setState(() {
        _canBack = back;
        _canForward = forward;
      });
    }
  }

  void _scroll(int direction) {
    const step = (_ApartmentCard.width + _ApartmentsPanel._gap) * 2;
    _controller.animateTo(
      (_controller.offset + direction * step).clamp(0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final types = widget.apartmentTypes;
    return SizedBox(
      height: _ApartmentCard.height,
      child: Stack(
        children: [
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => LinearGradient(
              begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
              end: rtl ? Alignment.centerLeft : Alignment.centerRight,
              colors: [
                _canBack ? Colors.transparent : Colors.black,
                Colors.black,
                Colors.black,
                _canForward ? Colors.transparent : Colors.black,
              ],
              stops: const [0, _fade, 1 - _fade, 1],
            ).createShader(rect),
            // Mouse drag must scroll too (desktop/web default excludes it).
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
              ),
              // Centred when the cards fit, scrolls when they overflow.
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < types.length; i++) ...[
                          if (i > 0) const SizedBox(width: _ApartmentsPanel._gap),
                          _ApartmentCard(
                            asset: 'assets/images/apartments/${types[i].toLowerCase()}.png',
                            label: widget.strings.bedrooms(types[i].replaceAll(RegExp(r'\D'), '')),
                            selected: widget.selected == i,
                            onTap: () => widget.onSelect(i),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_canBack)
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: _ScrollArrow(
                tooltip: widget.strings.scrollBack,
                icon: Icons.chevron_left,
                flip: rtl,
                onTap: () => _scroll(-1),
              ),
            ),
          if (_canForward)
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              child: _ScrollArrow(
                tooltip: widget.strings.scrollForward,
                icon: Icons.chevron_right,
                flip: rtl,
                onTap: () => _scroll(1),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScrollArrow extends StatelessWidget {
  const _ScrollArrow({required this.tooltip, required this.icon, required this.flip, required this.onTap});

  final String tooltip;
  final IconData icon;
  final bool flip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.glass,
          shape: const CircleBorder(side: BorderSide(color: AppColors.glassBorder, width: 0.48)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              UiFeedback.tap();
              onTap();
            },
            child: SizedBox.square(
              dimension: 40,
              child: Transform.flip(flipX: flip, child: Icon(icon, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApartmentCard extends StatelessWidget {
  const _ApartmentCard({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const width = 179.0;
  static const height = 180.0;

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final radius = BorderRadius.circular(16);
    return GestureDetector(
      onTap: () {
        UiFeedback.select();
        onTap();
      },
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(color: AppColors.apartmentCard, borderRadius: radius),
        foregroundDecoration: selected
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: AppColors.accent, width: 3),
              )
            : null,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: radius,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: _text(strings, 14, FontWeight.w500, color: AppColors.calloutCard),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Availability" row with a green (Available) or red (Not Available) badge.
class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.strings, required this.available});

  final AppStrings strings;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            strings.availability,
            style: _text(strings, 16, FontWeight.w400, color: AppColors.textSecondary, spacing: -0.16),
          ),
        ),
        const SizedBox(width: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: available ? AppColors.availableBadge : AppColors.unavailableBadge,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            available ? strings.available : strings.unavailable,
            style: _text(strings, 16, FontWeight.w400, spacing: -0.16),
          ),
        ),
      ],
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
    final style = _text(strings, 16, FontWeight.w400, color: AppColors.textSecondary, spacing: -0.16);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 18),
        Text(value, style: style),
      ],
    );
  }
}
