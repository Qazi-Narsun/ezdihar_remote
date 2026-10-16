import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum PlayerStatus { disconnected, connecting, connected }

/// A message from the player: `{"Event": ..., "Payload": ...}`.
class PlayerMessage {
  const PlayerMessage(this.event, this.payload);

  final String event;
  final Object? payload;
}

/// Link to the NarsunPlayer (Ezdihar build) driving the main screen.
///
/// The player shows a QR code holding its WebSocket URL (`ws://<ip>:3737/`) while no remote is
/// connected; scanning it calls [connect]. The URL is saved, so the app reconnects on its own after
/// a restart or a dropped link (the player accepts one remote at a time and refuses others).
class PlayerConnection extends ChangeNotifier {
  PlayerConnection._(this._prefs, this._url);

  static const _key = 'player_url';
  static const _connectTimeout = Duration(seconds: 5);
  static const _maxRetryDelay = Duration(seconds: 30);

  /// App-wide link. Replaced by [load] before `runApp`; tests get an idle one.
  static PlayerConnection instance = PlayerConnection._(null, null);

  final SharedPreferences? _prefs;
  Uri? _url;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retry;
  int _attempt = 0;
  PlayerStatus _status = PlayerStatus.disconnected;
  final _messages = StreamController<PlayerMessage>.broadcast();

  PlayerStatus get status => _status;

  /// The paired player, or null before the first scan.
  Uri? get url => _url;

  Stream<PlayerMessage> get messages => _messages.stream;

  /// Reads the paired player and starts connecting to it; call once before `runApp`.
  static Future<PlayerConnection> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = parsePairingCode(prefs.getString(_key) ?? '');
    instance = PlayerConnection._(prefs, saved);
    if (saved != null) unawaited(instance._open());
    return instance;
  }

  /// The player URL in a scanned QR code, or null when it is not a player code.
  static Uri? parsePairingCode(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'ws' || uri.host.isEmpty || !uri.hasPort) return null;
    return uri;
  }

  /// Pairs with the player at [url] (from its QR code) and connects.
  Future<void> connect(Uri url) async {
    _url = url;
    await _prefs?.setString(_key, url.toString());
    _attempt = 0;
    await _open();
  }

  /// The player experience whose states mirror this app's screens.
  static const experience = 'ezdihar';

  Map<String, Object?>? _state;
  Map<String, Object?>? _modal;

  /// The last mirrored `StartState` payload and the open modal (null when none).
  Map<String, Object?>? get mirroredState => _state;
  Map<String, Object?>? get mirroredModal => _modal;

  /// Shows [id] (with an optional [tag], e.g. a floor code) on the main screen. Repeats are
  /// dropped; a new state also closes any modal, since modals belong to the screen they opened on.
  /// Re-sent after every reconnect.
  void mirrorState(String id, {String? tag}) {
    final state = {'id': id, 'experience': experience, 'tag': ?tag};
    if (_state != null && jsonEncode(_state) == jsonEncode(state)) return;
    if (_state?['id'] != id) hideModal();
    _state = state;
    send('StartState', state);
  }

  /// Opens (or updates) the main screen's modal: `{'kind': 'gallery', 'id': ...}` or
  /// `{'kind': 'brochure', 'page': n}`.
  void showModal(Map<String, Object?> modal) {
    if (_modal != null && jsonEncode(_modal) == jsonEncode(modal)) return;
    _modal = modal;
    send('ShowModal', modal);
  }

  /// Closes the main screen's modal, if one is open.
  void hideModal() {
    if (_modal == null) return;
    _modal = null;
    send('HideModal');
  }

  /// Brings a (re)connected player to this app's current state and modal.
  void _resync() {
    if (_state != null) send('StartState', _state);
    _modal == null ? send('HideModal') : send('ShowModal', _modal);
  }

  /// Sends an event in the player's format; dropped while not connected.
  void send(String event, [Object? payload]) {
    if (_status != PlayerStatus.connected) return;
    _channel?.sink.add(jsonEncode({'Event': event, 'Payload': payload}));
  }

  Future<void> _open() async {
    final url = _url;
    if (url == null) return;
    _retry?.cancel();
    await _close();
    _setStatus(PlayerStatus.connecting);

    final channel = WebSocketChannel.connect(url);
    _channel = channel;
    try {
      await channel.ready.timeout(_connectTimeout);
    } catch (_) {
      if (_channel != channel) return; // superseded by a newer connect()
      _channel = null;
      unawaited(channel.sink.close().catchError((_) {}));
      _scheduleRetry();
      return;
    }
    if (_channel != channel) return;

    _attempt = 0;
    _subscription = channel.stream.listen(
      _onData,
      onError: (_) => _onLost(channel),
      onDone: () => _onLost(channel),
      cancelOnError: true,
    );
    _setStatus(PlayerStatus.connected);
    _resync();
  }

  void _onData(dynamic data) {
    if (data is! String) return;
    try {
      final json = jsonDecode(data);
      if (json is Map && json['Event'] is String) {
        _messages.add(PlayerMessage(json['Event'] as String, json['Payload']));
      }
    } on FormatException {
      // Not a player message; ignore.
    }
  }

  void _onLost(WebSocketChannel channel) {
    if (_channel != channel) return;
    _channel = null;
    _subscription = null;
    _scheduleRetry();
  }

  /// Retries with a growing delay (1, 2, 4 ... 30 s) until the player is back.
  void _scheduleRetry() {
    _setStatus(PlayerStatus.disconnected);
    if (_url == null) return;
    final seconds = 1 << _attempt.clamp(0, 5);
    _attempt++;
    final delay = Duration(seconds: seconds) > _maxRetryDelay ? _maxRetryDelay : Duration(seconds: seconds);
    _retry?.cancel();
    _retry = Timer(delay, _open);
  }

  Future<void> _close() async {
    final channel = _channel;
    _channel = null;
    await _subscription?.cancel();
    _subscription = null;
    if (channel != null) unawaited(channel.sink.close().catchError((_) {}));
  }

  void _setStatus(PlayerStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _retry?.cancel();
    _close();
    _messages.close();
    super.dispose();
  }
}
