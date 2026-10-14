import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/ui_feedback.dart';
import '../theme/app_colors.dart';

/// Round frosted-glass button holding a single icon (e.g. the back button).
class GlassIconButton extends StatefulWidget {
  const GlassIconButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.size = 56,
    this.tooltip,
    this.padding,
    this.repeatEvery,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;

  /// When set, the button is [size] tall and as wide as [child] plus this
  /// horizontal padding (a pill, e.g. icon + label) instead of a square.
  final EdgeInsetsGeometry? padding;

  /// When set, holding the button calls [onPressed] repeatedly at this rate
  /// (hold-to-spin for the rotate buttons).
  final Duration? repeatEvery;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  Timer? _hold;

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  void _tap() {
    // Hold-to-spin buttons (rotate) are silent here: their callback gives the
    // per-step cue, so a held button ticks once per step.
    if (widget.repeatEvery == null) UiFeedback.tap();
    widget.onPressed?.call();
  }

  void _startHold() {
    _hold?.cancel();
    _hold = Timer.periodic(widget.repeatEvery!, (_) => widget.onPressed?.call());
  }

  void _stopHold() {
    _hold?.cancel();
    _hold = null;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    final padding = widget.padding;
    return Tooltip(
      message: widget.tooltip ?? '',
      child: Listener(
        onPointerUp: (_) => _stopHold(),
        onPointerCancel: (_) => _stopHold(),
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
                onTap: widget.onPressed == null ? null : _tap,
                onLongPress: widget.repeatEvery == null ? null : _startHold,
                borderRadius: radius,
                child: padding == null
                    ? SizedBox(width: widget.size, height: widget.size, child: Center(child: widget.child))
                    : SizedBox(
                        height: widget.size,
                        child: Padding(
                          padding: padding,
                          child: Center(widthFactor: 1, child: widget.child),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
