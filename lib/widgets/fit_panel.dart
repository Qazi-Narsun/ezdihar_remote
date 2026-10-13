import 'package:flutter/material.dart';

/// Keeps a fixed-size glass panel from swallowing the background: the panel is
/// scaled down (never up) so it takes at most [maxWidthFactor] x
/// [maxHeightFactor] of the screen.
class FitPanel extends StatelessWidget {
  const FitPanel({
    super.key,
    required this.child,
    this.maxWidthFactor = 0.92,
    this.maxHeightFactor = 0.6,
    this.alignment = Alignment.bottomCenter,
  });

  final Widget child;
  final double maxWidthFactor;
  final double maxHeightFactor;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    // Screen-relative (not parent-relative): panels sit in unbounded columns.
    final size = MediaQuery.sizeOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: size.width * maxWidthFactor,
        maxHeight: size.height * maxHeightFactor,
      ),
      child: FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child),
    );
  }
}
