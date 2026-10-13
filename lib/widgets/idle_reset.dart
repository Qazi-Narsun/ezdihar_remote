import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'restart_dialog.dart';

/// Kiosk safety net: after [idleAfter] without input anywhere but the first
/// page, shows a "Still there?" countdown and then returns to the first page
/// (dropping any half-filled form for the next visitor).
///
/// Mounted once from `MaterialApp.builder`; [navigatorKey] must be the app's.
class IdleReset extends StatefulWidget {
  const IdleReset({
    super.key,
    required this.navigatorKey,
    required this.child,
    this.idleAfter = const Duration(seconds: 90),
    this.countdown = 15,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final Duration idleAfter;

  /// Seconds the warning is shown before the reset.
  final int countdown;

  @override
  State<IdleReset> createState() => _IdleResetState();
}

class _IdleResetState extends State<IdleReset> {
  Timer? _idle;
  Timer? _tick;
  int _remaining = 0;
  bool _warning = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restartIdle();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _idle?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    _activity();
    return false;
  }

  void _restartIdle() {
    _idle?.cancel();
    _idle = Timer(widget.idleAfter, _onIdle);
  }

  void _activity() {
    if (_warning) _dismissWarning();
    _restartIdle();
  }

  void _onIdle() {
    final navigator = widget.navigatorKey.currentState;
    final typing = (MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0) > 0;
    // Nothing to reset on the first page, and the soft keyboard means someone
    // is typing (it produces no pointer events).
    if (navigator == null || !navigator.canPop() || typing) {
      _restartIdle();
      return;
    }
    setState(() {
      _warning = true;
      _remaining = widget.countdown;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _reset();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _dismissWarning() {
    _tick?.cancel();
    setState(() => _warning = false);
  }

  void _reset() {
    _tick?.cancel();
    widget.navigatorKey.currentState?.popUntil((route) => route.isFirst);
    setState(() => _warning = false);
    _restartIdle();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _activity(),
      onPointerMove: (_) => _activity(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_warning)
            _Warning(remaining: _remaining, onStay: () {
              _dismissWarning();
              _restartIdle();
            }),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.remaining, required this.onStay});

  final int remaining;
  final VoidCallback onStay;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final radius = BorderRadius.circular(32);
    // Absorbs taps so the first touch only dismisses the warning.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onStay,
      child: ColoredBox(
        color: AppColors.scrim,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: Container(
                  width: 440,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.glass,
                    borderRadius: radius,
                    border: Border.all(color: AppColors.glassBorder, width: 0.8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(strings.stillThereTitle, style: appText(strings, 24, FontWeight.w500, spacing: -0.24)),
                      const SizedBox(height: 12),
                      Text(
                        strings.stillThereBody(remaining),
                        textAlign: TextAlign.center,
                        style: appText(strings, 16, FontWeight.w400, color: AppColors.textSecondary, spacing: -0.16),
                      ),
                      const SizedBox(height: 32),
                      DialogButton(label: strings.stillHere, filled: true, onTap: onStay),
                    ],
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
