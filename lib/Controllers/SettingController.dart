import 'package:de/Controllers/HolidayListController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class SettingController {
  static SharedPreferences _prefs;

  static final String _appThemeKey = "appThemeKey";
  static final String _timezoneKey = "timezoneKey";
  static final String _holidayStateCodeKey = "holidayStateCodeKey";
  static final String _eventStandardColorKey = "eventStandardColorKey";
  static final String _showNewVotingOnEventScreenKey = "showNewVotingOnEventScreenKey";
  static final String _showBirthdaysOnHolidayScreenKey = "showBirthdaysOnHolidayScreenKey";

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static XitemTheme getTheme() {
    String storedTheme = _prefs.getString(_appThemeKey) ?? "dark";

    return storedTheme == "light" ? XitemTheme.Light : XitemTheme.Dark;
  }

  static Future<bool> setTheme(XitemTheme theme) async {
    String storedTheme = "dark";
    if (theme == XitemTheme.Light) storedTheme = "light";

    return await _prefs.setString(_appThemeKey, storedTheme);
  }

  static tz.Location getTimeZone() {
    String storedTimeZone = _prefs.get(_timezoneKey) ?? "Europe/Berlin";

    if (tz.timeZoneDatabase.locations.containsKey(storedTimeZone)) return tz.getLocation(storedTimeZone);

    return tz.getLocation("Europe/Berlin");
  }

  static Future<bool> setTimeZone(tz.Location timeZone) async {
    return await _prefs.setString(_timezoneKey, timeZone.name);
  }

  static StateCode getHolidayStateCode() {
    String storedHolidayStateCode = _prefs.get(_holidayStateCodeKey) ?? "BW";

    switch (storedHolidayStateCode) {
      case "BW":
        return StateCode.BW;
      case "BY":
        return StateCode.BY;
      case "BE":
        return StateCode.BE;
      case "BB":
        return StateCode.BB;
      case "HB":
        return StateCode.HB;
      case "HH":
        return StateCode.HH;
      case "HE":
        return StateCode.HE;
      case "MV":
        return StateCode.MV;
      case "NI":
        return StateCode.NI;
      case "NW":
        return StateCode.NW;
      case "RP":
        return StateCode.RP;
      case "SL":
        return StateCode.SL;
      case "SN":
        return StateCode.SN;
      case "ST":
        return StateCode.ST;
      case "SH":
        return StateCode.SH;
      case "TH":
        return StateCode.TH;
      default:
        return StateCode.BW;
    }
  }

  static Future<bool> setHolidayStateCode(StateCode stateCode) async {
    return await _prefs.setString(_holidayStateCodeKey, HolidayController.getStateCode(stateCode));
  }

  static Color getEventStandardColor()  {
    int storedEventStandardColor = _prefs.getInt(_eventStandardColorKey) ?? Colors.amber.value;

    return Color(storedEventStandardColor);
  }

  static Future<bool> setEventStandardColor(Color color) async {
    return await _prefs.setInt(_eventStandardColorKey, color.value);
  }

  static bool getShowNewVotingOnEventScreen() {
    bool showNewVotingOnEventScreen = _prefs.getBool(_showNewVotingOnEventScreenKey) ?? true;

    return showNewVotingOnEventScreen;
  }

  static Future<bool> setShowNewVotingOnEventScreen(bool show) async {
    return await _prefs.setBool(_showNewVotingOnEventScreenKey, show);
  }

  static bool getShowBirthdaysOnHolidayScreen()  {
    bool showNewVotingOnEventScreen = _prefs.getBool(_showBirthdaysOnHolidayScreenKey) ?? true;

    return showNewVotingOnEventScreen;
  }

  static Future<bool> setShowBirthdaysOnHolidayScreen(bool show) async {
    return await _prefs.setBool(_showBirthdaysOnHolidayScreenKey, show);
  }
}
