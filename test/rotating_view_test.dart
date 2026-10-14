import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezdihar_remote/widgets/rotating_view.dart';

void main() {
  late List<int> steps;
  late int taps;
  final key = GlobalKey<RotatingViewState>();

  Future<void> pumpView(WidgetTester tester) async {
    steps = [];
    taps = 0;
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: RotatingView(
        key: key,
        turns: 0,
        maxTurns: 3,
        onStep: steps.add,
        child: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Colors.green)),
          Positioned(
            left: 480,
            top: 280,
            width: 40,
            height: 40,
            child: GestureDetector(
              key: const ValueKey('button'),
              onTap: () => taps++,
              child: const ColoredBox(color: Colors.red),
            ),
          ),
        ]),
      ),
    ));
  }

  Future<void> doubleTapAt(WidgetTester tester, Offset at) async {
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(at);
    await tester.pumpAndSettle();
  }

  testWidgets('double-tap toggles 2x zoom', (tester) async {
    await pumpView(tester);
    await doubleTapAt(tester, const Offset(200, 150));
    expect(key.currentState!.isZoomed, isTrue);
    await doubleTapAt(tester, const Offset(200, 150));
    expect(key.currentState!.isZoomed, isFalse);
  });

  testWidgets('pinch zooms and the button stays tappable', (tester) async {
    await pumpView(tester);
    final a = await tester.startGesture(const Offset(450, 300));
    final b = await tester.startGesture(const Offset(550, 300), pointer: 2);
    await tester.pump();
    for (var i = 1; i <= 10; i++) {
      await a.moveTo(Offset(450 - i * 10.0, 300));
      await b.moveTo(Offset(550 + i * 10.0, 300));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(key.currentState!.isZoomed, isTrue);

    await tester.tap(find.byKey(const ValueKey('button')));
    expect(taps, 1);

    // A one-finger drag while zoomed pans and does not rotate.
    await tester.dragFrom(const Offset(300, 300), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(steps, isEmpty);

    key.currentState!.resetZoom();
    await tester.pumpAndSettle();
    expect(key.currentState!.isZoomed, isFalse);
  });

  testWidgets('a drag at 1x still rotates', (tester) async {
    await pumpView(tester);
    await tester.dragFrom(const Offset(500, 300), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(steps, isNotEmpty);
    expect(key.currentState!.isZoomed, isFalse);
  });
}
