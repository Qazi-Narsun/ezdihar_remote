import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ezdihar_remote/services/player_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts only the player QR code (ws://host:port/)', () {
    expect(PlayerConnection.parsePairingCode('ws://192.168.1.20:3737/'), Uri.parse('ws://192.168.1.20:3737/'));
    expect(PlayerConnection.parsePairingCode(' ws://10.0.0.5:3737/ '), isNotNull);
    expect(PlayerConnection.parsePairingCode('192.168.1.20'), isNull);
    expect(PlayerConnection.parsePairingCode('ws://192.168.1.20/'), isNull);
    expect(PlayerConnection.parsePairingCode('https://example.com:443/'), isNull);
    expect(PlayerConnection.parsePairingCode(''), isNull);
  });

  test('connects, sends in the player format and reconnects after a drop', () async {
    final received = StreamController<String>();
    final sockets = <WebSocket>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.transform(WebSocketTransformer()).listen((socket) {
      sockets.add(socket);
      socket.listen((data) => received.add(data as String));
    });
    addTearDown(() => server.close(force: true));

    final connection = PlayerConnection.instance;
    Future<void> statusIs(PlayerStatus status) async {
      while (connection.status != status) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    await connection.connect(Uri.parse('ws://127.0.0.1:${server.port}/'));
    await statusIs(PlayerStatus.connected).timeout(const Duration(seconds: 5));

    final messages = received.stream.asBroadcastStream();
    connection.send('StartState', {'id': 'intro'});
    expect(jsonDecode(await messages.first), {'Event': 'StartState', 'Payload': {'id': 'intro'}});

    final fromPlayer = connection.messages.first;
    sockets.last.add(jsonEncode({'Event': 'StateStarted', 'Payload': {'CurrentState': 'intro'}}));
    final message = await fromPlayer.timeout(const Duration(seconds: 5));
    expect(message.event, 'StateStarted');

    await sockets.last.close();
    await statusIs(PlayerStatus.disconnected).timeout(const Duration(seconds: 5));
    await statusIs(PlayerStatus.connected).timeout(const Duration(seconds: 5));
    expect(sockets, hasLength(2));
  });
}
