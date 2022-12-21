import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:xitem/api/EventApi.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/models/EventMonth.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class EventController {

  EventController(this._eventApi);

  static const initialPastRange = 2;
  static const initialFutureRange = 8;
  static const monthlyOverhangRange = Duration(days: 0);

  final EventApi _eventApi;

  late final Calendar _relatedCalendar;
  bool _isInitialized = false;

  final Map<BigInt, Event> _dynamicEventMap = <BigInt, Event>{};
  final Map<String, EventMonth> _dynamicMonthMap = <String, EventMonth>{};

  Future<ResponseCode> initialize(Calendar relatedCalendar) async {
    if(_isInitialized) {
      return ResponseCode.invalidAction;
    }

    _relatedCalendar = relatedCalendar;

    ResponseCode initialLoad = await _loadInitialEventRange();

    if(initialLoad != ResponseCode.success) {
      _resetControllerState();
      return initialLoad;
    }

    _isInitialized = true;
    return ResponseCode.success;
  }

  //Event functions
  Future<ResponseCode> _loadInitialEventRange() async {
    DateTime now = DateTime.now();

    DateTime rangeStart = DateTime(now.year, now.month - initialPastRange, 1).subtract(monthlyOverhangRange);
    DateTime rangeEnd = DateTime(now.year, now.month + initialFutureRange, 1).add(monthlyOverhangRange);

    ApiResponse<List<Event>> loadEventRange = await _eventApi.loadEvents(_relatedCalendar.id, rangeStart, rangeEnd);
    List<Event>? loadedEvents = loadEventRange.value;

    if (loadEventRange.code != ResponseCode.success) {
      return loadEventRange.code;
    } else if (loadedEvents == null) {
      return ResponseCode.unknown;
    }

    for (int loadedMonth = -initialPastRange; loadedMonth < initialFutureRange; loadedMonth++) {
      DateTime newMonth = DateTime(now.year, now.month + loadedMonth);

      String monthlyKey = _generateMonthlyKey(newMonth.year, newMonth.month);
      _dynamicMonthMap[monthlyKey] = EventMonth(newMonth.year, newMonth.month, _relatedCalendar);
    }

    for (var event in loadedEvents) {
      _dynamicEventMap[event.eventID] = event;

      List<String> monthlyKeys = _getMonthlySpan(event);

      for(String monthlyKey in monthlyKeys) {
        if(_dynamicMonthMap.containsKey(monthlyKey)) {
          _dynamicMonthMap[monthlyKey]!.addOrReplaceEvent(event);
        }
      }
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> loadEventsInMonth(DateTime month) async {
    DateTime rangeStart = DateTime(month.year, month.month, 1).subtract(monthlyOverhangRange);
    DateTime rangeEnd = DateTime(month.year, month.month + 1, -1).add(monthlyOverhangRange);

    ApiResponse<List<Event>> loadEventRange = await _eventApi.loadEvents(_relatedCalendar.id, rangeStart, rangeEnd);
    List<Event>? loadedEvents = loadEventRange.value;

    if (loadEventRange.code != ResponseCode.success) {
      return loadEventRange.code;
    } else if (loadedEvents == null) {
      return ResponseCode.unknown;
    }

    String monthlyKey = _generateMonthlyKey(month.year, month.month);
    _dynamicMonthMap[monthlyKey] = EventMonth(month.year, month.month, _relatedCalendar);

    for (var event in loadedEvents) {
      _dynamicEventMap[event.eventID] = event;

      if(_dynamicMonthMap.containsKey(monthlyKey)) {
        _dynamicMonthMap[monthlyKey]!.addOrReplaceEvent(event);
      }
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> loadEvent(BigInt eventID) async {
    if(!_isInitialized) {
      throw AssertionError("EventController must be initialized before it can be accessed!");
    }

    ApiResponse<Event> loadEvent = await _eventApi.loadSingleEvent(_relatedCalendar.id, eventID);
    Event? event = loadEvent.value;

    if (loadEvent.code != ResponseCode.success) {
      return loadEvent.code;
    } else if (event == null) {
      return ResponseCode.unknown;
    }

    _dynamicEventMap[event.eventID] = event;

    _removeAllUiEvents(event.eventID);

    List<String> monthlyKeys = _getMonthlySpan(event);
    for(String monthlyKey in monthlyKeys) {
      if(_dynamicMonthMap.containsKey(monthlyKey)) {
        _dynamicMonthMap[monthlyKey]!.addOrReplaceEvent(event);
      }
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> createEvent(EventData newEvent) async {
    if(!_isInitialized) {
      throw AssertionError("EventController must be initialized before it can be accessed!");
    }

    ApiResponse<BigInt> createEvent = await _eventApi.createEvent(_relatedCalendar.id, CreateEventRequest(newEvent.startDate, newEvent.endDate, newEvent.title, newEvent.daylong, newEvent.description, newEvent.color));
    BigInt? newEventID = createEvent.value;

    if (createEvent.code != ResponseCode.success) {
      return createEvent.code;
    } else if (newEventID == null) {
      return ResponseCode.unknown;
    }

    return loadEvent(newEventID);
  }

  Future<ResponseCode> editEvent(BigInt eventID, DateTime newStartDate, DateTime newEndDate, String newTitle, String newDescription, bool dayLong, int newColor) async {
    if(!_isInitialized) {
      throw AssertionError("EventController must be initialized before it can be accessed!");
    }

    ResponseCode patchEvent = await _eventApi.patchEvent(_relatedCalendar.id, eventID, PatchEventRequest(newStartDate, newEndDate, newTitle, dayLong, newDescription, newColor));

    if (patchEvent != ResponseCode.success) {
      return patchEvent;
    }

    return loadEvent(eventID);
  }

  Future<ResponseCode> removeEvent(BigInt eventToRemove) async {
    if(!_isInitialized) {
      throw AssertionError("EventController must be initialized before it can be accessed!");
    }

    ResponseCode deleteEvent = await _eventApi.deleteEvent(_relatedCalendar.id, eventToRemove);

    if (deleteEvent != ResponseCode.success) {
      return deleteEvent;
    }

    _dynamicEventMap.remove(eventToRemove);
    _removeAllUiEvents(eventToRemove);

    return ResponseCode.success;
  }

  Event? getEvent(BigInt eventID) {
    if(!_isInitialized) {
      throw AssertionError("EventController must be initialized before it can be accessed!");
    }

    return _dynamicEventMap[eventID];
  }

  List<Event> getLoadedEvents() {
    if(!_isInitialized) {
      throw AssertionError("EventController must be initialized before it can be accessed!");
    }

   return _dynamicEventMap.values.toList();
  }

  bool isEventMonthLoaded(DateTime month) {
    String monthlyKey = _generateMonthlyKey(month.year, month.month);
    return _dynamicMonthMap.containsKey(monthlyKey);
  }

  List<UiEvent> getUiEventsForDay(DateTime day) {
    String monthlyKey = _generateMonthlyKey(day.year, day.month);
    return _dynamicMonthMap[monthlyKey]?.getUiEventsByDay(day) ?? [];
  }

  List<String> _getMonthlySpan(Event event) {
    DateTime startDayWithOverhang = event.start.subtract(monthlyOverhangRange);
    DateTime endDayWithOverhang = event.end.add(monthlyOverhangRange);

    int startYearMonth = 12 * startDayWithOverhang.year + startDayWithOverhang.month - 1;
    int endYearMonth = 12 * endDayWithOverhang.year + endDayWithOverhang.month - 1;

    List<String> monthlyKeys = <String>[];
    for(int ym = startYearMonth; ym <= endYearMonth; ym++) {
      monthlyKeys.add(_generateMonthlyKey(ym~/12, (ym%12)+1));
    }

    return monthlyKeys;
  }

  String _generateMonthlyKey(int year, int month) {
    return year.toString() + month.toString();
  }

  void _removeAllUiEvents(BigInt eventID) {
    for(EventMonth month in _dynamicMonthMap.values) {
      month.removeUiEventById(eventID);
    }
  }

  void _resetControllerState() {
    _dynamicEventMap.clear();
    _dynamicMonthMap.clear();
    _isInitialized = false;
  }

}