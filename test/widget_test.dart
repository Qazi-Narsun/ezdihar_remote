import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ezdihar_remote/l10n/locale_controller.dart';
import 'package:ezdihar_remote/main.dart';

void main() {
  testWidgets('first page offers Start Journey in the default (Arabic) locale', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = await LocaleController.load();

    await tester.pumpWidget(MyApp(localeController: controller));
    await tester.pump();

    expect(find.text('ابدأ الرحلة'), findsOneWidget);
  });
}
