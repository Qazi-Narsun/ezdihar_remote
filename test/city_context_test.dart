import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezdihar_remote/l10n/app_strings.dart';
import 'package:ezdihar_remote/screens/city_context_screen.dart';
import 'package:ezdihar_remote/screens/masterplan_screen.dart';
import 'package:ezdihar_remote/widgets/app_canvas.dart';

void main() {
  Future<Rect> pumpCity(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppCanvas(child: child!),
        locale: const Locale('en'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CityContextScreen(onLocaleChanged: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final polygon = find.byWidgetPredicate(
      (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.endsWith('site_polygon.png'),
    );
    return tester.getRect(polygon);
  }

  testWidgets('tapping the highlighted site opens the masterplan', (tester) async {
    final site = await pumpCity(tester);
    await tester.tapAt(site.topLeft + Offset(site.width * 0.6, site.height * 0.6));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MasterplanScreen), findsOneWidget);
  });

  testWidgets('tapping the map just outside the site does nothing', (tester) async {
    final site = await pumpCity(tester);
    // Top-start corner of the image's box lies outside the polygon.
    await tester.tapAt(site.topLeft + Offset(site.width * 0.04, site.height * 0.04));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MasterplanScreen), findsNothing);
  });
}
