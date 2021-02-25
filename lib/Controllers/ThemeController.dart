import 'package:de/Controllers/SettingController.dart';
import 'package:flutter/material.dart';

enum XitemTheme { Dark, Light }

class AppTheme {
  AppTheme(
      this.themeBrightness,
      this.globalAccentColor,
      this.globalCursorColor,
      this.backgroundColor,
      this.foregroundColor,
      this.cardColor,
      this.cardInfoColor,
      this.cardSmallInfoColor,
      this.textColor,
      this.iconColor,
      this.actionButtonColor,
      this.infoDialogBackgroundColor,
      this.infoDialogTextColor,
      this.menuPopupBackgroundColor,
      this.menuPopupTextColor,
      this.menuPopupIconColor,
      this.headlineColor,
      this.dividerColor);

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
  static final AppTheme _lightTheme = new AppTheme(Brightness.light, Colors.amber, Colors.amber, Colors.white, Colors.blue, Color.fromARGB(255, 211, 211, 211), Colors.black, Colors.grey[800],
      Colors.black, Colors.black, Colors.amber, Colors.white30, Colors.black, Colors.black, Colors.white, Colors.white, Colors.grey, Colors.grey[800]);

  static final AppTheme _darkTheme = new AppTheme(Brightness.dark, Colors.amber, Colors.amber, Colors.grey[900], Colors.grey[850], Color.fromARGB(255, 56, 56, 56), Colors.white, Colors.grey,
      Colors.white, Colors.white, Colors.amber, Colors.grey[900], Colors.white, Colors.white, Colors.black, Colors.black, Colors.grey, Colors.grey[800]);

  static AppTheme _currentTheme = _darkTheme;

  static void loadThemeFromSettings() {
    XitemTheme theme = SettingController.getTheme();

    switch (theme) {
      case XitemTheme.Light:
        _currentTheme = _lightTheme;
        break;
      case XitemTheme.Dark:
      default:
        _currentTheme = _darkTheme;
        break;
    }
  }

  static AppTheme activeTheme() => _currentTheme;
}
