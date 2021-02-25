import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/HolidayListController.dart';
import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/SettingController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Settings/locator.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/Dialogs/picker_popups.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class SettingsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final NavigationService _navigationService = locator<NavigationService>();

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool settingsLoaded = false;

  tz.Location _timeZone;
  StateCode _holidayStateCode;

  Color _eventStandardColor;

  bool _showBirthdaysOnHolidayScreen;
  bool _showNewVotingOnEventScreen;


  void loadSettings() async {
    setState(() {
      settingsLoaded = false;
    });

    _timeZone = await SettingController.getTimeZone();
    _holidayStateCode = await SettingController.getHolidayStateCode();
    _eventStandardColor = await SettingController.getEventStandardColor();
    _showBirthdaysOnHolidayScreen = await SettingController.getShowBirthdaysOnHolidayScreen();
    _showNewVotingOnEventScreen = await SettingController.getShowNewVotingOnEventScreen();

    setState(() {
      settingsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            _navigationService.pop();
          },
        ),
        title: Text(
          "Einstellungen",
          style: TextStyle(
            color: ThemeController.activeTheme().textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        elevation: 3,
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: settingsLoaded ? ListView(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          children: <Widget>[
            buildHeadline("Allgemein"),
            buildSetting(Icon(Icons.public, size: 30,), "Zeitzone", _timeZone.name, () => changeTimezone()),
            buildSetting(Icon(Icons.location_pin, size: 30,), "Bundesland für Feiertage", HolidayController.getStateName(_holidayStateCode), () => changeHolidayStateCode()),
            SizedBox(height: 18,),

            buildHeadline("Erscheinungsbild"),
            buildSetting(Icon(Icons.circle, size: 30, color: _eventStandardColor,), "Statndart-Farbe für neue Events", "", (() async {
              Color newColor = await PickerPopup.showColorPickerDialog(_eventStandardColor);

              if(newColor != null) {
                await SettingController.setEventStandardColor(newColor);
                _eventStandardColor = SettingController.getEventStandardColor();
                setState(() {});
              }
            })),
            buildSwitchSetting(Icon(Icons.cake, size: 30,), "Zeige Geburstage von anderen Mitgliedern", _showBirthdaysOnHolidayScreen, (value) async {
              await SettingController.setShowBirthdaysOnHolidayScreen(value);
              _showBirthdaysOnHolidayScreen = SettingController.getShowBirthdaysOnHolidayScreen();
              setState(() {});
            }),
            buildSwitchSetting(Icon(Icons.how_to_vote, size: 30,), "Zeige neue Abstimmung im Home Bereich", _showNewVotingOnEventScreen, (value) async {
              await SettingController.setShowNewVotingOnEventScreen(value);
              _showNewVotingOnEventScreen = SettingController.getShowNewVotingOnEventScreen();
              setState(() {});
            }),
            SizedBox(height: 18,),

            buildHeadline("Profil"),
            buildSetting(Icon(Icons.info_outline, size: 30, color: Colors.blue,), "Profildaten anfordern", "", (() {
              sendProfileInformationMail();
            })),
            buildSetting(Icon(Icons.delete, size: 30, color: Colors.red,), "Profil Löschung anfordern", "", (() {
              sendProfileDeletionMail();
            })),
            SizedBox(height: 18,),

            buildHeadline("App Info"),
            SizedBox(height: 15,),
            SizedBox(
              height: 80.0,
              child: Image.asset(
                "images/logo_hell.png",
                fit: BoxFit.contain,
              ),
            ),
            Center(
                child: Text("Version: " + Api.appVersion, style: TextStyle(fontWeight: FontWeight.w800),)
            ),
            Center(
                child: Text("API: " + Api.apiName + " " + Api.apiVersion, style: TextStyle(fontWeight: FontWeight.w800),)
            ),
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Clemens Hübner ", style: TextStyle(fontSize: 12),),
                Text("©2021", style: TextStyle(color: Colors.amber, fontSize: 12),),
              ],
            ),
            SizedBox(height: 30,),
          ]
      ) : Center(),
    );
  }

  Widget buildHeadline(String text) {
    return Text(
      text,
      style: TextStyle(
          color: Colors.amber,
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 1
      ),
    );
  }

  Widget buildSetting(Icon leadingIcon, String titleText, String currentSelectionText, Function() onTap) {

    return  Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 1,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leadingIcon,
          title: Text(titleText),
          trailing: Text(currentSelectionText),
          onTap: () => onTap?.call(),
        ),
      ),
    );
  }

  Widget buildSwitchSetting(Icon leadingIcon, String titleText, bool value, Function(bool) onChanged) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 1,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leadingIcon,
          title: Text(titleText),
          trailing: Checkbox(
            value: value,
            onChanged: (value) => onChanged?.call(value),
          ),
        ),
      ),
    );
  }

  void changeTimezone() async {
    tz.Location newLocation = await PickerPopup.showTimezonePickerDialog(_timeZone);

    GlobalKey<State> _keyLoader = new GlobalKey<State>();

    if(newLocation != null) {
      await SettingController.setTimeZone(newLocation);
      _timeZone = SettingController.getTimeZone();

      DialogPopup.asyncLoadingDialog(_keyLoader, "Konvertiere Termine...");

      bool success = await UserController.loadAllCalendars().catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!success) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        DialogPopup.asyncOkDialog("Termine konnten nicht konvertiert werden!", Api.errorMessage);
      } else {
        setState(() {});
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      }
    }
  }

  void changeHolidayStateCode() async {
    StateCode newStateCode = await PickerPopup.showStateCodePickerDialog(_holidayStateCode);

    GlobalKey<State> _keyLoader = new GlobalKey<State>();

    if (newStateCode != null) {
      await SettingController.setHolidayStateCode(newStateCode);
      _holidayStateCode = SettingController.getHolidayStateCode();

      DialogPopup.asyncLoadingDialog(_keyLoader, "Lade Feiertage...");

      bool success = await HolidayController.loadPublicHolidays().catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!success) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        DialogPopup.asyncOkDialog("Feiertage konnten nicht geladen werden!", Api.errorMessage);
      } else {
        setState(() {});
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      }
    }
  }

  void sendProfileInformationMail() async {
    final answer = await DialogPopup.asyncConfirmDialog("Profildaten anfordern?", "Hier kannst du alle Daten die Xitem über dich gespeichert hat anfordern. Die Daten werden dir per Mail an\n" + UserController.user.email + "\ngesendet. Möchtest du fortfahren?");

    if (answer == ConfirmAction.OK) {
      final password = await DialogPopup.asyncPasswordDialog();

      if (password != "" && password != null) {
        if (await Api.requestProfileInformationEmail(UserController.user.userID, password)) {
          DialogPopup.asyncOkDialog("Email gesendet", "Email wurde erfolgreich gesendet! ♥");
        } else {
          DialogPopup.asyncOkDialog("Email konnte nicht gesendet werden!", Api.errorMessage);
        }
      }
    }
  }

  void sendProfileDeletionMail() async {
    final answer = await DialogPopup.asyncConfirmDialog(
        "Profil löschen?",
        "Hier kannst du dein Xitem Account löschen. Nach der Löschung kann dein Account nicht mehr wiederhergestellt werden. Die Löschung muss per Mail bestätigt werden. Wir senden die Mail an\n" + UserController.user.email + "\nMöchtest du fortfahren?");

    if (answer == ConfirmAction.OK) {
      final password = await DialogPopup.asyncPasswordDialog();

      if (password != "" && password != null) {
        if (await Api.requestProfileDeletionEmail(UserController.user.userID, password)) {
          DialogPopup.asyncOkDialog("Email gesendet", "Email wurde erfolgreich gesendet! ♥");
        } else {
          DialogPopup.asyncOkDialog("Email konnte nicht gesendet werden!", Api.errorMessage);
        }
      }
    }
  }
}
