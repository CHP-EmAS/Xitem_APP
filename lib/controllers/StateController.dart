import 'dart:convert';

import 'package:crypto/crypto.dart';
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
import 'package:xitem/utils/SecureStorage.dart';
import 'CalendarController.dart';
import 'UserController.dart';

class StateController {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final SecureStorage secureStorage = SecureStorage();

  static final AuthenticationApi _authenticationApi = AuthenticationApi();
  static final UserApi _userApi = UserApi();
  static final CalendarApi _calendarApi = CalendarApi();
  static final EventApi _eventApi = EventApi();
  static final CalendarMemberApi _calendarMemberApi = CalendarMemberApi();
  static final NoteApi _noteApi = NoteApi();
  static final HolidayApi _holidayApi = HolidayApi();

  static AppState _appState = AppState.loggedOut;

  static UserController? _userController;
  static CalendarController? _calendarController;
  static HolidayController? _holidayController;
  static BirthdayController? _birthdayController;

  static Future<ApiResponse<String>> getApiInfo() {
    return _authenticationApi.checkStatus();
  }

  static Future<ResponseCode> authenticateWithCredentials(String email, String password) async {
    if(_appState != AppState.loggedOut) {
      return ResponseCode.invalidAction;
    }

    debugPrint("Authentication with credentials started...");

    ApiResponse<RemoteAuthenticationData> remoteLogin = await _authenticationApi.remoteLogin(UserLoginRequest(email, password));
    RemoteAuthenticationData? authData = remoteLogin.value;

    if(remoteLogin.code != ResponseCode.success) {
      debugPrint("Authentication with credentials failed with Code: ${remoteLogin.code}");
      return ResponseCode.authenticationFailed;
    } else if (authData == null) {
      debugPrint("Authentication with credentials failed because User ID is missing in response");
      return ResponseCode.internalError;
    }

    debugPrint("Authentication with credentials successful. Retrieved User ID: ${authData.userID}");
    debugPrint("Overwriting Secure Storage");

    secureStorage.writeVariable(SecureVariable.authenticationToken, authData.authenticationToken);
    secureStorage.writeVariable(SecureVariable.refreshToken, authData.refreshToken);

    List<int> passwordBytes = utf8.encode(password);
    secureStorage.writeVariable(SecureVariable.hashedPassword, sha256.convert(passwordBytes).toString());

    return ResponseCode.success;
  }

  static Future<StartupResponse> initializeAppState({ValueNotifier<int>? progress}) async {
    if(_appState != AppState.loggedOut) {
      return StartupResponse.alreadyStarted;
    }

    debugPrint("Initializing StateController...");
    debugPrint("Checking Api Connection");
    _appState = AppState.connecting;

    progress?.value = 12;

    ApiResponse<String> connection = await StateController.getApiInfo().timeout(const Duration(seconds: 30), onTimeout: () {
      return ApiResponse(ResponseCode.timeout);
    });

    String? apiInfo = connection.value;
    if(connection.code != ResponseCode.success || apiInfo == null) {
      return StartupResponse.connectionFailed;
    }

    debugPrint("Connected with $apiInfo");
    debugPrint("Authenticating...");
    _appState = AppState.authenticating;
    progress?.value = 24;

    ApiResponse<String> userIdRequest = await _authenticationApi.requestUserIdByToken();

    String? userID = userIdRequest.value;
    if(userIdRequest.code != ResponseCode.success || userID == null) {
      safeLogout();
      return StartupResponse.authenticationFailed;
    }

    debugPrint("User <$userID> is authenticated");
    debugPrint("Initializing essential controllers...");
    _appState = AppState.initialising;
    progress?.value = 50;

    ResponseCode initControllers = await _initializeEssentialControllers(userID, progress: progress);

    if(initControllers != ResponseCode.success) {
      safeLogout();
      return StartupResponse.controllerInitializationFailed;
    }

    debugPrint("Initializing StateController successful!");

    progress?.value = 100;
    _appState = AppState.loggedIn;
    return StartupResponse.success;
  }

  static Future<ResponseCode> safeLogout() async {
    await secureStorage.wipeStorage();

    _userController = null;
    _calendarController = null;
    _holidayController = null;
    _birthdayController = null;

    _appState = AppState.loggedOut;

    return ResponseCode.success;
  }

  static Future<ResponseCode> reinitializeCalendarController() async {
    if(_appState != AppState.loggedIn) {
      return ResponseCode.invalidAction;
    }

    UserController? userController = _userController;
    if(userController == null) {
      return ResponseCode.internalError;
    }

    CalendarController calendarController = CalendarController(_calendarApi, _authenticationApi, _eventApi, _calendarMemberApi, _noteApi);
    ResponseCode initCalendarController = await calendarController.initialize(userController.getAuthenticatedUser().id);
    if(initCalendarController != ResponseCode.success) {
      return initCalendarController;
    }

    _calendarController = calendarController;
    return ResponseCode.success;
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    UserController? userController = _userController;
    CalendarController? calendarController = _calendarController;
    HolidayController? holidayController = _holidayController;
    BirthdayController? birthdayController = _birthdayController;

    switch(settings.name) {
      case '/startup':
        return MaterialPageRoute(
            maintainState: false,
            builder: (_) => const StartUpPage()
        );
      case '/login':
        return MaterialPageRoute(
            builder: (_) => LoginPage(authenticationApi: _authenticationApi)
        );
      case '/register':
        return MaterialPageRoute(
            builder: (_) => RegisterPage(authenticationApi: _authenticationApi)
        );
      case '/home':
        if(userController != null && calendarController != null && holidayController != null && birthdayController != null) {
          return MaterialPageRoute(
              builder: (_) => HomePage(
                  initialSubPage: HomeSubPage.events,
                  userController: userController,
                  calendarController: calendarController,
                  holidayController: holidayController,
                  birthdayController: birthdayController
              )
          );
        }
        break;
      case '/home/calendar':
        if(userController != null && calendarController != null && holidayController != null && birthdayController != null) {
          return MaterialPageRoute(
              builder: (_) => HomePage(
                  initialSubPage: HomeSubPage.calendars,
                  userController: userController,
                  calendarController: calendarController,
                  holidayController: holidayController,
                  birthdayController: birthdayController
              )
          );
        }
        break;
      case '/calendar':
        if(args is String && userController != null && calendarController != null && holidayController != null && birthdayController != null) {
          return MaterialPageRoute(
              builder: (_) => CalendarPage(
                  linkedCalendarID: args,
                  userController: userController,
                  calendarController: calendarController,
                  holidayController: holidayController,
                  birthdayController: birthdayController
              )
          );
        }
        break;
      case '/calendar/settings':
        if(args is String && userController != null && calendarController != null) {
          return MaterialPageRoute(
              builder: (_) => CalendarSettingsPage(
                  linkedCalendarID:args,
                  userController: userController,
                  calendarController: calendarController
              )
          );
        }
        break;
      case '/calendar/notes':
        if(args is String && userController != null && calendarController != null) {
          return MaterialPageRoute(
              builder: (_) => NotesPage(
                  linkedCalendarID: args,
                  userController: userController,
                  calendarController: calendarController
              )
          );
        }
        break;
      case '/event':
        if(args is EventPageArguments) {
          return MaterialPageRoute(
              builder: (_) => EventPage(arguments: args)
          );
        }
        break;
      case '/profile':
        if(userController != null) {
          return MaterialPageRoute(builder: (_) =>
              ProfilePage(userController.getAuthenticatedUser()));
        }
        break;
      case '/editProfile':
        if(userController != null) {
          return MaterialPageRoute(builder: (_) => EditProfilePage(
              userController: userController,
              authenticationApi: _authenticationApi
          ));
        }
        break;
      case '/createCalendar':
        if(calendarController != null) {
          return MaterialPageRoute(builder: (_) => NewCalendarPage(
              calendarController: calendarController
          ));
        }
        break;
      case '/settings':
        if(userController != null && holidayController != null) {
          return MaterialPageRoute(builder: (_) => SettingsPage(
            userController: userController,
            authenticationApi: _authenticationApi,
            holidayController: holidayController,
          ));
        }
        break;
    }

    return MaterialPageRoute(builder: (_) => _ErrorPage());
  }

  static Future<String> getSecuredVariable(SecureVariable variableKey) {
    return secureStorage.readVariable(variableKey);
  }

  static Future<void> setAuthToken(String authToken) async {
    await secureStorage.writeVariable(SecureVariable.authenticationToken, authToken);
    return;
  }

  static Future<ResponseCode> _initializeEssentialControllers(String loggedInUserID, {ValueNotifier<int>? progress}) async {
    if(_appState != AppState.initialising) {
      return ResponseCode.invalidAction;
    }

    UserController userController = UserController(_userApi);
    ResponseCode initUserController = await userController.initialize(loggedInUserID);
    if(initUserController != ResponseCode.success) {
      debugPrint("Initializing UserController failed with Code:$initUserController");
      return initUserController;
    }

    progress?.value = 70;

    CalendarController calendarController = CalendarController(_calendarApi, _authenticationApi, _eventApi, _calendarMemberApi, _noteApi);
    ResponseCode initCalendarController = await calendarController.initialize(userController.getAuthenticatedUser().id);
    if(initCalendarController != ResponseCode.success) {
      debugPrint("Initializing CalendarController failed with Code:$initCalendarController");
      return initCalendarController;
    }

    progress?.value = 95;

    for(Calendar calendar in calendarController.getCalendarMap().values) {
      for(CalendarMember member in calendar.calendarMemberController.getMemberList()) {
        await userController.getUser(member.userID);
      }
    }

    progress?.value = 96;

    HolidayController holidayController = HolidayController(_holidayApi);
    ResponseCode initHolidayController = await holidayController.initialize();
    if(initHolidayController != ResponseCode.success) {
      debugPrint("Initializing HolidayController failed with Code:$initHolidayController");
      return initHolidayController;
    }

    progress?.value = 98;

    BirthdayController birthdayController = BirthdayController(userController);
    ResponseCode initBirthdayController = await birthdayController.initialize();
    if(initBirthdayController != ResponseCode.success) {
      debugPrint("Initializing BirthdayController failed with Code:$initBirthdayController");
      return initHolidayController;
    }

    progress?.value = 99;

    _userController = userController;
    _calendarController = calendarController;
    _holidayController = holidayController;
    _birthdayController = birthdayController;

    return ResponseCode.success;
  }
}

enum AppState {
  loggedOut,
  connecting,
  authenticating,
  initialising,
  loggedIn,
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
                StateController.safeLogout();
                Navigator.pushNamedAndRemoveUntil(context, "/startup", (route) => false);
              },
              child: Text(
                  "<= Zurück",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Montserrat', fontSize: 20.0).copyWith(
                      color: Colors.white, fontSize: 18
                  )
              ),
            )
          ],
        ),
      ),
    );
  }
}