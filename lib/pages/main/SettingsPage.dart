import 'package:xitem/api/AuthenticationApi.dart';
import 'package:xitem/controllers/HolidayController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/controllers/UserController.dart';
import 'package:xitem/main.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/StateCodeConverter.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';
import 'package:xitem/widgets/dialogs/PickerDialog.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.holidayController, required this.userController, required this.authenticationApi});

  final HolidayController holidayController;
  final UserController userController;
  final AuthenticationApi authenticationApi;
  
  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  bool settingsLoaded = false;

  late tz.Location _timeZone;
  late StateCode _holidayStateCode;

  late int _eventStandardColor;

  late bool _showBirthdaysInCalendar;
  late bool _showHolidaysInCalendar;

  String _apiVersion = "Lade...";

  @override
  void initState() {
    _loadSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            StateController.navigatorKey.currentState?.pop();
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
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          children: <Widget>[
            _buildHeadline("Allgemein"),
            _buildSetting(const Icon(Icons.public, size: 30,), "Zeitzone", _timeZone.name, () => _changeTimezone()),
            _buildSetting(const Icon(Icons.location_pin, size: 30,), "Bundesland für Feiertage", StateCodeConverter.getStateName(_holidayStateCode), () => _changeHolidayStateCode()),
            const SizedBox(height: 18,),

            _buildHeadline("Erscheinungsbild"),
            _buildSetting(Icon(Icons.circle, size: 30, color: ThemeController.getEventColor(_eventStandardColor),), "Standard-Farbe für neue Termine", "", (() async {
              int? newColor = await PickerDialog.eventColorPickerDialog(initialColor: _eventStandardColor);

              if(newColor != null) {
                await Xitem.settingController.setEventStandardColor(newColor);
                setState(() {
                  _eventStandardColor = Xitem.settingController.getEventStandardColor();
                });
              }
            })),
            _buildSwitchSetting(const Icon(Icons.visibility, size: 30,), "Zeige Geburtstage im Kalender an", _showBirthdaysInCalendar, (value) async {
              await Xitem.settingController.setShowBirthdaysInCalendarScreen(value);
              setState(() {
                _showBirthdaysInCalendar = Xitem.settingController.getShowBirthdaysInCalendarScreen();
              });
            }),
            _buildSwitchSetting(const Icon(Icons.visibility, size: 30,), "Zeige Feiertage im Kalender an", _showHolidaysInCalendar, (value) async {
              await Xitem.settingController.setShowHolidaysInCalendarScreen(value);
              setState(() {
                _showHolidaysInCalendar = Xitem.settingController.getShowHolidaysInCalendarScreen();
              });
            }),
            const SizedBox(height: 18,),
            _buildHeadline("Profil"),
            _buildSetting(const Icon(Icons.info_outline, size: 30, color: Colors.blue,), "Profildaten anfordern", "", (() {
              _sendProfileInformationMail();
            })),
            _buildSetting(const Icon(Icons.delete, size: 30, color: Colors.red,), "Profil Löschung anfordern", "", (() {
              _sendProfileDeletionMail();
            })),
            const SizedBox(height: 18,),
            _buildHeadline("App Info"),
            const SizedBox(height: 15,),
            SizedBox(
              height: 80.0,
              child: Image.asset(
                "images/logo_hell.png",
                fit: BoxFit.contain,
              ),
            ),
            const Center(
                child: Text("Version: ${Xitem.appVersion}", style: TextStyle(fontWeight: FontWeight.w800))
            ),
            Center(
                child: Text("API: $_apiVersion", style: const TextStyle(fontWeight: FontWeight.w800))
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text("Clemens Hübner ", style: TextStyle(fontSize: 12),),
                Text("©2023", style: TextStyle(color: Colors.amber, fontSize: 12),),
              ],
            ),
            const SizedBox(height: 30,),
          ]
      ) : const Center(),
    );
  }

  Widget _buildHeadline(String text) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.amber,
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 1
      ),
    );
  }

  Widget _buildSetting(Icon leadingIcon, String titleText, String currentSelectionText, Function() onTap) {
    return  Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
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
          onTap: () => onTap.call(),
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(Icon leadingIcon, String titleText, bool value, Function(bool) onChanged) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
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
            onChanged: (value) => onChanged.call(value ?? false),
          ),
        ),
      ),
    );
  }

  void _loadSettings() async {
    setState(() {
      settingsLoaded = false;
    });

    _timeZone = Xitem.settingController.getTimeZone();
    _holidayStateCode = Xitem.settingController.getHolidayStateCode();
    _eventStandardColor = Xitem.settingController.getEventStandardColor();
    _showBirthdaysInCalendar = Xitem.settingController.getShowBirthdaysInCalendarScreen();
    _showHolidaysInCalendar = Xitem.settingController.getShowHolidaysInCalendarScreen();

    widget.authenticationApi.checkStatus().then((apiInfoRequest) {
      String? strApiInfo = apiInfoRequest.value;

      if(apiInfoRequest.code == ResponseCode.success && strApiInfo != null) {
        _apiVersion = strApiInfo;
      } else {
        _apiVersion = "Unbekannt";
      }

      setState(() {});
    });

    setState(() {
      settingsLoaded = true;
    });
  }

  void _changeTimezone() async {
    tz.Location? newLocation = await PickerDialog.timezonePickerDialog(_timeZone);

    if(newLocation != null) {
      await Xitem.settingController.setTimeZone(newLocation);
      _timeZone = Xitem.settingController.getTimeZone();

      StandardDialog.loadingDialog("Konvertiere Termine...");

      ResponseCode reinitializeCalendar = await StateController.reinitializeCalendarController();

      if (reinitializeCalendar != ResponseCode.success) {
        StateController.navigatorKey.currentState?.pop();
        StandardDialog.okDialog("Termine konnten nicht konvertiert werden!", "Code: $reinitializeCalendar");
        return;
      }

      setState(() {});
      StateController.navigatorKey.currentState?.pop();
    }
  }

  void _changeHolidayStateCode() async {
    StateCode? newStateCode = await PickerDialog.stateCodePickerDialog(_holidayStateCode);

    if (newStateCode != null) {
      await Xitem.settingController.setHolidayStateCode(newStateCode);
      _holidayStateCode = Xitem.settingController.getHolidayStateCode();

      StandardDialog.loadingDialog("Lade Feiertage...");

      ResponseCode reloadHolidays = await widget.holidayController.loadHolidays(_holidayStateCode);

      if (reloadHolidays != ResponseCode.success) {
        StateController.navigatorKey.currentState?.pop();
        StandardDialog.okDialog("Feiertage konnten nicht geladen werden!", "Code: $reloadHolidays");
        return;
      }

      setState(() {});
      StateController.navigatorKey.currentState?.pop();
    }
  }

  void _sendProfileInformationMail() async {
    final ConfirmAction? answer = await StandardDialog.confirmDialog("Profildaten anfordern?", "Hier kannst du alle Daten die Xitem über dich gespeichert hat anfordern. Die Daten werden dir per Mail an\n${widget.userController.getAuthenticatedUser().email}\ngesendet. Möchtest du fortfahren?");

    if (answer == ConfirmAction.ok) {
      final password = await StandardDialog.passwordDialog();

      if (password != null) {
        ResponseCode sendEmail = await widget.authenticationApi.requestProfileInformationEmail(widget.userController.getAuthenticatedUser().id, password);

        if (sendEmail != ResponseCode.success) {
          StandardDialog.okDialog("Email konnte nicht gesendet werden!", "Code: $sendEmail");
          return;
        }

        StandardDialog.okDialog("Email gesendet", "Email wurde erfolgreich gesendet! ♥");
      }
    }
  }

  void _sendProfileDeletionMail() async {
    final ConfirmAction? answer = await StandardDialog.confirmDialog(
        "Profil löschen?",
        "Hier kannst du dein Xitem Account löschen. Nach der Löschung kann dein Account nicht mehr wiederhergestellt werden. Die Löschung muss per Mail bestätigt werden. Wir senden die Mail an\n${widget.userController.getAuthenticatedUser().email}\nMöchtest du fortfahren?"
    );

    if (answer == ConfirmAction.ok) {
      final password = await StandardDialog.passwordDialog();

      if (password != "" && password != null) {
        ResponseCode sendEmail = await widget.authenticationApi.requestProfileDeletionEmail(widget.userController.getAuthenticatedUser().id, password);

        if (sendEmail != ResponseCode.success) {
          StandardDialog.okDialog("Email konnte nicht gesendet werden!", "Code: $sendEmail");
          return;
        }

        StandardDialog.okDialog("Email gesendet", "Email wurde erfolgreich gesendet! ♥");
      }
    }
  }
}
