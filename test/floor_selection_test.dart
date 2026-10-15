import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezdihar_remote/data/building_data.dart';
import 'package:ezdihar_remote/l10n/app_strings.dart';
import 'package:ezdihar_remote/screens/building_detail_screen.dart';
import 'package:ezdihar_remote/widgets/app_canvas.dart';

void main() {
  late BuildingType typeC;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    typeC = (await BuildingType.loadAll()).firstWhere((t) => t.type == 'C');
  });

  Future<void> pumpBuilding(WidgetTester tester, String locale) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppCanvas(child: child!),
        locale: Locale(locale),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BuildingDetailScreen(type: typeC, buildingId: 'C01', onLocaleChanged: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('floors use the sheet names; a floor without apartments hides the apartments panel',
      (tester) async {
    await pumpBuilding(tester, 'en');

    // The lowest outline on the photo is 1F, which has apartments.
    await tester.tap(find.byTooltip('1F'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('1F Details'), findsOneWidget);
    expect(find.text('Apartments'), findsOneWidget);

    // Type C's GF has no apartments in the sheet; it has its own outline.
    await tester.tap(find.byTooltip('GF'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500)); // panel fade-out
    await tester.pump();
    expect(find.text('GF Details'), findsOneWidget);
    expect(find.text('Apartments'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic floor names', (tester) async {
    await pumpBuilding(tester, 'ar');
    await tester.tap(find.byTooltip('ط1'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('تفاصيل ط1'), findsOneWidget);
  });
}
