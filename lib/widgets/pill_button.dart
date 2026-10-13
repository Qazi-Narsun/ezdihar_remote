import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Blurred, rounded call-to-action button.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 224,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(40);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: Colors.white),
          ),
          child: InkWell(
            onTap: onPressed == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  },
            borderRadius: radius,
            child: SizedBox(
              width: width,
              height: height,
              child: Center(
                child: Text(
                  label,
                  style: Localizations.localeOf(context).languageCode == 'ar'
                      ? GoogleFonts.notoSansArabic(fontSize: 22, color: Colors.white)
                      : GoogleFonts.rubik(fontSize: 22, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
