import 'package:flutter/material.dart';

/// Full-bleed cover image with a dark tint and an optional overlay image on top.
class OverlayBackground extends StatelessWidget {
  const OverlayBackground({
    super.key,
    required this.image,
    this.overlayImage,
    this.overlayColor = const Color(0xA3000000), // black @ 64%
    this.child,
  });

  final String image;
  final String? overlayImage;
  final Color overlayColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(image, fit: BoxFit.cover),
        ColoredBox(color: overlayColor),
        if (overlayImage case final overlay?)
          Image.asset(overlay, fit: BoxFit.cover),
        ?child,
      ],
    );
  }
}
