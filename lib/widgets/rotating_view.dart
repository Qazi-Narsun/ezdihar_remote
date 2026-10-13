import 'package:flutter/material.dart';

/// Slides a slightly zoomed-in [child] sideways for each rotate step. It stands
/// in for turning the view until real 360 frames exist.
class RotatingView extends StatelessWidget {
  const RotatingView({
    super.key,
    required this.turns,
    required this.maxTurns,
    required this.child,
  });

  final int turns;
  final int maxTurns;
  final Widget child;

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
            child: child,
          ),
        );
      },
    );
  }
}
