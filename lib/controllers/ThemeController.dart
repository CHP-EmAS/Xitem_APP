import 'package:xitem/controllers/SettingController.dart';
import 'package:flutter/material.dart';

enum XitemTheme { dark, light }

class AppTheme {
  AppTheme({
    required this.themeBrightness,
    required this.globalAccentColor,
    required this.globalCursorColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.cardColor,
    required this.cardInfoColor,
    required this.cardSmallInfoColor,
    required this.textColor,
    required this.iconColor,
    required this.actionButtonColor,
    required this.infoDialogBackgroundColor,
    required this.infoDialogTextColor,
    required this.menuPopupBackgroundColor,
    required this.menuPopupTextColor,
    required this.menuPopupIconColor,
    required this.headlineColor,
    required this.dividerColor
  });

  final Brightness themeBrightness;

  final Color globalAccentColor;
  final Color globalCursorColor;

  final Color backgroundColor;
  final Color foregroundColor;

  final Color cardColor;
  final Color cardInfoColor;
  final Color cardSmallInfoColor;

  final Color textColor;
  final Color iconColor;

  final Color actionButtonColor;

  final Color infoDialogBackgroundColor;
  final Color infoDialogTextColor;

  final Color menuPopupBackgroundColor;
  final Color menuPopupTextColor;
  final Color menuPopupIconColor;

  final Color headlineColor;
  final Color dividerColor;
}

class ThemeController {
  static final  AppTheme _lightTheme = AppTheme(
    themeBrightness: Brightness.light,
    globalAccentColor: Colors.amber,
    globalCursorColor: Colors.amber,
    backgroundColor: Colors.white,
    foregroundColor: Colors.blue,
    cardColor: const Color.fromARGB(255, 211, 211, 211),
    cardInfoColor: Colors.black,
    cardSmallInfoColor: Colors.grey[800]!,
    textColor: Colors.black,
    iconColor: Colors.black,
    actionButtonColor: Colors.amber,
    infoDialogBackgroundColor: Colors.white30,
    infoDialogTextColor: Colors.black,
    menuPopupBackgroundColor: Colors.black,
    menuPopupTextColor: Colors.white,
    menuPopupIconColor: Colors.white,
    headlineColor: Colors.grey,
    dividerColor: Colors.grey[800]!
  );

  static final AppTheme _darkTheme = AppTheme(
      themeBrightness: Brightness.dark,
      globalAccentColor: Colors.amber,
      globalCursorColor: Colors.amber,
      backgroundColor: Colors.grey.shade900,
      foregroundColor: const Color(0xFF303030),
      cardColor: const Color.fromARGB(255, 56, 56, 56),
      cardInfoColor: Colors.white,
      cardSmallInfoColor: Colors.grey,
      textColor: Colors.white,
      iconColor: Colors.white,
      actionButtonColor: Colors.amber,
      infoDialogBackgroundColor: Colors.grey.shade900,
      infoDialogTextColor: Colors.white,
      menuPopupBackgroundColor: Colors.white,
      menuPopupTextColor: Colors.black,
      menuPopupIconColor: Colors.black,
      headlineColor: Colors.grey,
      dividerColor: Colors.grey.shade800
  );

  static const List<Color> eventColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];
  static const int defaultEventColorIndex = 13;

  static const List<Color> noteColors = [
    Color(0xFFFFF476),
    Color(0xFFCDFF90),
    Color(0xFFA7FEEB),
    Color(0xFFCBF0F8),
    Color(0xFFAFCBFA),
    Color(0xFFD7AEFC),
    Color(0xFFFDCFE9),
    Color(0xFFE6C9A9),
    Color(0xFFF28C82),
    Color(0xFFE9EAEE),
  ];
  static const int defaultNoteColorIndex = 0;

  static const List<IconData> calendarIcons = [
    Icons.calendar_today,
    Icons.event,
    Icons.event_available,
    Icons.event_note,
    Icons.date_range,
    Icons.assignment_late,
    Icons.cake,
    Icons.favorite,
    Icons.favorite_border,
    Icons.star,
    Icons.star_border,
    Icons.all_inclusive,
    Icons.extension,
    Icons.cloud,
    Icons.filter_drama,
    Icons.filter_hdr,
    Icons.filter_vintage,
    Icons.whatshot,
    Icons.home,
    Icons.group,
    Icons.people_outline,
    Icons.directions_bike,
    Icons.directions_bus,
    Icons.directions_car,
    Icons.directions_railway,
    Icons.directions_boat,
    Icons.local_airport,
    Icons.hotel,
    Icons.ac_unit,
    Icons.brightness_2,
    Icons.wb_sunny,
    Icons.work,
    Icons.school,
    Icons.schedule,
    Icons.audiotrack,
    Icons.beach_access,
    Icons.fitness_center,
    Icons.pool,
    Icons.pets,
    Icons.alarm,
    Icons.android,
    Icons.build,
    Icons.camera,
    Icons.apps,
    Icons.blur_on,
    Icons.bubble_chart,
    Icons.dashboard,
    Icons.layers,
    Icons.equalizer,
    Icons.timeline,
    Icons.account_balance,
    Icons.euro_symbol,
    Icons.attach_money,
    Icons.check,
    Icons.done_outline,
    Icons.block,
    Icons.clear,
    Icons.lock,
    Icons.delete,
    Icons.priority_high,
    Icons.mood,
    Icons.create,
    Icons.call,
    Icons.email,
    Icons.business,
    Icons.language,
    Icons.attach_file,
    Icons.business_center,
    Icons.build,
    Icons.translate,
    Icons.child_friendly,
    Icons.flag,
    Icons.location_on,
    Icons.public,
    Icons.fingerprint,
    Icons.restaurant,
    Icons.fastfood,
    Icons.format_paint,
    Icons.color_lens,
    Icons.free_breakfast,
    Icons.explore,
    Icons.computer,
    Icons.power_settings_new,
    Icons.memory,
    Icons.headset,
    Icons.http,
    Icons.gamepad,
    Icons.videogame_asset,
    Icons.golf_course,
    Icons.local_movies,
    Icons.event_seat,
  ];
  static const int defaultCalendarIconIndex = 0;

  static AppTheme _currentTheme = _darkTheme;

  static void loadThemeFromSettings(SettingController settingController) {
    XitemTheme theme = settingController.getTheme();

    switch (theme) {
      case XitemTheme.light:
        _currentTheme = _lightTheme;
        break;
      case XitemTheme.dark:
      default:
        _currentTheme = _darkTheme;
        break;
    }
  }

  static AppTheme activeTheme() => _currentTheme;

  static Color getEventColor(int index) {
    if(index < eventColors.length) {
      return eventColors[index];
    }

    return Colors.amber;
  }

  static Color getNoteColor(int index) {
    if(index < noteColors.length) {
      return noteColors[index];
    }

    return const Color(0xFFFFF476);
  }

  static IconData getCalendarIcon(int index) {
    if(index < calendarIcons.length) {
      return calendarIcons[index];
    }

    return Icons.calendar_today;
  }
}
