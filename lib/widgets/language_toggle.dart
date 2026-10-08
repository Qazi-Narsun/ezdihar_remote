import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

enum AppLanguage { english, arabic }

/// Two-segment pill used to switch between English and Arabic.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, required this.selected, required this.onChanged});

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(122);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.25, sigmaY: 5.25),
        child: Container(
          height: 56,
          padding: const EdgeInsetsDirectional.only(end: 4, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: const Color(0x8F2D1C10),
            borderRadius: radius,
            border: Border.all(color: const Color(0x3DFFFFFF), width: 0.48),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Segment(
                radius: 65.26,
                selected: selected == AppLanguage.english,
                onTap: () => onChanged(AppLanguage.english),
                child: Text(
                  'English',
                  style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.24, height: 1),
                ),
              ),
              _Segment(
                radius: 118,
                selected: selected == AppLanguage.arabic,
                onTap: () => onChanged(AppLanguage.arabic),
                child: Text(
                  'العربية',
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.notoSansArabic(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.radius, required this.selected, required this.onTap, required this.child});

  final double radius;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return Material(
      color: selected ? AppColors.accent : Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(constraints: const BoxConstraints(minHeight: 34), alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 12), child: child),
      ),
    );
  }
}
