import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_strings.dart';
import 'l10n/locale_controller.dart';
import 'screens/initial_screen.dart';
import 'services/player_connection.dart';
import 'services/ui_feedback.dart';
import 'widgets/app_canvas.dart';
import 'widgets/directional_page_transitions.dart';
import 'widgets/idle_reset.dart';
import 'widgets/locale_fade.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kiosk tablet (1920x1200, landscape): hide status + navigation bars.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  UiFeedback.init(); // pre-load interaction sounds; never blocks startup
  await PlayerConnection.load(); // reconnects to the paired main screen, if any
  runApp(MyApp(localeController: await LocaleController.load()));
}

final _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) => _buildApp(),
    );
  }

  Widget _buildApp() {
    final locale = localeController.locale;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      builder: (context, child) => AppCanvas(
        child: LocaleFade(
          locale: locale,
          child: IdleReset(navigatorKey: _navigatorKey, child: child!),
        ),
      ),
      title: 'Ezdihar Remote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: DirectionalPageTransitionsBuilder(),
          TargetPlatform.windows: DirectionalPageTransitionsBuilder(),
          TargetPlatform.iOS: DirectionalPageTransitionsBuilder(),
          TargetPlatform.linux: DirectionalPageTransitionsBuilder(),
          TargetPlatform.macOS: DirectionalPageTransitionsBuilder(),
        }),
      ),
      // The locale drives text direction: ar -> RTL, en -> LTR.
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: InitialScreen(
        locale: locale,
        onLocaleChanged: localeController.setLocale,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
