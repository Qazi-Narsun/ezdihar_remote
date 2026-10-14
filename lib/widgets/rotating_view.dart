import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Slides a slightly zoomed-in [child] sideways for each rotate step. It stands
/// in for turning the view until real 360 frames exist.
///
/// With [onStep] set, the view also takes gestures:
/// - At 1x, dragging horizontally pans it with the finger (1:1, clamped to the
///   rotation slack); on release it settles on the nearest step and reports
///   the steps moved through [onStep] (negative when dragged right, as the
///   scene follows the finger).
/// - Pinch zooms from 1x to [maxZoom] around the fingers; while zoomed in, one
///   finger pans freely within the view.
/// - Double-tap zooms to [doubleTapZoom] at that point, or back out to 1x.
///
/// The zoom transforms [child] as a whole, so anything placed on it (building
/// buttons) stays in place and tappable. [RotatingViewState.resetZoom] returns
/// to 1x (the screen calls it on rotate buttons and when leaving).
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
  static const maxZoom = 3.0;
  static const doubleTapZoom = 2.0;

  @override
  State<RotatingView> createState() => RotatingViewState();
}

class RotatingViewState extends State<RotatingView> {
  static const _animation = Duration(milliseconds: 300);

  /// Finger offset of the rotation drag in progress (null when not dragging).
  double? _drag;

  /// User zoom on top of the rotation view, and its top-left offset.
  double _scale = 1;
  Offset _offset = Offset.zero;

  /// True while a pinch/pan follows the fingers (no easing).
  bool _zooming = false;
  double _gestureStartScale = 1;
  Offset _lastFocal = Offset.zero;

  Size _size = Size.zero;

  // Double-tap detection on raw pointers, so building taps are not delayed.
  final Map<int, (Offset, Duration)> _downs = {};
  (Offset, Duration)? _lastTap;

  bool get isZoomed => _scale > 1;

  /// Back to 1x, animated.
  void resetZoom() {
    if (!isZoomed && _offset == Offset.zero) return;
    setState(() {
      _zooming = false;
      _scale = 1;
      _offset = Offset.zero;
    });
  }

  /// Keeps the zoomed view covering the whole viewport.
  Offset _clamp(Offset o, double scale) => Offset(
        o.dx.clamp(_size.width * (1 - scale), 0),
        o.dy.clamp(_size.height * (1 - scale), 0),
      );

  /// Zooms to [scale] keeping the content under [focal] (view coords) still.
  void _zoomAround(Offset focal, double scale, {Offset pan = Offset.zero}) {
    final content = (focal - _offset) / _scale;
    _scale = scale;
    _offset = _clamp(focal + pan - content * scale, scale);
    if (_scale <= 1.001) {
      _scale = 1;
      _offset = Offset.zero;
    }
  }

  void _onScaleStart(ScaleStartDetails d) {
    if (d.pointerCount < 2 && !isZoomed) {
      setState(() => _drag = 0);
      return;
    }
    _gestureStartScale = _scale;
    _lastFocal = d.localFocalPoint;
    setState(() => _zooming = true);
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_drag != null) {
      setState(() => _drag = _drag! + d.focalPointDelta.dx);
      return;
    }
    if (!_zooming) return;
    final scale = (_gestureStartScale * d.scale).clamp(1.0, RotatingView.maxZoom);
    setState(() {
      _zoomAround(_lastFocal, scale, pan: d.localFocalPoint - _lastFocal);
      _lastFocal = d.localFocalPoint;
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_drag != null) {
      _settle(d.velocity.pixelsPerSecond.dx);
    } else if (_zooming) {
      setState(() => _zooming = false);
    }
  }

  void _onPointerDown(PointerDownEvent e) =>
      _downs[e.pointer] = (e.localPosition, e.timeStamp);

  void _onPointerUp(PointerUpEvent e) {
    final down = _downs.remove(e.pointer);
    if (down == null || _downs.isNotEmpty) return;
    final (position, time) = down;
    final isTap = (e.localPosition - position).distance < kTouchSlop &&
        e.timeStamp - time < kLongPressTimeout;
    if (!isTap) {
      _lastTap = null;
      return;
    }
    final last = _lastTap;
    if (last != null &&
        e.timeStamp - last.$2 < kDoubleTapTimeout &&
        (position - last.$1).distance < kDoubleTapSlop &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      _lastTap = null;
      _onDoubleTap(position);
    } else {
      _lastTap = (position, e.timeStamp);
    }
  }

  void _onDoubleTap(Offset position) {
    if (isZoomed) {
      resetZoom();
      return;
    }
    setState(() {
      _zooming = false;
      _drag = null;
      _zoomAround(position, RotatingView.doubleTapZoom);
    });
  }

  double get _slack => _size.width * (RotatingView._zoom - 1) / 2;

  double get _base => -_slack * widget.turns / widget.maxTurns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final slack = _slack;
        final dragging = _drag != null;
        final dx = (_base + (_drag ?? 0)).clamp(-slack, slack);
        final zoom = Matrix4.translationValues(_offset.dx, _offset.dy, 0)
          ..scaleByDouble(_scale, _scale, 1, 1);
        final view = ClipRect(
          child: TweenAnimationBuilder<Matrix4>(
            tween: Matrix4Tween(end: zoom),
            duration: _zooming ? Duration.zero : _animation,
            curve: Curves.easeOut,
            builder: (context, value, child) => Transform(transform: value, child: child),
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
          ),
        );
        if (widget.onStep == null) return view;
        return Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: (e) => _downs.remove(e.pointer),
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: view,
          ),
        );
      },
    );
  }

  /// Snaps the rotation drag to the nearest step (a fling carries one step
  /// further).
  void _settle(double velocity) {
    final slack = _slack;
    final base = _base;
    final dx = (base + (_drag ?? 0)).clamp(-slack, slack);
    final perStep = slack / widget.maxTurns;
    var steps = perStep == 0 ? 0 : ((base - dx) / perStep).round();
    if (velocity.abs() > 600 && steps == 0) steps = velocity > 0 ? -1 : 1;
    final turns = (widget.turns + steps).clamp(-widget.maxTurns, widget.maxTurns);
    setState(() => _drag = null);
    final delta = turns - widget.turns;
    if (delta != 0) widget.onStep!(delta);
  }
}
