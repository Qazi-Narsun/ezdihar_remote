import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/building_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/language_toggle.dart';
import '../widgets/rotating_view.dart';
import 'building_detail_screen.dart';

/// Which panel the bottom navigation currently has open above the map.
enum _MasterplanPanel { filters, gallery }

/// Aerial masterplan view with a bottom navigation (rotate left / Filters |
/// Gallery / rotate right) and a reset-view button.
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
    BuildingType.loadAll().then((types) {
      if (mounted) setState(() => _types = types);
    });
  }

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
      spots.add(_BuildingSpot(_laneCentres[i], type, queues[letter]!.ids.current));
    }
    return spots;
  }

  void _openBuilding(BuildingType type, String id) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BuildingDetailScreen(
            type: type,
            buildingId: id,
            onLocaleChanged: widget.onLocaleChanged,
          ),
        ),
      );

  void _togglePanel(_MasterplanPanel panel) =>
      setState(() => _panel = _panel == panel ? null : panel);

  void _rotate(int delta) =>
      setState(() => _turns = (_turns + delta).clamp(-_maxTurns, _maxTurns));

  /// Restart: clear the stack and return to the first page.
  void _reset() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isArabic = strings.isArabic;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          RotatingView(
            turns: _turns,
            maxTurns: _maxTurns,
            child: _MapCanvas(buildings: _spots(), onSelect: _openBuilding),
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
                          _MasterplanPanel.filters => _buildFilters(strings),
                          _MasterplanPanel.gallery => _buildGallery(strings),
                          null => const SizedBox(width: 0, height: 0),
                        },
                      ),
                      if (_panel != null) const SizedBox(height: 24),
                      _BottomNav(
                        strings: strings,
                        panel: _panel,
                        onRotate: _rotate,
                        onSelect: _togglePanel,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: GlassIconButton(
                    tooltip: strings.resetView,
                    onPressed: _reset,
                    child: SvgPicture.asset('$_assets/icon_reset.svg'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                _CloseButton(
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
                          Text(strings.surface, style: _label(strings)),
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
                _CloseButton(
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
      _text(strings, 16, FontWeight.w600, color: Colors.white.withValues(alpha: 0.64), spacing: -0.16);
}

/// The aerial photo with one box button per building of the upper lane. Laid
/// out on the photo's own pixel grid so the buttons stay on their buildings.
class _MapCanvas extends StatelessWidget {
  const _MapCanvas({required this.buildings, required this.onSelect});

  final List<_BuildingSpot> buildings;
  final void Function(BuildingType type, String id) onSelect;

  static const _size = Size(2000, 1147);
  static const _button = 44.0;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox.fromSize(
        size: _size,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/masterplan/background.png', fit: BoxFit.cover),
            ),
            for (final b in buildings)
              Positioned(
                left: b.center.dx - _button / 2,
                top: b.center.dy - _button / 2,
                width: _button,
                height: _button,
                child: _BuildingButton(label: b.id, onTap: () => onSelect(b.type, b.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuildingSpot {
  const _BuildingSpot(this.center, this.type, this.id);

  final Offset center;
  final BuildingType type;
  final String id;
}

class _BuildingButton extends StatelessWidget {
  const _BuildingButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Material(
      color: AppColors.glass,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.accent, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
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
    required this.onRotate,
    required this.onSelect,
  });

  final AppStrings strings;
  final _MasterplanPanel? panel;
  final ValueChanged<int> onRotate;
  final ValueChanged<_MasterplanPanel> onSelect;

  static const _assets = _MasterplanScreenState._assets;

  @override
  Widget build(BuildContext context) {
    // Physical left/right: the rotate direction must not mirror in RTL.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassIconButton(
            size: 40,
            tooltip: strings.rotateLeft,
            onPressed: () => onRotate(-1),
            child: SvgPicture.asset('$_assets/icon_rotate.svg'),
          ),
          const SizedBox(width: 8),
          _GlassPill(
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
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            size: 40,
            tooltip: strings.rotateRight,
            onPressed: () => onRotate(1),
            // Figma uses the same glyph mirrored for the opposite direction.
            child: Transform.flip(
              flipX: true,
              child: SvgPicture.asset('$_assets/icon_rotate.svg'),
            ),
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

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      icon: SvgPicture.asset('assets/images/masterplan/icon_close.svg', width: 32, height: 32),
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
            .copyWith(color: Colors.white.withValues(alpha: 0.64)),
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
                .copyWith(color: Colors.white.withValues(alpha: 0.64)),
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
