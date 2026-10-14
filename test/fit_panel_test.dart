import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezdihar_remote/widgets/fit_panel.dart';

void main() {
  Future<Size> panelSize(WidgetTester tester, Size screen) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = screen;
    addTearDown(tester.view.reset);
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
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
    return tester.getSize(find.byType(FitPanel));
  }

  testWidgets('keeps Figma size on a 1920 wide screen', (tester) async {
    expect(await panelSize(tester, const Size(1920, 1200)), const Size(600, 400));
  });

  testWidgets('takes the same share of a 1280x800 (1.5x) screen as in Figma', (tester) async {
    final size = await panelSize(tester, const Size(1280, 800));
    expect(size.width, closeTo(400, 0.01));
    expect(size.height, closeTo(400 * 1280 / 1920, 0.01));
  });
}
