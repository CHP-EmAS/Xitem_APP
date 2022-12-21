import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:xitem/api/AuthenticationApi.dart';
import 'package:xitem/api/CalendarApi.dart';
import 'package:xitem/api/CalendarMemberApi.dart';
import 'package:xitem/api/EventApi.dart';
import 'package:xitem/api/NoteApi.dart';
import 'package:xitem/controllers/CalendarMemberController.dart';
import 'package:xitem/controllers/EventController.dart';
import 'package:xitem/interfaces/CalendarApiInterfaces.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

import 'NoteController.dart';

class CalendarController {

  CalendarController(this._calendarApi, this._authenticationApi, this._eventApi, this._calendarMemberApi, this._noteApi);

  final CalendarApi _calendarApi;
  final AuthenticationApi _authenticationApi;
  final EventApi _eventApi;
  final CalendarMemberApi _calendarMemberApi;
  final NoteApi _noteApi;

  late final String _authenticatedUserID;

  final Map<String, Calendar> _calendarList = <String, Calendar>{};

  bool _isInitialized = false;

  Future<ResponseCode> initialize(String authenticatedUserID) async {
    if(_isInitialized) {
      return ResponseCode.invalidAction;
    }

    ResponseCode initialLoad = await _loadAllCalendars(authenticatedUserID);

    if(initialLoad != ResponseCode.success) {
      _resetControllerState();
      return initialLoad;
    }

    _authenticatedUserID = authenticatedUserID;

    _isInitialized = true;
    return ResponseCode.success;
  }

  Future<ResponseCode> _loadAllCalendars(String userID) async {
    print("Loading calendar list...");

    ApiResponse<List<LoadedCalendarData>> loadAllCalendars = await _calendarApi.loadAllCalendars(userID);

    if(loadAllCalendars.code == ResponseCode.success) {
      List<LoadedCalendarData>? loadedCalendarList = loadAllCalendars.value;

      if (loadedCalendarList != null) {
        _resetControllerState();

        for (final calendarData in loadedCalendarList) {
          String calendarId = calendarData.id;

          Calendar loadedCalendar = _createCalendarFromRawData(calendarData);

          ResponseCode initController = await _initControllerForCalendar(loadedCalendar, userID);
          if(initController != ResponseCode.success) {
            return initController;
          }

          _calendarList[calendarId] = loadedCalendar;
        }

        return ResponseCode.success;
      }
    }

    return loadAllCalendars.code;
  }

  Future<ApiResponse<Calendar>> _loadCalendar(String calendarID) async {
    ApiResponse<LoadedCalendarData> loadCalendarData = await _calendarApi.loadSingleCalendar(calendarID);
    LoadedCalendarData? calendarData = loadCalendarData.value;

    if(loadCalendarData.code != ResponseCode.success) {
      return ApiResponse(loadCalendarData.code);
    } else if(calendarData == null) {
      return ApiResponse(ResponseCode.unknown);
    }

    Calendar loadedCalendar = _createCalendarFromRawData(calendarData);

    ResponseCode initController = await _initControllerForCalendar(loadedCalendar, _authenticatedUserID);
    if(initController != ResponseCode.success) {
      return ApiResponse(initController);
    }

    _calendarList[loadedCalendar.id] = loadedCalendar;

    return ApiResponse(ResponseCode.success, loadedCalendar);
  }

  Future<ResponseCode> reloadCalendar(String calendarID) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    ApiResponse<Calendar> reloadCalendar = await _loadCalendar(calendarID);

    return reloadCalendar.code;
  }

  Future<ApiResponse<String>> createCalendar(String name, String password, bool canJoin, int color, IconData icon) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    ApiResponse<String> createCalendar = await _calendarApi.createCalendar(CreateCalendarRequest(name, password, canJoin, color, icon));
    String? calendarID = createCalendar.value;

    if(createCalendar.code != ResponseCode.success) {
      return ApiResponse(createCalendar.code);
    } else if(calendarID == null) {
      return ApiResponse(ResponseCode.unknown);
    }

    ApiResponse<Calendar> loadCalendar = await _loadCalendar(calendarID);
    Calendar? newCalendar = loadCalendar.value;

    if(loadCalendar.code != ResponseCode.success) {
      return ApiResponse(loadCalendar.code);
    } else if(newCalendar == null) {
      return ApiResponse(ResponseCode.unknown);
    }

    return ApiResponse(ResponseCode.success, "${newCalendar.name}#${newCalendar.hash}");
  }

  Future<ResponseCode> joinCalendar(String hashName, String password, int color, IconData icon) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    ApiResponse<String> joinCalendar = await _calendarApi.joinCalendar(hashName, JoinCalendarRequest(password, color, icon));
    String? calendarID = joinCalendar.value;

    if(joinCalendar.code != ResponseCode.success) {
      return joinCalendar.code;
    } else if(calendarID == null) {
      return ResponseCode.unknown;
    }

    ApiResponse<Calendar> loadCalendar = await _loadCalendar(calendarID);

    if(loadCalendar.code != ResponseCode.success) {
      return loadCalendar.code;
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> acceptCalendarInvitation(String invToken, int color, IconData icon) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    ApiResponse<String> acceptInv = await _calendarApi.acceptCalendarInvitationToken(AcceptCalendarInvitationRequest(invToken, color, icon));
    String? calendarID = acceptInv.value;

    if(acceptInv.code != ResponseCode.success) {
      return acceptInv.code;
    } else if(calendarID == null) {
      return ResponseCode.unknown;
    }

    ApiResponse<Calendar> loadCalendar = await _loadCalendar(calendarID);

    if(loadCalendar.code != ResponseCode.success) {
      return loadCalendar.code;
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> deleteCalendar(String calendarID, String userPassword) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    if(await _authenticationApi.checkHashPassword(userPassword) != ResponseCode.success) {
      return ResponseCode.wrongPassword;
    }

    ResponseCode deleteCalendar = await _calendarApi.deleteCalendar(calendarID);

    if(deleteCalendar != ResponseCode.success) {
      return deleteCalendar;
    }

    _calendarList.remove(calendarID);

    return ResponseCode.success;
  }

  Future<ResponseCode> leaveCalendar(String calendarID, String userPassword) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    if(await _authenticationApi.checkHashPassword(userPassword) != ResponseCode.success) {
      return ResponseCode.wrongPassword;
    }

    ResponseCode leaveCalendar = await _calendarApi.leaveCalendar(calendarID, _authenticatedUserID);

    if(leaveCalendar != ResponseCode.success) {
      return leaveCalendar;
    }

    _calendarList.remove(calendarID);

    return ResponseCode.success;
  }

  Future<ResponseCode> changeCalendarLayout(String calendarID, int color, IconData icon) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    ResponseCode patchLayout = await _calendarApi.patchCalendarLayout(calendarID, PatchCalendarLayoutRequest(color, icon));
    if (patchLayout != ResponseCode.success) {
      return patchLayout;
    }

    ApiResponse<Calendar> loadCalendar = await _loadCalendar(calendarID);
    if(loadCalendar.code != ResponseCode.success) {
      return loadCalendar.code;
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> changeCalendarInformation(String calendarID, String name, bool canJoin, String? password) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    if (password == "") password = null;

    ResponseCode patchCalendar = await _calendarApi.patchCalendar(calendarID, PatchCalendarRequest(name, canJoin, password));
    if (patchCalendar != ResponseCode.success) {
      return patchCalendar;
    }

    ApiResponse<Calendar> loadCalendar = await _loadCalendar(calendarID);
    if(loadCalendar.code != ResponseCode.success) {
      return loadCalendar.code;
    }

    return ResponseCode.success;
  }

  Future<ApiResponse<String>> getInvitationToken(String calendarID, bool canCreateEvents, bool canEditEvents, int duration) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    ApiResponse getInvToken = await _calendarApi.getCalendarInvitationToken(calendarID, CalendarInvitationTokenRequest(canCreateEvents, canEditEvents, duration));
    String? invToken = getInvToken.value;

    if(getInvToken.code != ResponseCode.success) {
      return ApiResponse(getInvToken.code);
    } else if(invToken == null) {
      return ApiResponse(ResponseCode.unknown);
    }

    return ApiResponse(ResponseCode.success, invToken);
  }

  Map<String, Calendar> getCalendarMap() {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    return _calendarList;
  }

  Calendar? getCalendar(String calendarID) {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    return _calendarList[calendarID];
  }

  List<Event> combineAllEvents() {
    if(!_isInitialized) {
      throw AssertionError("CalendarController must be initialized before it can be accessed!");
    }

    List<Event> combinedList = [];

    _calendarList.forEach((id, calendar) {
      combinedList.addAll(calendar.eventController.getLoadedEvents());
    });

    return combinedList;
  }

  Calendar _createCalendarFromRawData(LoadedCalendarData data) {
    EventController newEventController = EventController(_eventApi);
    CalendarMemberController newCalendarMemberController = CalendarMemberController(_calendarMemberApi, _authenticationApi);
    NoteController newNoteController = NoteController(_noteApi);

    return Calendar(
        eventController: newEventController,
        calendarMemberController: newCalendarMemberController,
        noteController: newNoteController,
        id: data.id,
        fullName: data.fullName,
        canJoin: data.canJoin,
        creationDate: data.creationDate,
        color: data.color,
        icon: data.icon
    );
  }

  Future<ResponseCode> _initControllerForCalendar(Calendar calendarToInitialize, String authenticatedUserID) async {
    ResponseCode initEvent = await calendarToInitialize.eventController.initialize(calendarToInitialize);
    if(initEvent != ResponseCode.success) {

      return initEvent;
    }

    ResponseCode initMember = await calendarToInitialize.calendarMemberController.initialize(calendarToInitialize.id, authenticatedUserID);
    if(initMember != ResponseCode.success) {
      return initMember;
    }

    ResponseCode initNote = await calendarToInitialize.noteController.initialize(calendarToInitialize.id);
    if(initNote != ResponseCode.success) {
      return initNote;
    }

    return ResponseCode.success;
  }

  void _resetControllerState() {
    _calendarList.clear();
    //_votingControllerList.clear();
    _isInitialized = false;
  }
}