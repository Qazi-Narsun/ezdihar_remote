import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'app_canvas.dart';

/// Sizes a fixed-size glass panel (authored in Figma pixels) to the screen.
///
/// The panel is first scaled by [designScale], so it takes the same share of
/// the [AppCanvas] as in the 1920x1081 Figma frame. It is then scaled down
/// further (never up) so it takes at most [maxWidthFactor] x [maxHeightFactor]
/// of the screen and the background stays visible.
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

  /// Figma frame the panels are authored on.
  static const designSize = Size(1920, 1081);

  /// Canvas pixels per Figma pixel. Constant: the canvas is the same on
  /// every screen.
  static final double designScale = math.min(
    AppCanvas.size.width / designSize.width,
    AppCanvas.size.height / designSize.height,
  );

  @override
  Widget build(BuildContext context) {
    // Screen-relative (not parent-relative): panels sit in unbounded columns.
    final size = MediaQuery.sizeOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: size.width * maxWidthFactor,
        maxHeight: size.height * maxHeightFactor,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: _DesignScaled(scale: designScale, child: child),
      ),
    );
  }
}

/// Lays [child] out unconstrained and paints it scaled by [scale]; its own
/// size is the scaled size, so it takes that much room in the layout.
class _DesignScaled extends SingleChildRenderObjectWidget {
  const _DesignScaled({required this.scale, required super.child});

  final double scale;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderDesignScaled(scale);

  @override
  void updateRenderObject(BuildContext context, _RenderDesignScaled renderObject) {
    renderObject.scale = scale;
  }
}

class _RenderDesignScaled extends RenderProxyBox {
  _RenderDesignScaled(this._scale);

  double _scale;
  set scale(double value) {
    if (value == _scale) return;
    _scale = value;
    markNeedsLayout();
  }

  Matrix4 get _transform => Matrix4.diagonal3Values(_scale, _scale, 1);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(const BoxConstraints(), parentUsesSize: true);
    size = constraints.constrain(child.size * _scale);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(child.getDryLayout(const BoxConstraints()) * _scale);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer as TransformLayer?,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }

  @override
  double computeMinIntrinsicWidth(double height) => (child?.getMinIntrinsicWidth(double.infinity) ?? 0) * _scale;

  @override
  double computeMaxIntrinsicWidth(double height) => (child?.getMaxIntrinsicWidth(double.infinity) ?? 0) * _scale;

  @override
  double computeMinIntrinsicHeight(double width) => (child?.getMinIntrinsicHeight(double.infinity) ?? 0) * _scale;

  @override
  double computeMaxIntrinsicHeight(double width) => (child?.getMaxIntrinsicHeight(double.infinity) ?? 0) * _scale;
}
