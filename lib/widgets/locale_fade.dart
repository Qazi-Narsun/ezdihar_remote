import 'package:flutter/material.dart';

/// Softens the abrupt RTL/LTR flip on a language change: the content swaps
/// immediately (state is kept) and fades back in.
class LocaleFade extends StatefulWidget {
  const LocaleFade({super.key, required this.locale, required this.child});

  final Locale locale;
  final Widget child;

  @override
  State<LocaleFade> createState() => _LocaleFadeState();
}

class _LocaleFadeState extends State<LocaleFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  late final Animation<double> _opacity = Tween<double>(begin: 0.15, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
  );

  @override
  void didUpdateWidget(LocaleFade old) {
    super.didUpdateWidget(old);
    if (old.locale != widget.locale) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}
