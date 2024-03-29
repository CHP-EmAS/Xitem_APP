import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/utils/StateCodeConverter.dart';

class SettingController {
  late final SharedPreferences _prefs;

  static const String _appThemeKey = "appThemeKey";
  static const String _timezoneKey = "timezoneKey";
  static const String _holidayStateCodeKey = "holidayStateCodeKey";
  static const String _eventStandardColorKey = "eventStandardColorKey";
  static const String _showBirthdaysInCalendarScreenKey = "showBirthdaysInCalendarScreenKey";
  static const String _showHolidaysInCalendarScreenKey = "showHolidaysInCalendarScreenKey";

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  XitemTheme getTheme() {
    String storedTheme = _prefs.getString(_appThemeKey) ?? "dark";

    return storedTheme == "light" ? XitemTheme.light : XitemTheme.dark;
  }

  Future<bool> setTheme(XitemTheme theme) async {
    String storedTheme = "dark";
    if (theme == XitemTheme.light) storedTheme = "light";

    return await _prefs.setString(_appThemeKey, storedTheme);
  }

  tz.Location getTimeZone() {
    String storedTimeZone = _prefs.getString(_timezoneKey) ?? "Europe/Berlin";

    if (tz.timeZoneDatabase.locations.containsKey(storedTimeZone)) return tz.getLocation(storedTimeZone);

    return tz.getLocation("Europe/Berlin");
  }

  Future<bool> setTimeZone(tz.Location timeZone) async {
    return await _prefs.setString(_timezoneKey, timeZone.name);
  }

  StateCode getHolidayStateCode() {
    String storedHolidayStateCode = _prefs.getString(_holidayStateCodeKey) ?? "hh";
    return StateCodeConverter.getStateCode(storedHolidayStateCode);
  }

  Future<bool> setHolidayStateCode(StateCode stateCode) async {
    return await _prefs.setString(_holidayStateCodeKey, StateCodeConverter.getStateCodeString(stateCode));
  }

  int getEventStandardColor() {
    return _prefs.getInt(_eventStandardColorKey) ?? ThemeController.defaultEventColorIndex;
  }

  Future<bool> setEventStandardColor(int color) async {
    return await _prefs.setInt(_eventStandardColorKey, color);
  }

  bool getShowBirthdaysInCalendarScreen() {
    bool showNewVotingOnEventScreen = _prefs.getBool(_showBirthdaysInCalendarScreenKey) ?? true;

    return showNewVotingOnEventScreen;
  }

  Future<bool> setShowBirthdaysInCalendarScreen(bool show) async {
    return await _prefs.setBool(_showBirthdaysInCalendarScreenKey, show);
  }

  bool getShowHolidaysInCalendarScreen() {
    bool showNewVotingOnEventScreen = _prefs.getBool(_showHolidaysInCalendarScreenKey) ?? true;

    return showNewVotingOnEventScreen;
  }

  Future<bool> setShowHolidaysInCalendarScreen(bool show) async {
    return await _prefs.setBool(_showHolidaysInCalendarScreenKey, show);
  }
}
