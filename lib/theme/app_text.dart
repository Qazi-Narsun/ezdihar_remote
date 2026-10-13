import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';

/// Locale-aware text style: Noto Sans Arabic for Arabic, Rubik for English.
TextStyle appText(
  AppStrings strings,
  double size,
  FontWeight weight, {
  Color color = Colors.white,
  double spacing = 0,
}) =>
    strings.isArabic
        ? GoogleFonts.notoSansArabic(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing)
        : GoogleFonts.rubik(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);
