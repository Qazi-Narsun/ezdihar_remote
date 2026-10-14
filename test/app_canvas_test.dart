import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezdihar_remote/data/building_data.dart';
import 'package:ezdihar_remote/l10n/app_strings.dart';
import 'package:ezdihar_remote/screens/building_detail_screen.dart';
import 'package:ezdihar_remote/screens/city_context_screen.dart';
import 'package:ezdihar_remote/screens/initial_screen.dart';
import 'package:ezdihar_remote/screens/masterplan_screen.dart';
import 'package:ezdihar_remote/screens/register_interest_screen.dart';
import 'package:ezdihar_remote/widgets/app_canvas.dart';

/// 16:10 screens: physical size x device pixel ratio.
const _screens = [Size(1280, 800), Size(1920, 1200), Size(2560, 1600)];
const _ratios = [1.0, 1.5, 2.0];

void main() {
  late List<BuildingType> types;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    types = await BuildingType.loadAll();
  });

  void noop(Locale _) {}

  final screens = <String, Widget Function()>{
    'initial': () => InitialScreen(locale: const Locale('ar'), onLocaleChanged: noop),
    'city context': () => CityContextScreen(onLocaleChanged: noop),
    'masterplan': () => MasterplanScreen(onLocaleChanged: noop),
    'building': () => BuildingDetailScreen(type: types.first, buildingId: 'A01', onLocaleChanged: noop),
    'register interest': () => const RegisterInterestScreen(),
    'thank you': () => const InterestRegisteredScreen(),
  };

  /// Pumps [screen] like the app does and returns every visible text's rect
  /// as a fraction of the screen.
  Future<List<Rect>> layout(WidgetTester tester, Widget screen, Size physical, double ratio, String locale) async {
    tester.view.physicalSize = physical;
    tester.view.devicePixelRatio = ratio;
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
        home: screen,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    final logical = physical / ratio;
    return [
      for (final element in find.byType(RichText).hitTestable().evaluate())
        if ((element.renderObject! as RenderBox).hasSize)
          _fraction(tester.getRect(find.byElementPredicate((e) => e == element)), logical),
    ];
  }

  for (final locale in ['ar', 'en']) {
    for (final MapEntry(key: name, value: build) in screens.entries) {
      testWidgets('$name ($locale) is the same on every 16:10 screen, without overlaps', (tester) async {
        List<Rect>? reference;
        for (final physical in _screens) {
          for (final ratio in _ratios) {
            final rects = await layout(tester, build(), physical, ratio, locale);
            final label = '${physical.width.toInt()}x${physical.height.toInt()} @${ratio}x';
            for (var i = 0; i < rects.length; i++) {
              for (var j = i + 1; j < rects.length; j++) {
                final overlap = rects[i].intersect(rects[j]);
                expect(
                  overlap.width > 0.001 && overlap.height > 0.001,
                  isFalse,
                  reason: '$label: texts overlap at ${rects[i]} and ${rects[j]}',
                );
              }
            }
            if (reference == null) {
              reference = rects;
              continue;
            }
            expect(rects, hasLength(reference.length), reason: label);
            for (var i = 0; i < rects.length; i++) {
              for (final (a, b) in [
                (rects[i].left, reference[i].left),
                (rects[i].top, reference[i].top),
                (rects[i].right, reference[i].right),
                (rects[i].bottom, reference[i].bottom),
              ]) {
                expect(a, closeTo(b, 0.0005), reason: '$label: text $i moved');
              }
            }
          }
        }
      });
    }
  }

  testWidgets('letterboxes a screen that is not 16:10', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Size canvas;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppCanvas(child: child!),
        home: Builder(
          builder: (context) {
            canvas = MediaQuery.sizeOf(context);
            return const ColoredBox(key: Key('page'), color: Colors.red);
          },
        ),
      ),
    );
    expect(canvas, AppCanvas.size);
    // 1080 high -> 1728 wide, centred: 96 px bars left and right.
    expect(tester.getRect(find.byKey(const Key('page'))), const Rect.fromLTWH(96, 0, 1728, 1080));
  });
}

Rect _fraction(Rect r, Size screen) =>
    Rect.fromLTRB(r.left / screen.width, r.top / screen.height, r.right / screen.width, r.bottom / screen.height);
