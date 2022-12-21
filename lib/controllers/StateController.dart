import 'package:flutter/material.dart';
import 'package:xitem/api/AuthenticationApi.dart';
import 'package:xitem/api/CalendarApi.dart';
import 'package:xitem/api/CalendarMemberApi.dart';
import 'package:xitem/api/EventApi.dart';
import 'package:xitem/api/HolidayApi.dart';
import 'package:xitem/api/NoteApi.dart';
import 'package:xitem/api/UserApi.dart';
import 'package:xitem/controllers/BirthdayController.dart';
import 'package:xitem/controllers/HolidayController.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/CalendarMember.dart';
import 'package:xitem/pages/main/CalendarPage.dart';
import 'package:xitem/pages/main/CalendarSettingsPage.dart';
import 'package:xitem/pages/main/EditProfilePage.dart';
import 'package:xitem/pages/main/HomePage.dart';
import 'package:xitem/pages/main/LoginPage.dart';
import 'package:xitem/pages/main/NewCalendarPage.dart';
import 'package:xitem/pages/main/NotesPage.dart';
import 'package:xitem/pages/main/ProfilePage.dart';
import 'package:xitem/pages/main/RegisterPage.dart';
import 'package:xitem/pages/main/SettingsPage.dart';
import 'package:xitem/pages/main/StartUpPage.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/SecureStorage.dart';
import 'CalendarController.dart';
import 'UserController.dart';

class StateController {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final AuthenticationApi _authenticationApi = AuthenticationApi();
  static final UserApi _userApi = UserApi();
  static final CalendarApi _calendarApi = CalendarApi();
  static final EventApi _eventApi = EventApi();
  static final CalendarMemberApi _calendarMemberApi = CalendarMemberApi();
  static final NoteApi _noteApi = NoteApi();
  static final HolidayApi _holidayApi = HolidayApi();

  static AppState _appState = AppState.loggedOut;

  static late UserController _userController;
  static late CalendarController _calendarController;
  static late HolidayController _holidayController;
  static late BirthdayController _birthdayController;

  static Future<ApiResponse<String>> getApiInfo() {
    return _authenticationApi.checkStatus();
  }

  static Future<ResponseCode> localLogin() async {
    if(_appState != AppState.loggedOut) {
      return ResponseCode.invalidAction;
    }

    ApiResponse<String> localLogin = await _authenticationApi.localLogin();
    String? userID = localLogin.value;

    if(localLogin.code != ResponseCode.success) {
      return localLogin.code;
    } else if(userID == null) {
      return ResponseCode.unknown;
    }

    ResponseCode init = await _initializeController(userID);

    if(init != ResponseCode.success) {
      return init;
    }

    _appState = AppState.loggedIn;
    return ResponseCode.success;
  }

  static Future<ResponseCode> remoteLogin(String email, String password) async {
    if(_appState != AppState.loggedOut) {
      return ResponseCode.invalidAction;
    }

    ApiResponse remoteLogin = await _authenticationApi.remoteLogin(UserLoginRequest(email, password));
    return remoteLogin.code;
  }

  static Future<ResponseCode> safeLogout() async {
    if(_appState != AppState.loggedIn) {
      return ResponseCode.invalidAction;
    }

    await SecureStorage.wipeStorage();

    _userController = UserController(_userApi);
    _calendarController = CalendarController(_calendarApi, _authenticationApi, _eventApi, _calendarMemberApi, _noteApi);

    _appState = AppState.loggedOut;
    return ResponseCode.success;
  }

  static Future<ResponseCode> reinitializeCalendarController() async {
    if(_appState != AppState.loggedIn) {
      return ResponseCode.invalidAction;
    }

    CalendarController calendarController = CalendarController(_calendarApi, _authenticationApi, _eventApi, _calendarMemberApi, _noteApi);
    ResponseCode initCalendarController = await calendarController.initialize(_userController.getAuthenticatedUser().id);
    if(initCalendarController != ResponseCode.success) {
      return initCalendarController;
    }

    _calendarController = calendarController;
    return ResponseCode.success;
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch(settings.name) {
      case '/startup':
        return MaterialPageRoute(maintainState: false, builder: (_) => const StartUpPage());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginPage(_authenticationApi));
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterPage(_authenticationApi));
      case '/home':
        return MaterialPageRoute(builder: (_) => HomePage(HomeSubPage.events, _userController, _calendarController, _holidayController, _birthdayController));
      case '/home/calendar':
        return MaterialPageRoute(builder: (_) => HomePage(HomeSubPage.calendars, _userController, _calendarController, _holidayController, _birthdayController));
      case '/calendar':
        if(args is String) {
          return MaterialPageRoute(builder: (_) => CalendarPage(args, _calendarController, _userController, _holidayController, _birthdayController));
        }
        break;
      case '/calendar/settings':
        if(args is String) {
          return MaterialPageRoute(builder: (_) => CalendarSettingsPage(args, _calendarController, _userController));
        }
        break;
      case '/calendar/notes':
        if(args is String) {
          return MaterialPageRoute(builder: (_) => NotesPage(args, _calendarController, _userController));
        }
        break;
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfilePage(_userController.getAuthenticatedUser()));
      case '/editProfile':
        return MaterialPageRoute(builder: (_) => EditProfilePage(_userController, _authenticationApi));
      case '/createCalendar':
        return MaterialPageRoute(builder: (_) => NewCalendarPage(_calendarController));
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsPage(_holidayController, _userController, _authenticationApi));
    }

    return MaterialPageRoute(builder: (_) => _ErrorPage());
  }

  static Future<ResponseCode> _initializeController(String loggedInUserID) async {
    _appState = AppState.initialising;

    UserController userController = UserController(_userApi);
    ResponseCode initUserController = await userController.initialize(loggedInUserID);
    if(initUserController != ResponseCode.success) {
      print("Initializing UserController failed with Code:$initUserController");
      return initUserController;
    }

    CalendarController calendarController = CalendarController(_calendarApi, _authenticationApi, _eventApi, _calendarMemberApi, _noteApi);
    ResponseCode initCalendarController = await calendarController.initialize(userController.getAuthenticatedUser().id);
    if(initCalendarController != ResponseCode.success) {
      print("Initializing CalendarController failed with Code:$initCalendarController");
      return initCalendarController;
    }

    for(Calendar calendar in calendarController.getCalendarMap().values) {
      for(CalendarMember member in calendar.calendarMemberController.getMemberList()) {
        await userController.getUser(member.userID);
      }
    }

    HolidayController holidayController = HolidayController(_holidayApi);
    ResponseCode initHolidayController = await holidayController.initialize();
    if(initHolidayController != ResponseCode.success) {
      print("Initializing HolidayController failed with Code:$initHolidayController");
      return initHolidayController;
    }

    BirthdayController birthdayController = BirthdayController(userController);
    ResponseCode initBirthdayController = await birthdayController.initialize();
    if(initBirthdayController != ResponseCode.success) {
      print("Initializing BirthdayController failed with Code:$initBirthdayController");
      return initHolidayController;
    }

    _userController = userController;
    _calendarController = calendarController;
    _holidayController = holidayController;
    _birthdayController = birthdayController;

    return ResponseCode.success;
  }
}

enum AppState {
  initialising,
  loggedOut,
  loggedIn,
}

class _ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              height: 160.0,
              child: FlutterLogo(size: 120),
            ),
            const SizedBox(height: 20),
            Text("Ein Fehler ist aufgetreten! Sry...", textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 20.0).copyWith(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false), child: Text("<= Zurück", textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 20.0).copyWith(color: Colors.white, fontSize: 18)),)
          ],
        ),
      ),
    );
  }
}