import 'package:flutter/widgets.dart';

import '../services/player_connection.dart';

/// Shows [state] on the main screen (NarsunPlayer) while this widget's route is the top route:
/// when the route is pushed, when the route above it is popped, and whenever [state]/[tag]
/// change. Wrap a screen (or compute [state] from its panels) to mirror it; screens without one
/// (register form, thank-you) leave the main screen on the previous state.
class MirrorState extends StatefulWidget {
  const MirrorState({super.key, required this.state, this.tag, required this.child});

  /// A state id of the player's `ezdihar` experience, e.g. `masterplan`.
  final String state;
  final String? tag;
  final Widget child;

  /// Mounted on the app's `MaterialApp.navigatorObservers` so popping back re-mirrors a screen.
  static final routeObserver = RouteObserver<ModalRoute<Object?>>();

  @override
  State<MirrorState> createState() => _MirrorStateState();
}

class _MirrorStateState extends State<MirrorState> with RouteAware {
  ModalRoute<Object?>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route != null) MirrorState.routeObserver.unsubscribe(this);
      _route = route;
      // Subscribing calls didPush.
      if (route != null) MirrorState.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(MirrorState old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state || old.tag != widget.tag) _mirror();
  }

  @override
  void dispose() {
    MirrorState.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => _mirror();

  @override
  void didPopNext() => _mirror();

  void _mirror() {
    if (_route?.isCurrent ?? true) {
      PlayerConnection.instance.mirrorState(widget.state, tag: widget.tag);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
