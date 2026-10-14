import 'package:flutter/material.dart';

/// Slides a slightly zoomed-in [child] sideways for each rotate step. It stands
/// in for turning the view until real 360 frames exist.
///
/// With [onStep] set, dragging the view horizontally pans it with the finger
/// (1:1, clamped to the zoom slack); on release it settles on the nearest step
/// and reports the steps moved through [onStep] (negative when dragged right,
/// as the scene follows the finger).
class RotatingView extends StatefulWidget {
  const RotatingView({
    super.key,
    required this.turns,
    required this.maxTurns,
    required this.child,
    this.onStep,
  });

  final int turns;
  final int maxTurns;
  final Widget child;
  final ValueChanged<int>? onStep;

  static const _zoom = 1.2;

  @override
  State<RotatingView> createState() => _RotatingViewState();
}

class _RotatingViewState extends State<RotatingView> {
  /// Finger offset of the drag in progress (null when not dragging).
  double? _drag;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Slack created by the zoom, split evenly across +/- maxTurns.
        final slack = constraints.maxWidth * (RotatingView._zoom - 1) / 2;
        final base = -slack * widget.turns / widget.maxTurns;
        final dragging = _drag != null;
        final dx = (base + (_drag ?? 0)).clamp(-slack, slack);
        final view = ClipRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: dx),
            duration: dragging ? Duration.zero : const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(value, 0),
              child: Transform.scale(scale: RotatingView._zoom, child: child),
            ),
            child: widget.child,
          ),
        );
        if (widget.onStep == null) return view;
        final perStep = slack / widget.maxTurns;
        return GestureDetector(
          onHorizontalDragStart: (_) => setState(() => _drag = 0),
          onHorizontalDragUpdate: (d) => setState(() => _drag = (_drag ?? 0) + d.delta.dx),
          onHorizontalDragEnd: (d) => _settle(
            (base + (_drag ?? 0)).clamp(-slack, slack),
            base,
            perStep,
            d.primaryVelocity ?? 0,
          ),
          onHorizontalDragCancel: () => setState(() => _drag = null),
          child: view,
        );
      },
    );
  }

  /// Snaps to the nearest step (a fling carries one step further).
  void _settle(double dx, double base, double perStep, double velocity) {
    var steps = perStep == 0 ? 0 : ((base - dx) / perStep).round();
    if (velocity.abs() > 600 && steps == 0) steps = velocity > 0 ? -1 : 1;
    final turns = (widget.turns + steps).clamp(-widget.maxTurns, widget.maxTurns);
    setState(() => _drag = null);
    final delta = turns - widget.turns;
    if (delta != 0) widget.onStep!(delta);
  }
}
