import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ui_feedback.dart';
import '../theme/app_colors.dart';

/// Which side of the marker the name label sits on (physical, not directional,
/// because the map is geography and must not mirror in RTL).
enum PinLabelSide { left, right }

/// A map marker (teardrop + [icon]) with a frosted name label overlapping it.
///
/// Must be a child of a [Stack]; [markerLeft]/[markerTop] place the 48-wide
/// marker body in the parent's coordinate space.
class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.markerLeft,
    required this.markerTop,
    required this.label,
    required this.labelWidth,
    required this.icon,
    required this.isArabic,
    this.labelSide = PinLabelSide.left,
  });

  static const _markerWidth = 48.0;
  static const _height = 69.0; // 55 body + 6 gap + 8 tail
  static const _overlap = 16.0;
  static const _labelCenterY = 24.0;

  final double markerLeft;
  final double markerTop;
  final String label;
  final double labelWidth;

  /// Glyph drawn inside the marker, laid out in a 24x24 box.
  final Widget icon;
  final bool isArabic;
  final PinLabelSide labelSide;

  @override
  Widget build(BuildContext context) {
    final labelOnLeft = labelSide == PinLabelSide.left;
    final width = labelWidth + _markerWidth - _overlap;
    final markerX = labelOnLeft ? labelWidth - _overlap : 0.0;
    final labelX = labelOnLeft ? 0.0 : _markerWidth - _overlap;

    return Positioned(
      left: markerLeft - markerX,
      top: markerTop,
      width: width,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: labelX,
            top: _labelCenterY,
            width: labelWidth,
            child: FractionalTranslation(
              translation: const Offset(0, -0.5),
              child: _Label(text: label, isArabic: isArabic),
            ),
          ),
          Positioned(left: markerX, top: 0, child: _Marker(icon: icon)),
        ],
      ),
    );
  }
}

/// A landmark as a square tile (Figma 401:118) with its name in a box that the
/// tile overlaps; tap it to open the landmark. The highlighted landmark is
/// drawn as a [MapPin] instead.
///
/// Must be a child of a [Stack]; [tileLeft]/[tileTop] place the 56px tile in
/// the parent's coordinate space.
class MapTile extends StatelessWidget {
  const MapTile({
    super.key,
    required this.tileLeft,
    required this.tileTop,
    required this.label,
    required this.labelWidth,
    required this.icon,
    required this.isArabic,
    required this.onTap,
    this.labelSide = PinLabelSide.left,
  });

  static const tileSize = 56.0;
  static const _height = 70.0; // 56 tile + 6 gap + 8 dot
  static const _overlap = 8.0;

  final double tileLeft;
  final double tileTop;
  final String label;
  final double labelWidth;

  /// Glyph drawn in the middle of the tile, laid out in a 24x24 box.
  final Widget icon;
  final bool isArabic;
  final VoidCallback onTap;
  final PinLabelSide labelSide;

  @override
  Widget build(BuildContext context) {
    final labelOnLeft = labelSide == PinLabelSide.left;
    final tileX = labelOnLeft ? labelWidth - _overlap : 0.0;
    final labelX = labelOnLeft ? 0.0 : tileSize - _overlap;
    final radius = BorderRadius.circular(8);
    return Positioned(
      left: tileLeft - tileX,
      top: tileTop,
      width: labelWidth + tileSize - _overlap,
      height: _height,
      child: Semantics(
        button: true,
        label: label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              UiFeedback.select();
              onTap();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: labelX,
                  top: 6,
                  width: labelWidth,
                  height: 44,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: AlignmentDirectional.centerStart,
                        decoration: BoxDecoration(
                          color: AppColors.glass,
                          borderRadius: radius,
                          border: Border.all(color: AppColors.glassBorder, width: 0.48),
                        ),
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _labelStyle(isArabic),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: tileX,
                  top: 0,
                  width: tileSize,
                  height: tileSize,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.mapTile,
                          borderRadius: radius,
                          border: Border.all(color: AppColors.glassBorder, width: 0.32),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 3,
                              top: 3,
                              width: 50,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.mapTileInner,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ),
                            Positioned(left: 16, top: 16, width: 24, height: 24, child: icon),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: tileX + 24,
                  top: 62,
                  child: SvgPicture.asset('assets/images/city/tile_dot.svg'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _labelStyle(bool isArabic) => isArabic
    ? GoogleFonts.notoSansArabic(
        fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mapLabelText, letterSpacing: 0.24, height: 1.3)
    : GoogleFonts.rubik(
        fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mapLabelText, letterSpacing: 0.24, height: 1.2);

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.isArabic});

  final String text;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(44);
    final style = _labelStyle(isArabic);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: radius,
            border: Border.all(color: AppColors.glassBorder, width: 0.48),
          ),
          child: Text(text, textAlign: TextAlign.center, style: style),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MapPin._markerWidth,
      height: 69,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset('assets/images/city/pin_union.svg'),
          Positioned(
            left: 1.95,
            top: 2,
            child: SvgPicture.asset('assets/images/city/pin_ellipse.svg'),
          ),
          Positioned(left: 11.95, top: 12, width: 24, height: 24, child: icon),
          Positioned(
            left: 20,
            top: 61,
            child: SvgPicture.asset('assets/images/city/pin_tail_down.svg'),
          ),
        ],
      ),
    );
  }
}
