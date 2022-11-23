import 'package:flutter/material.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch(settings.name) {
      case '/live_list_grid':
        return MaterialPageRoute(builder: (_) => LiveListGridPage());
      case '/live_list':
        if(args is String) {
          return PageTransition(
              child: LiveListPage(args),
              type: PageTransitionType.fade
          );
        }
        break;
      case '/startup':
        return MaterialPageRoute(maintainState: false, builder: (_) => StartUpPage());
    }

    return MaterialPageRoute(builder: (_) => _ErrorPage());
  }
}

// home: StartUpScreen(),
// routes: <String, WidgetBuilder>{
// '/startup': (BuildContext context) => new StartUpScreen(),
// '/login': (BuildContext context) => new LoginScreen(),
// '/register': (BuildContext context) => new RegisterScreen(),
// '/home': (BuildContext context) => new HomeScreen(1),
// '/home/calendar': (BuildContext context) => new HomeScreen(0),
// '/calendar': (BuildContext context) => new SingleCalendarScreen(ModalRoute.of(context).settings.arguments),
// '/calendarSettings': (BuildContext context) => new CalendarSettingsScreen(ModalRoute.of(context).settings.arguments),
// '/calendarNotesAndVotes': (BuildContext context) => new CalendarNotesAndVotesScreen(ModalRoute.of(context).settings.arguments),
// '/profile': (BuildContext context) => new ProfileScreen(),
// '/editProfile': (BuildContext context) => new EditProfileScreen(),
// '/createCalendar': (BuildContext context) => new NewCalendarScreen(),
// '/settings': (BuildContext context) => new SettingsScreen(),
// },

class _ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 160.0,
                child: FlutterLogo(size: 120),
              ),
              SizedBox(height: 20),
              Text("Ein Routingfehler ist aufgetreten! Sry...", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Montserrat', fontSize: 20.0).copyWith(color: Colors.white, fontSize: 18)),
              SizedBox(height: 20),
              TextButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false), child: Text("<= Zurück", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Montserrat', fontSize: 20.0).copyWith(color: Colors.white, fontSize: 18)),)
            ],
          ),
        ),
      ),
    );
  }
}