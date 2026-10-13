import 'package:flutter/material.dart';

/// Slides pages in from the reading-direction end: from the right in LTR and
/// from the left in RTL. The page underneath drifts the opposite way.
class DirectionalPageTransitionsBuilder extends PageTransitionsBuilder {
  const DirectionalPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final dx = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final enter = Tween(begin: Offset(dx, 0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    final exit = Tween(begin: Offset.zero, end: Offset(-dx * 0.25, 0))
        .chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(
      position: secondaryAnimation.drive(exit),
      child: SlideTransition(position: animation.drive(enter), child: child),
    );
  }
}
