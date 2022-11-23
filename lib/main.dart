import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/SettingController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Screens/Main_Screens/calendar_notes_and_votes_screen.dart';
import 'package:de/Screens/Main_Screens/calendar_screen.dart';
import 'package:de/Screens/Main_Screens/calendar_settings_screen.dart';
import 'package:de/Screens/Main_Screens/HomePage.dart';
import 'package:de/Screens/Main_Screens/LoginPage.dart';
import 'package:de/Screens/Main_Screens/new_calendar_screen.dart';
import 'package:de/Screens/Main_Screens/profile_edit_screen.dart';
import 'package:de/Screens/Main_Screens/profile_screen.dart';
import 'package:de/Screens/Main_Screens/RegisterPage.dart';
import 'package:de/Screens/Main_Screens/settings_screen.dart';
import 'package:de/Screens/Main_Screens/StartUpPage.dart';
import 'package:de/Utils/RouteGenerator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  tz.initializeTimeZones();
  setupLocator();

  WidgetsFlutterBinding.ensureInitialized();
  await SettingController.init();

  runApp(Xitem());
}

class Xitem extends StatefulWidget {
  const Xitem();

  @override
  State<StatefulWidget> createState() {
    return _XitemState();
  }
}

class _XitemState extends State<Xitem> {
  @override
  void initState() {
    super.initState();
    ThemeController.loadThemeFromSettings();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration(
      headerTriggerDistance: 85,
      dragSpeedRatio: 0.9,
      child: MaterialApp(
        title: 'Xitem',
        theme: ThemeData(
          primaryColor: Colors.amber,
          accentColor: Colors.amber,
          brightness: ThemeController.activeTheme().themeBrightness,
          accentColorBrightness: ThemeController.activeTheme().themeBrightness,
          primaryColorBrightness: ThemeController.activeTheme().themeBrightness,
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('de', 'DE'),
        ],
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
