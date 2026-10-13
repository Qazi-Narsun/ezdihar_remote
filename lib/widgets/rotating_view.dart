import 'package:flutter/material.dart';

/// Slides a slightly zoomed-in [child] sideways for each rotate step. It stands
/// in for turning the view until real 360 frames exist.
///
/// With [onStep] set, dragging the view horizontally also turns it: every
/// [dragPerStep] pixels dragged calls [onStep] with -1 (dragged right, as the
/// scene follows the finger) or +1 (dragged left).
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
  static const dragPerStep = 120.0;

  @override
  State<RotatingView> createState() => _RotatingViewState();
}

class _RotatingViewState extends State<RotatingView> {
  double _drag = 0;

  void _onDrag(DragUpdateDetails details) {
    _drag += details.delta.dx;
    while (_drag.abs() >= RotatingView.dragPerStep) {
      widget.onStep!(_drag > 0 ? -1 : 1);
      _drag -= RotatingView.dragPerStep * _drag.sign;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Slack created by the zoom, split evenly across +/- maxTurns.
        final slack = constraints.maxWidth * (RotatingView._zoom - 1) / 2;
        final dx = -slack * widget.turns / widget.maxTurns;
        final view = ClipRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: dx),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(value, 0),
              child: Transform.scale(scale: RotatingView._zoom, child: child),
            ),
            child: widget.child,
          ),
        );
        if (widget.onStep == null) return view;
        return GestureDetector(
          onHorizontalDragStart: (_) => _drag = 0,
          onHorizontalDragUpdate: _onDrag,
          child: view,
        );
      },
    );
  }
}
