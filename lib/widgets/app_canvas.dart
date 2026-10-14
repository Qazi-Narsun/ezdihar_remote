import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lays the whole app out on one fixed logical canvas ([size], 16:10) and
/// scales it uniformly to the screen, so every 16:10 screen shows the same
/// layout whatever its resolution or pixel density. Other aspect ratios are
/// letterboxed (never reflowed).
///
/// The canvas is 1920 wide like the Figma frames, so sizes in code are Figma
/// pixels and take the same share of the screen as in Figma.
///
/// Mounted once from `MaterialApp.builder`, around the navigator, so routes,
/// dialogs and overlays all live on the canvas.
class AppCanvas extends StatelessWidget {
  const AppCanvas({super.key, required this.child});

  final Widget child;

  /// Logical size every screen is laid out on.
  static const size = Size(1920, 1200);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = math.min(media.size.width / size.width, media.size.height / size.height);
    if (!scale.isFinite || scale <= 0) return const SizedBox.shrink();
    return ColoredBox(
      color: AppColors.letterbox,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: size,
          child: MediaQuery(
            data: media.copyWith(
              size: size,
              // Images still pick the asset variant for the real pixel density.
              devicePixelRatio: media.devicePixelRatio * scale,
              padding: media.padding / scale,
              viewPadding: media.viewPadding / scale,
              viewInsets: media.viewInsets / scale,
              systemGestureInsets: media.systemGestureInsets / scale,
              // The system font size must not reflow the fixed layout.
              textScaler: TextScaler.noScaling,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
