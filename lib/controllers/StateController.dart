import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:xitem/api/AuthenticationApi.dart';
import 'package:xitem/api/CalendarApi.dart';
import 'package:xitem/api/CalendarMemberApi.dart';
import 'package:xitem/api/EventApi.dart';
import 'package:xitem/api/HolidayApi.dart';
import 'package:xitem/api/NoteApi.dart';
import 'package:xitem/api/UserApi.dart';
import 'package:xitem/controllers/AuthenticationController.dart';
import 'package:xitem/controllers/BirthdayController.dart';
import 'package:xitem/controllers/HolidayController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/CalendarMember.dart';
import 'package:xitem/pages/main/CalendarPage.dart';
import 'package:xitem/pages/main/CalendarSettingsPage.dart';
import 'package:xitem/pages/main/EditProfilePage.dart';
import 'package:xitem/pages/main/EventPage.dart';
import 'package:xitem/pages/main/HomePage.dart';
import 'package:xitem/pages/main/LoginPage.dart';
import 'package:xitem/pages/main/NewCalendarPage.dart';
import 'package:xitem/pages/main/NotesPage.dart';
import 'package:xitem/pages/main/ProfilePage.dart';
import 'package:xitem/pages/main/RegisterPage.dart';
import 'package:xitem/pages/main/SettingsPage.dart';
import 'package:xitem/pages/main/StartUpPage.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
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

  static final AuthenticationController authenticationController = AuthenticationController(_authenticationApi);

  static AppState _appState = AppState.uninitialized;
  static final List<AppStateListener> _stateListeners = [];

  static UserController? _userController;
  static CalendarController? _calendarController;
  static HolidayController? _holidayController;
  static BirthdayController? _birthdayController;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    UserController? userController = _userController;
    CalendarController? calendarController = _calendarController;
    HolidayController? holidayController = _holidayController;
    BirthdayController? birthdayController = _birthdayController;

    switch (settings.name) {
      case '/startup':
        return MaterialPageRoute(maintainState: false, builder: (_) => const StartUpPage());
      case '/login':
        return PageTransition(
          child: LoginPage(authenticationApi: _authenticationApi),
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          type: PageTransitionType.fade,
        );
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterPage(authenticationApi: _authenticationApi));
      case '/home':
        if (userController != null && calendarController != null && holidayController != null && birthdayController != null) {
          return PageTransition(
            child: HomePage(
              initialSubPage: HomeSubPage.events,
              userController: userController,
              calendarController: calendarController,
              holidayController: holidayController,
              birthdayController: birthdayController
            ),
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 300),
            type: PageTransitionType.fade,
          );
        }
        break;
      case '/home/calendar':
        if (userController != null && calendarController != null && holidayController != null && birthdayController != null) {
          return PageTransition(
              child: HomePage(
                  initialSubPage: HomeSubPage.calendars,
                  userController: userController,
                  calendarController: calendarController,
                  holidayController: holidayController,
                  birthdayController: birthdayController
              ),
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 300),
            type: PageTransitionType.fade,
          );
        }
        break;
      case '/calendar':
        if (args is String && userController != null && calendarController != null && holidayController != null && birthdayController != null) {
          return PageTransition(
            child: CalendarPage(
                linkedCalendarID: args, userController: userController, calendarController: calendarController, holidayController: holidayController, birthdayController: birthdayController),
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 300),
            type: PageTransitionType.fade,
          );
        }
        break;
      case '/calendar/settings':
        if (args is String && userController != null && calendarController != null) {
          return PageTransition(
            child: CalendarSettingsPage(linkedCalendarID: args, userController: userController, calendarController: calendarController),
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 300),
            type: PageTransitionType.fade,
          );
        }
        break;
      case '/calendar/notes':
        if (args is String && userController != null && calendarController != null) {
          return PageTransition(
            child: NotesPage(linkedCalendarID: args, userController: userController, calendarController: calendarController),
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 300),
            type: PageTransitionType.fade,
          );
        }
        break;
      case '/event':
        if (args is EventPageArguments) {
          return PageTransition(
            child: EventPage(arguments: args),
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 300),
            type: PageTransitionType.fade,
          );
        }
        break;
      case '/profile':
        if (userController != null) {
          return PageTransition(
            child: ProfilePage(userController.getAuthenticatedUser()),
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 300),
            type: PageTransitionType.fade,
          );
        }
        break;
      case '/editProfile':
        if (userController != null) {
          return PageTransition(
              child: EditProfilePage(userController: userController, authenticationApi: _authenticationApi),
              duration: const Duration(milliseconds: 300),
              reverseDuration: const Duration(milliseconds: 300),
              type: PageTransitionType.fade
          );
        }
        break;
      case '/createCalendar':
        if (calendarController != null) {
          return PageTransition(
              child: NewCalendarPage(calendarController: calendarController),
              duration: const Duration(milliseconds: 300),
              reverseDuration: const Duration(milliseconds: 300),
              type: PageTransitionType.fade
          );
        }
        break;
      case '/settings':
        if (userController != null && holidayController != null) {
          return PageTransition(
            child: SettingsPage(
              userController: userController,
              authenticationApi: _authenticationApi,
              holidayController: holidayController,
            ),
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 300),
            type: PageTransitionType.fade,
          );
        }
        break;
    }

    return MaterialPageRoute(builder: (_) => _ErrorPage());
  }

  static Future<StartupResponse> initializeAppState() async {
    if (_appState != AppState.uninitialized) {
      return StartupResponse.alreadyStarted;
    }

    debugPrint("Initializing StateController...");
    debugPrint("Checking Api Connection");
    _setAppState(AppState.connecting);

    ApiResponse<String> connection = await _authenticationApi.checkStatus().timeout(const Duration(seconds: 20), onTimeout: () {
      return ApiResponse(ResponseCode.timeout);
    });

    String? apiInfo = connection.value;
    if (connection.code != ResponseCode.success || apiInfo == null) {
      return StartupResponse.connectionFailed;
    }
    debugPrint("Connected with $apiInfo");

    if (!authenticationController.loggedIn) {
      debugPrint("Authenticating...");
      _setAppState(AppState.authenticating);

      ResponseCode tokenLogin = await authenticationController.authenticateWithSecuredToken();

      if (tokenLogin != ResponseCode.success) {
        _resetAppState();
        return StartupResponse.authenticationFailed;
      }
    }

    if (authenticationController.authenticatedUserID.isEmpty) {
      logOut();
      return StartupResponse.authenticationFailed;
    }

    _setAppState(AppState.authenticated);
    debugPrint("User <${authenticationController.authenticatedUserID}> is authenticated");

    debugPrint("Initializing essential controllers...");
    ResponseCode initControllers = await _initializeEssentialControllers(authenticationController.authenticatedUserID);

    if (initControllers != ResponseCode.success) {
      _resetAppState();
      return StartupResponse.controllerInitializationFailed;
    }

    debugPrint("Initializing StateController successful!");

    _setAppState(AppState.initialized);
    return StartupResponse.success;
  }

  static Future<ResponseCode> reinitializeCalendarController() async {
    if (_appState != AppState.initialized) {
      return ResponseCode.invalidAction;
    }

    UserController? userController = _userController;
    if (userController == null) {
      return ResponseCode.internalError;
    }

    CalendarController calendarController = CalendarController(_calendarApi, authenticationController, _eventApi, _calendarMemberApi, _noteApi);
    ResponseCode initCalendarController = await calendarController.initialize(userController.getAuthenticatedUser().id);
    if (initCalendarController != ResponseCode.success) {
      return initCalendarController;
    }

    _calendarController = calendarController;
    return ResponseCode.success;
  }

  static Future<void> logOut() async {
    await authenticationController.safeLogout();
    _resetAppState();
  }

  static void registerListener(AppStateListener newListener) {
    _stateListeners.add(newListener);
  }

  static bool removeListener(AppStateListener listener) {
    return _stateListeners.remove(listener);
  }

  static void _setAppState(AppState newState) {
    AppState oldState = _appState;
    _appState = newState;

    for (var listener in _stateListeners) {
      listener.onAppStateChanged(oldState, newState);
    }
  }

  static _resetAppState() {
    _userController = null;
    _calendarController = null;
    _holidayController = null;
    _birthdayController = null;

    _setAppState(AppState.uninitialized);
  }

  static Future<ResponseCode> _initializeEssentialControllers(String loggedInUserID) async {
    if (_appState != AppState.authenticated) {
      return ResponseCode.invalidAction;
    }

    _setAppState(AppState.initialisingUserController);
    UserController userController = UserController(_userApi);
    ResponseCode initUserController = await userController.initialize(loggedInUserID);
    if (initUserController != ResponseCode.success) {
      debugPrint("Initializing UserController failed with Code:$initUserController");
      return initUserController;
    }

    _setAppState(AppState.initialisingCalendarController);
    CalendarController calendarController = CalendarController(_calendarApi, authenticationController, _eventApi, _calendarMemberApi, _noteApi);
    ResponseCode initCalendarController = await calendarController.initialize(userController.getAuthenticatedUser().id);
    if (initCalendarController != ResponseCode.success) {
      debugPrint("Initializing CalendarController failed with Code:$initCalendarController");
      return initCalendarController;
    }

    for (Calendar calendar in calendarController.getCalendarMap().values) {
      for (CalendarMember member in calendar.calendarMemberController.getMemberList()) {
        await userController.getUser(member.userID);
      }
    }

    _setAppState(AppState.initialisingHolidayController);
    HolidayController holidayController = HolidayController(_holidayApi);
    ResponseCode initHolidayController = await holidayController.initialize();
    if (initHolidayController != ResponseCode.success) {
      debugPrint("Initializing HolidayController failed with Code:$initHolidayController");
      return initHolidayController;
    }

    _setAppState(AppState.initialisingBirthdayController);
    BirthdayController birthdayController = BirthdayController(userController);
    ResponseCode initBirthdayController = await birthdayController.initialize();
    if (initBirthdayController != ResponseCode.success) {
      debugPrint("Initializing BirthdayController failed with Code:$initBirthdayController");
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
  uninitialized,
  connecting,
  authenticating,
  authenticated,
  initialisingUserController,
  initialisingCalendarController,
  initialisingHolidayController,
  initialisingBirthdayController,
  initialized,
}

enum StartupResponse {
  success,
  connectionFailed,
  authenticationFailed,
  controllerInitializationFailed,
  alreadyStarted,
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
            TextButton(
              onPressed: () {
                StateController.logOut();
                Navigator.pushNamedAndRemoveUntil(context, "/startup", (route) => false);
              },
              child: Text("<= Zurück", textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 20.0).copyWith(color: Colors.white, fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}

abstract class AppStateListener {
  void onAppStateChanged(AppState oldState, AppState newState) {}
}
