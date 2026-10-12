import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/language_toggle.dart';

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

  void _togglePanel(_MasterplanPanel panel) =>
      setState(() => _panel = _panel == panel ? null : panel);

  void _rotate(int delta) =>
      setState(() => _turns = (_turns + delta).clamp(-_maxTurns, _maxTurns));

  void _reset() => setState(() {
        _turns = 0;
        _panel = null;
      });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isArabic = strings.isArabic;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _RotatingMap(turns: _turns, maxTurns: _maxTurns),
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

/// Full-bleed aerial image. Each rotate step slides a slightly zoomed-in copy
/// sideways, which stands in for turning the view until real 360 frames exist.
class _RotatingMap extends StatelessWidget {
  const _RotatingMap({required this.turns, required this.maxTurns});

  final int turns;
  final int maxTurns;

  static const _zoom = 1.2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Slack created by the zoom, split evenly across +/- maxTurns.
        final slack = constraints.maxWidth * (_zoom - 1) / 2;
        final dx = -slack * turns / maxTurns;
        return ClipRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: dx),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(value, 0),
              child: Transform.scale(scale: _zoom, child: child),
            ),
            child: Image.asset(
              'assets/images/masterplan/background.png',
              fit: BoxFit.cover,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          ),
        );
      },
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
