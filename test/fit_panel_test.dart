import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezdihar_remote/widgets/app_canvas.dart';
import 'package:ezdihar_remote/widgets/fit_panel.dart';

void main() {
  /// The panel's rect as a fraction of the screen.
  Future<Rect> panelRect(WidgetTester tester, Size physical, double ratio) async {
    tester.view.devicePixelRatio = ratio;
    tester.view.physicalSize = physical;
    addTearDown(tester.view.reset);
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppCanvas(child: child!),
        home: Align(
          alignment: Alignment.bottomCenter,
          child: FitPanel(
            child: GestureDetector(
              onTap: () => tapped = true,
              child: Container(key: const Key('panel'), width: 600, height: 400, color: Colors.red),
            ),
          ),
        ),
      ),
    );
    // Taps land on the scaled panel.
    await tester.tap(find.byKey(const Key('panel')));
    expect(tapped, isTrue);
    final r = tester.getRect(find.byType(FitPanel));
    final screen = physical / ratio;
    return Rect.fromLTRB(
      r.left / screen.width,
      r.top / screen.height,
      r.right / screen.width,
      r.bottom / screen.height,
    );
  }

  testWidgets('takes the same share of the screen as in the Figma frame', (tester) async {
    final r = await panelRect(tester, const Size(1920, 1200), 1.5);
    expect(r.width, closeTo(600 / 1920, 1e-6));
    expect(r.height, closeTo(400 / 1200, 1e-6));
  });

  testWidgets('is the same on every 16:10 screen', (tester) async {
    final reference = await panelRect(tester, const Size(1920, 1200), 1.5);
    for (final (physical, ratio) in [
      (const Size(1280, 800), 1.0),
      (const Size(1920, 1200), 1.0),
      (const Size(1920, 1200), 2.0),
      (const Size(2560, 1600), 2.0),
      (const Size(2560, 1600), 1.0),
    ]) {
      final r = await panelRect(tester, physical, ratio);
      expect(r.left, closeTo(reference.left, 1e-6));
      expect(r.top, closeTo(reference.top, 1e-6));
      expect(r.width, closeTo(reference.width, 1e-6));
      expect(r.height, closeTo(reference.height, 1e-6));
    }
  });
}
