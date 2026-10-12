import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Round frosted-glass button holding a single icon (e.g. the back button).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.size = 56,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    return Tooltip(
      message: tooltip ?? '',
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: AppColors.glass,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: const BorderSide(color: AppColors.glassBorder, width: 0.48),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              child: SizedBox(width: size, height: size, child: Center(child: child)),
            ),
          ),
        ),
      ),
    );
  }
}
