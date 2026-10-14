import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/building_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/fade_in_asset.dart';
import '../widgets/fit_panel.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/language_toggle.dart';
import '../widgets/panel_close_button.dart';
import '../widgets/restart_dialog.dart';
import '../widgets/rotating_view.dart';
import '../widgets/status_chip.dart';
import 'building_detail_screen.dart';

/// Which panel the bottom navigation currently has open above the map.
enum _MasterplanPanel { filters, gallery }

/// Aerial masterplan view with a bottom navigation (Filters | Gallery), rotate
/// left / right buttons at the screen sides and a reset-view button.
///
/// Figma: "Masterplan" (24:1403), "Masterplan_Filters" (49:5630) and
/// "Masterplan_Gallery" (49:6205), authored on a 1920x1081 canvas.
///
/// Navigation behaviour: Filters and Gallery are mutually exclusive toggles.
/// Tapping an inactive tab opens its panel (replacing the other one); tapping
/// the active tab or the panel's close button returns to the bare map. The
/// rotate buttons turn the aerial view and the reset button restores it.
class MasterplanScreen extends StatefulWidget {
  const MasterplanScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<MasterplanScreen> createState() => _MasterplanScreenState();
}

class _MasterplanScreenState extends State<MasterplanScreen> {
  static const _assets = 'assets/images/masterplan';

  /// Holding a rotate button keeps turning, one step per this interval.
  static const _holdRepeat = Duration(milliseconds: 450);
  static const _maxTurns = 3;

  _MasterplanPanel? _panel;
  int _turns = 0;

  // Filter state (the map has no unit data yet, so it is only held here).
  RangeValues _floors = _floorBounds;
  RangeValues _surface = _surfaceBounds;
  bool _hideUnavailable = false;
  final Set<String> _buildingTypes = {};
  int _selectedImage = 0;

  static const _floorBounds = RangeValues(3, 26);
  static const _surfaceBounds = RangeValues(141, 400);

  List<BuildingType> _types = const [];
  bool _loadFailed = false;

  /// "Tap a building" hint (and the pulse on the buttons); dropped on the
  /// first interaction or after a few seconds.
  bool _hintVisible = true;
  Timer? _hintTimer;

  /// Centres of the buildings along the upper lane, left to right, on the
  /// 2000x1147 aerial photo.
  static const _laneCentres = [
    Offset(5, 440), Offset(35, 370), Offset(125, 350), Offset(210, 325),
    Offset(320, 310), Offset(410, 325), Offset(495, 305), Offset(600, 300),
    Offset(690, 315), Offset(770, 305), Offset(890, 310), Offset(950, 345),
    Offset(1160, 345), Offset(1230, 300), Offset(1335, 295), Offset(1430, 310),
    Offset(1515, 295), Offset(1620, 295), Offset(1720, 300), Offset(1795, 285),
    Offset(1905, 285), Offset(1990, 295),
  ];

  /// Lane slots taken by the two large corner buildings (type C). The rest
  /// are type A first, then type B, in lane order. Placeholder until the real
  /// building-to-slot mapping is provided.
  static const _typeCSlots = {10, 13};

  @override
  void initState() {
    super.initState();
    _load();
    _hintTimer = Timer(const Duration(seconds: 12), _dismissHint);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up the next screen's photo so it does not pop in.
    precacheImage(const AssetImage('assets/images/building/exterior.jpg'), context);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _load() {
    setState(() => _loadFailed = false);
    BuildingType.loadAll().then((types) {
      if (mounted) setState(() => _types = types);
    }).catchError((Object _) {
      if (mounted) setState(() => _loadFailed = true);
    });
  }

  void _dismissHint() {
    _hintTimer?.cancel();
    if (_hintVisible && mounted) setState(() => _hintVisible = false);
  }

  /// Building types and floor range are the filters that apply to a building;
  /// surface and availability need per-unit data that does not exist yet.
  bool get _filtersActive => _buildingTypes.isNotEmpty || _floors != _floorBounds;

  bool _matches(BuildingType t) =>
      (_buildingTypes.isEmpty || _buildingTypes.contains(t.type)) &&
      t.floors >= _floors.start &&
      t.floors <= _floors.end;

  void _clearFilters() => setState(() {
        _floors = _floorBounds;
        _surface = _surfaceBounds;
        _hideUnavailable = false;
        _buildingTypes.clear();
      });

  List<_BuildingSpot> _spots() {
    if (_types.isEmpty) return const [];
    final queues = {
      for (final t in _types) t.type: (type: t, ids: t.buildingIds.iterator),
    };
    BuildingType? next(String letter) {
      final q = queues[letter];
      return q != null && q.ids.moveNext() ? q.type : null;
    }

    final spots = <_BuildingSpot>[];
    var aLeft = queues['A']?.type.buildingCount ?? 0;
    for (var i = 0; i < _laneCentres.length; i++) {
      final letter = _typeCSlots.contains(i) ? 'C' : (aLeft-- > 0 ? 'A' : 'B');
      final type = next(letter);
      if (type == null) continue;
      spots.add(_BuildingSpot(
        _laneCentres[i],
        type,
        queues[letter]!.ids.current,
        matched: _matches(type),
      ));
    }
    return spots;
  }

  void _openBuilding(BuildingType type, String id) {
    _dismissHint();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BuildingDetailScreen(
          type: type,
          buildingId: id,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
  }

  void _togglePanel(_MasterplanPanel panel) {
    _dismissHint();
    setState(() => _panel = _panel == panel ? null : panel);
  }

  void _rotate(int delta) {
    _dismissHint();
    setState(() => _turns = (_turns + delta).clamp(-_maxTurns, _maxTurns));
  }

  /// Restart: confirm, then clear the stack and return to the first page.
  void _reset() => confirmRestart(context);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isArabic = strings.isArabic;
    final spots = _spots();
    final matchCount = spots.where((s) => s.matched).length;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _rotate(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _rotate(1),
        const SingleActivator(LogicalKeyboardKey.escape): () => setState(() => _panel = null),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          RotatingView(
            turns: _turns,
            maxTurns: _maxTurns,
            onStep: _rotate,
            child: _MapCanvas(
              buildings: spots,
              onSelect: _openBuilding,
              pulse: _hintVisible && !_filtersActive,
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(32),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 72),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _statusChip(
                        strings,
                        matchCount: matchCount,
                        total: spots.length,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassIconButton(
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
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        alignment: Alignment.bottomCenter,
                        child: switch (_panel) {
                          _MasterplanPanel.filters => FitPanel(child: _buildFilters(strings)),
                          _MasterplanPanel.gallery => FitPanel(maxHeightFactor: 0.5, child: _buildGallery(strings)),
                          null => const SizedBox(width: 0, height: 0),
                        },
                      ),
                      if (_panel != null) const SizedBox(height: 24),
                      _BottomNav(
                        strings: strings,
                        panel: _panel,
                        onSelect: _togglePanel,
                      ),
                    ],
                  ),
                ),
                // Figma 225:542 / 225:526: rotate buttons at the screen sides,
                // vertically centred. Physical left/right: must not mirror in RTL.
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassIconButton(
                    size: 48,
                    repeatEvery: _holdRepeat,
                    tooltip: strings.rotateLeft,
                    onPressed: () => _rotate(-1),
                    child: SvgPicture.asset('$_assets/icon_rotate.svg'),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GlassIconButton(
                    size: 48,
                    repeatEvery: _holdRepeat,
                    tooltip: strings.rotateRight,
                    onPressed: () => _rotate(1),
                    // Figma uses the same glyph mirrored for the opposite direction.
                    child: Transform.flip(
                      flipX: true,
                      child: SvgPicture.asset('$_assets/icon_rotate.svg'),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: GlassIconButton(
                    size: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    onPressed: _reset,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset('$_assets/icon_reset.svg'),
                        const SizedBox(width: 8),
                        Text(strings.restart, style: _text(strings, 14, FontWeight.w400, spacing: 0.28)),
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
    );
  }

  /// Hint, filter result count, "no match" or load-error chip under the header.
  Widget _statusChip(AppStrings strings, {required int matchCount, required int total}) {
    if (_loadFailed) {
      return StatusChip(
        key: const ValueKey('error'),
        label: strings.loadError,
        action: strings.retry,
        onAction: _load,
      );
    }
    if (_types.isEmpty) return const SizedBox.shrink(key: ValueKey('none'));
    if (_filtersActive) {
      return StatusChip(
        key: ValueKey('count-$matchCount'),
        label: matchCount == 0 ? strings.noMatch : strings.matchCount(matchCount, total),
        action: strings.clearFilters,
        onAction: _clearFilters,
      );
    }
    if (_hintVisible && _panel == null) {
      return StatusChip(
        key: const ValueKey('hint'),
        label: strings.tapBuildingHint,
        icon: Icons.touch_app_outlined,
      );
    }
    return const SizedBox.shrink(key: ValueKey('none'));
  }

  Widget _buildFilters(AppStrings strings) {
    return _GlassPanel(
      radius: 32,
      padding: 32,
      child: SizedBox(
        width: 552,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.filters, style: _text(strings, 24, FontWeight.w500, spacing: -0.24)),
                      const SizedBox(height: 12),
                      Text(
                        strings.filtersSubtitle,
                        style: _text(strings, 16, FontWeight.w400, color: AppColors.panelSubtitle, spacing: -0.16),
                      ),
                    ],
                  ),
                ),
                // Space is always reserved so the panel keeps its size when
                // the first filter is applied.
                Visibility(
                  visible: _filtersActive || _hideUnavailable,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      strings.clearFilters,
                      style: _text(strings, 14, FontWeight.w500, color: AppColors.accent),
                    ),
                  ),
                ),
                PanelCloseButton(
                  tooltip: strings.close,
                  onPressed: () => setState(() => _panel = null),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FilterCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _RangeFilter(
                      title: Text(strings.floor, style: _label(strings)),
                      bounds: _floorBounds,
                      values: _floors,
                      onChanged: (v) => setState(() => _floors = v),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: _RangeFilter(
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(strings.size, style: _label(strings)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.unitChip,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              strings.sqm,
                              style: _text(strings, 8, FontWeight.w600, spacing: -0.08).copyWith(
                                color: Colors.white.withValues(alpha: 0.64),
                              ),
                            ),
                          ),
                        ],
                      ),
                      bounds: _surfaceBounds,
                      values: _surface,
                      onChanged: (v) => setState(() => _surface = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _FilterCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.availability, style: _label(strings)),
                          const SizedBox(height: 24),
                          _CheckOption(
                            label: strings.hideUnavailableUnits,
                            checked: _hideUnavailable,
                            onChanged: (v) => setState(() => _hideUnavailable = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _FilterCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.buildingType, style: _label(strings)),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 40,
                            runSpacing: 12,
                            children: [
                              for (final type in const ['A', 'B', 'C'])
                                _CheckOption(
                                  label: type,
                                  checked: _buildingTypes.contains(type),
                                  onChanged: (v) => setState(() {
                                    v ? _buildingTypes.add(type) : _buildingTypes.remove(type);
                                  }),
                                ),
                            ],
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
    );
  }

  Widget _buildGallery(AppStrings strings) {
    // The third and fourth Figma tiles are the same picture.
    const images = ['gallery_1.png', 'gallery_2.png', 'gallery_3.png', 'gallery_3.png'];
    return _GlassPanel(
      radius: 40,
      padding: 40,
      child: SizedBox(
        width: 973,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(strings.gallery, style: _text(strings, 28, FontWeight.w400)),
                ),
                PanelCloseButton(
                  tooltip: strings.close,
                  onPressed: () => setState(() => _panel = null),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 291,
              // Mouse/trackpad drag is off by default on desktop and web.
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  itemCount: images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, i) => _GalleryTile(
                    image: '$_assets/${images[i]}',
                    selected: i == _selectedImage,
                    onTap: () => setState(() => _selectedImage = i),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _text(
    AppStrings strings,
    double size,
    FontWeight weight, {
    Color color = Colors.white,
    double spacing = 0,
  }) =>
      strings.isArabic
          ? GoogleFonts.notoSansArabic(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing)
          : GoogleFonts.rubik(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);

  static TextStyle _label(AppStrings strings) =>
      _text(strings, 16, FontWeight.w600, color: AppColors.textSecondary, spacing: -0.16);
}

/// The aerial photo with one box button per building of the upper lane. Laid
/// out on the photo's own pixel grid so the buttons stay on their buildings.
class _MapCanvas extends StatefulWidget {
  const _MapCanvas({required this.buildings, required this.onSelect, required this.pulse});

  final List<_BuildingSpot> buildings;
  final void Function(BuildingType type, String id) onSelect;

  /// Draws an attention ring around the buttons (first-visit hint).
  final bool pulse;

  static const _size = Size(2000, 1147);

  /// Visible box and touch target of a building button, on the photo grid.
  static const _button = 44.0;
  static const _target = 64.0;

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(_MapCanvas old) {
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
    const target = _MapCanvas._target;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox.fromSize(
        size: _MapCanvas._size,
        child: Stack(
          children: [
            const Positioned.fill(
              child: FadeInAsset('assets/images/masterplan/background.png'),
            ),
            for (final b in widget.buildings)
              Positioned(
                left: b.center.dx - target / 2,
                top: b.center.dy - target / 2,
                width: target,
                height: target,
                child: _BuildingButton(
                  label: b.id,
                  matched: b.matched,
                  pulse: _pulse,
                  onTap: () => widget.onSelect(b.type, b.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuildingSpot {
  const _BuildingSpot(this.center, this.type, this.id, {this.matched = true});

  final Offset center;
  final BuildingType type;
  final String id;

  /// False when the active filters exclude this building (it is dimmed).
  final bool matched;
}

/// Building box button: 44px visible box in a larger touch target, with hover
/// and press feedback, a pulse ring while the hint is showing, and a dimmed
/// look when filtered out (it stays tappable).
class _BuildingButton extends StatefulWidget {
  const _BuildingButton({
    required this.label,
    required this.matched,
    required this.pulse,
    required this.onTap,
  });

  final String label;
  final bool matched;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  State<_BuildingButton> createState() => _BuildingButtonState();
}

class _BuildingButtonState extends State<_BuildingButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final active = _hovered || _pressed;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: Semantics(
          button: true,
          label: widget.label,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.matched ? 1 : 0.35,
            child: Center(
              child: SizedBox.square(
                dimension: _MapCanvas._button,
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    if (widget.matched)
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: widget.pulse,
                          builder: (context, _) {
                            final t = widget.pulse.value;
                            return Opacity(
                              opacity: widget.pulse.isAnimating ? 1 - t : 0,
                              child: Transform.scale(
                                scale: 1 + 0.7 * t,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: radius,
                                    border: Border.all(color: AppColors.accent, width: 2),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 120),
                      scale: active ? 1.18 : 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: active ? AppColors.accent : AppColors.glass,
                          borderRadius: radius,
                          border: Border.all(color: AppColors.accent, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            widget.label,
                            style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.strings,
    required this.panel,
    required this.onSelect,
  });

  final AppStrings strings;
  final _MasterplanPanel? panel;
  final ValueChanged<_MasterplanPanel> onSelect;

  static const _assets = _MasterplanScreenState._assets;

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavTab(
            strings: strings,
            label: strings.filters,
            icon: '$_assets/icon_filters.svg',
            fontSize: 14,
            spacing: 0.28,
            selected: panel == _MasterplanPanel.filters,
            onTap: () => onSelect(_MasterplanPanel.filters),
          ),
          _NavTab(
            strings: strings,
            label: strings.gallery,
            icon: '$_assets/icon_gallery.svg',
            fontSize: 16,
            spacing: 0.32,
            minWidth: 106,
            selected: panel == _MasterplanPanel.gallery,
            onTap: () => onSelect(_MasterplanPanel.gallery),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.strings,
    required this.label,
    required this.icon,
    required this.fontSize,
    required this.spacing,
    required this.selected,
    required this.onTap,
    this.minWidth = 0,
  });

  final AppStrings strings;
  final String label;
  final String icon;
  final double fontSize;
  final double spacing;
  final double minWidth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(selected ? 24 : 39);
    return Material(
      color: selected ? AppColors.accent : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 48,
          constraints: BoxConstraints(minWidth: minWidth),
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(icon),
              const SizedBox(width: 8),
              Text(
                label,
                style: strings.isArabic
                    ? GoogleFonts.notoSansArabic(fontSize: fontSize, color: Colors.white, letterSpacing: spacing)
                    : GoogleFonts.rubik(fontSize: fontSize, color: Colors.white, letterSpacing: spacing, height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(102);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.glass, borderRadius: radius),
          child: child,
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.radius, required this.padding, required this.child});

  final double radius;
  final double padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    // Scale down rather than overflow on screens narrower than the panel.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(color: AppColors.glass, borderRadius: borderRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.panelCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

/// Title, range slider and the two read-out fields of a numeric filter.
class _RangeFilter extends StatelessWidget {
  const _RangeFilter({
    required this.title,
    required this.bounds,
    required this.values,
    required this.onChanged,
  });

  final Widget title;
  final RangeValues bounds;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.accent.withValues(alpha: 0.32),
            overlayColor: Colors.transparent,
            rangeThumbShape: const _HaloThumbShape(),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
          ),
          child: RangeSlider(
            min: bounds.start,
            max: bounds.end,
            values: values,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ValueField(strings: strings, value: values.start)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SvgPicture.asset('assets/images/masterplan/range_dash.svg'),
            ),
            Expanded(child: _ValueField(strings: strings, value: values.end)),
          ],
        ),
      ],
    );
  }
}

/// Figma slider handle: white 8px dot with a 4px translucent halo ring.
class _HaloThumbShape extends RangeSliderThumbShape {
  const _HaloThumbShape();

  static const _dotRadius = 4.0;
  static const _haloRadius = 8.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_haloRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, _haloRadius, Paint()..color = AppColors.sliderHalo);
    canvas.drawCircle(center, _dotRadius, Paint()..color = Colors.white);
  }
}

class _ValueField extends StatelessWidget {
  const _ValueField({required this.strings, required this.value});

  final AppStrings strings;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.panelField,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        value.round().toString(),
        style: _MasterplanScreenState._text(strings, 16, FontWeight.w400, spacing: -0.16)
            .copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _CheckOption extends StatelessWidget {
  const _CheckOption({required this.label, required this.checked, required this.onChanged});

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: checked ? AppColors.accent : AppColors.panelField,
              borderRadius: BorderRadius.circular(6),
            ),
            child: checked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: _MasterplanScreenState._text(strings, 16, FontWeight.w400, spacing: -0.16)
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.image, required this.selected, required this.onTap});

  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 289 / 291,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(image, fit: BoxFit.cover),
              if (selected)
                const IgnorePointer(child: CustomPaint(painter: _InsetGlowPainter())),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma inset shadow (0 0 16px 0 accent): a blurred accent frame that fades
/// inwards from the tile's rounded edge.
class _InsetGlowPainter extends CustomPainter {
  const _InsetGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final tile = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final frame = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(48))
      ..addRRect(tile);
    canvas
      ..save()
      ..clipRRect(tile)
      ..drawPath(
        frame,
        Paint()
          ..color = AppColors.accent
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_InsetGlowPainter old) => false;
}
