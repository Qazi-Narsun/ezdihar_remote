import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Letter-spaced brand name followed by the hero tagline.
class BrandTitle extends StatelessWidget {
  const BrandTitle({
    super.key,
    this.name = 'MASHAEL AL FURSAN',
    this.tagline = 'Discover a New Way of Living',
    this.isArabic = false,
  });

  final String name;
  final String tagline;

  /// Arabic uses an Arabic-capable font and no letter spacing (it breaks joining).
  final bool isArabic;

  static const _color = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: isArabic
              ? GoogleFonts.notoSansArabic(fontSize: 18, fontWeight: FontWeight.w600, color: _color)
              : GoogleFonts.baskervville(fontSize: 18, fontWeight: FontWeight.w400, color: _color, letterSpacing: 6.84),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 417,
          child: Text(
            tagline.toUpperCase(),
            textAlign: TextAlign.center,
            style: isArabic
                ? GoogleFonts.notoNaskhArabic(fontSize: 48, height: 56 / 48, color: _color)
                : GoogleFonts.marcellus(fontSize: 48, height: 56 / 48, color: _color),
          ),
        ),
      ],
    );
  }
}
