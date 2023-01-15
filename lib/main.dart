import 'package:xitem/controllers/SettingController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:xitem/pages/main/StartUpPage.dart';

void main() async {
  tz.initializeTimeZones();

  WidgetsFlutterBinding.ensureInitialized();
  await Xitem.settingController.initialize();

  runApp(const Xitem());
}

class Xitem extends StatefulWidget {
  const Xitem({super.key});

  static const String appVersion = "1.3.1";
  static final SettingController settingController = SettingController();

  @override
  State<StatefulWidget> createState() => _XitemState();
}

class _XitemState extends State<Xitem> {
  @override
  void initState() {
    super.initState();
    ThemeController.loadThemeFromSettings(Xitem.settingController);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xitem',
      theme: ThemeData(
        primaryColor: Colors.amber,
        accentColor: Colors.amber,
        brightness: ThemeController.activeTheme().themeBrightness,
        accentColorBrightness: ThemeController.activeTheme().themeBrightness,
        primaryColorBrightness: ThemeController.activeTheme().themeBrightness,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'),
      ],
      navigatorKey: StateController.navigatorKey,
      onGenerateRoute: StateController.generateRoute,
      home: const StartUpPage(),
    );
  }
}
