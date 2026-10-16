import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ezdihar_remote/services/player_connection.dart';
import 'package:ezdihar_remote/widgets/mirror_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the top route mirrors its state; popping back re-mirrors the screen below', (tester) async {
    final connection = PlayerConnection.instance;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [MirrorState.routeObserver],
      home: const MirrorState(state: 'masterplan', child: SizedBox()),
    ));
    expect(connection.mirroredState?['id'], 'masterplan');
    expect(connection.mirroredState?['experience'], 'ezdihar');

    connection.showModal({'kind': 'gallery', 'id': 'gallery_1'});
    navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const MirrorState(state: 'floor_details', tag: '3F', child: SizedBox()),
    ));
    await tester.pumpAndSettle();
    expect(connection.mirroredState, {'id': 'floor_details', 'experience': 'ezdihar', 'tag': '3F'});
    expect(connection.mirroredModal, isNull, reason: 'a new state closes the modal');

    // A screen without MirrorState (e.g. the register form) leaves the state alone.
    navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const SizedBox()));
    await tester.pumpAndSettle();
    expect(connection.mirroredState?['id'], 'floor_details');

    navigator.currentState!.popUntil((r) => r.isFirst);
    await tester.pumpAndSettle();
    expect(connection.mirroredState?['id'], 'masterplan');
  });

  test('sends states and modals in the player format and resyncs after a reconnect', () async {
    final received = StreamController<Map<String, dynamic>>();
    final sockets = <WebSocket>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.transform(WebSocketTransformer()).listen((socket) {
      sockets.add(socket);
      socket.listen((data) => received.add(jsonDecode(data as String) as Map<String, dynamic>));
    });
    addTearDown(() => server.close(force: true));
    final messages = StreamIterator(received.stream);
    Future<Map<String, dynamic>> next() async {
      expect(await messages.moveNext().timeout(const Duration(seconds: 5)), isTrue);
      return messages.current;
    }

    final connection = PlayerConnection.instance;
    Future<void> statusIs(PlayerStatus status) async {
      while (connection.status != status) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    connection.mirrorState('splash');
    await connection.connect(Uri.parse('ws://127.0.0.1:${server.port}/'));
    await statusIs(PlayerStatus.connected).timeout(const Duration(seconds: 5));
    // On connect: the current state, then no modal.
    expect(await next(), {'Event': 'StartState', 'Payload': {'id': 'splash', 'experience': 'ezdihar'}});
    expect(await next(), {'Event': 'HideModal', 'Payload': null});

    connection.mirrorState('splash'); // repeat: dropped
    connection.mirrorState('apartment_details', tag: '2BR');
    expect(await next(), {
      'Event': 'StartState',
      'Payload': {'id': 'apartment_details', 'experience': 'ezdihar', 'tag': '2BR'},
    });

    connection.showModal({'kind': 'brochure', 'page': 1});
    connection.showModal({'kind': 'brochure', 'page': 1}); // repeat: dropped
    connection.showModal({'kind': 'brochure', 'page': 2});
    expect(await next(), {'Event': 'ShowModal', 'Payload': {'kind': 'brochure', 'page': 1}});
    expect(await next(), {'Event': 'ShowModal', 'Payload': {'kind': 'brochure', 'page': 2}});

    await sockets.last.close();
    await statusIs(PlayerStatus.disconnected).timeout(const Duration(seconds: 5));
    await statusIs(PlayerStatus.connected).timeout(const Duration(seconds: 5));
    expect((await next())['Payload'], {'id': 'apartment_details', 'experience': 'ezdihar', 'tag': '2BR'});
    expect(await next(), {'Event': 'ShowModal', 'Payload': {'kind': 'brochure', 'page': 2}});

    connection.hideModal();
    connection.hideModal(); // already closed: dropped
    expect(await next(), {'Event': 'HideModal', 'Payload': null});
  });
}
