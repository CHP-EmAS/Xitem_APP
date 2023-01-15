import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/widgets/buttons/LoadingButton.dart';
import 'package:flutter/material.dart';
import 'package:xitem/widgets/dialogs/PickerDialog.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';

class JoinCalendarSubPage extends StatefulWidget {
  const JoinCalendarSubPage(this._calendarController, {super.key});

  final CalendarController _calendarController;

  @override
  State<StatefulWidget> createState() => _JoinCalendarSubPageState();
}

class _JoinCalendarSubPageState extends State<JoinCalendarSubPage> {
  final _id = TextEditingController();
  final _password = TextEditingController();

  bool _alert = true;
  int _currentColorIndex = ThemeController.defaultEventColorIndex;
  int _currentIconIndex = ThemeController.defaultCalendarIconIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.black);

    final idField = TextField(
      obscureText: false,
      style: style,
      controller: _id,
      decoration: InputDecoration(
          suffixIcon: GestureDetector(
            onTap: () {
              StandardDialog.okDialog("Kalender ID",
                  "Die Kalender ID ist in den Einstellungen des jeweiligen Kalenders zu finden. Sie besteht aus dem Namen des Kalenders und einer Nummer welche durch einen # getrennt sind.");
            },
            child: const Icon(Icons.info_outline),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "ID (Name#1234)",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final passwordField = TextField(
      obscureText: true,
      style: style,
      controller: _password,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Passwort",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final joinCalendarButton = LoadingButton(buttonText: "Kalender beitreten", successText: "Erfolgreich beigetreten", buttonColor: Colors.amber, callBack: () async {
      FocusScope.of(context).unfocus();

      if (_id.text == "" || _password.text == "") return false;

      ResponseCode joinCalendar = await widget._calendarController.joinCalendar(_id.text, _password.text, _currentColorIndex, _currentIconIndex);

      if(joinCalendar != ResponseCode.success) {
        String errorMessage;

        switch (joinCalendar) {
          case ResponseCode.missingArgument:
            errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
            break;
          case ResponseCode.calendarNotFound:
            errorMessage = "Der Kalender den du betreten möchtest existiert nicht mehr.";
            break;
          case ResponseCode.calendarNotJoinable:
            errorMessage = "Diesem Kalender kann nicht beigetreten werden.";
            break;
          case ResponseCode.assocUserAlreadyExists:
            errorMessage = "Du bist bereits Mitglied in diesem Kalender.";
            break;
          case ResponseCode.invalidColor:
            errorMessage = "Unzulässige Farbe.";
            break;
          case ResponseCode.wrongPassword:
            errorMessage = "Kalender-Name oder Passwort falsch.";
            break;
          default:
            errorMessage = "Beim Beitreten des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
            break;
        }

        StandardDialog.okDialog("Dem Kalender konnten nicht beigetreten werden!", errorMessage);
        return false;
      }

      StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/home/calendar', (route) => false);
      return true;
    });

    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Kalender ID",
                style: TextStyle(
                  color: ThemeController.activeTheme().headlineColor,
                  letterSpacing: 2,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              idField,
              const SizedBox(height: 20),
              Text(
                "Passwort",
                style: TextStyle(
                  color: ThemeController.activeTheme().headlineColor,
                  letterSpacing: 2,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              passwordField,
              const SizedBox(height: 10),
              Divider(
                height: 20,
                color: ThemeController.activeTheme().dividerColor,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: MaterialButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();

                        PickerDialog.eventColorPickerDialog(initialColor: _currentColorIndex).then((selectedColor) {
                          if (selectedColor != null) {
                            setState(() {
                              _currentColorIndex = selectedColor;
                            });
                          }
                        });
                      },
                      color: ThemeController.getEventColor(_currentColorIndex),
                      textColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Text(
                      "Kalender Farbe",
                      style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: IconButton(
                      icon: Icon(ThemeController.getCalendarIcon(_currentIconIndex)),
                      color: Colors.white70,
                      iconSize: 40,
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        PickerDialog.iconPickerDialog(_currentIconIndex).then((selectedIcon) {
                          if (selectedIcon != null) {
                            setState(() {
                              _currentIconIndex = selectedIcon;
                            });
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Text(
                      "Kalender Icon",
                      style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Switch(
                      value: _alert,
                      onChanged: (value) {
                        setState(() {
                          _alert = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Text(
                      "Benachrichtigungen",
                      style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(
                height: 20,
                color: ThemeController.activeTheme().dividerColor,
              ),
              const SizedBox(height: 10),
              joinCalendarButton,
            ],
          ),
        ),
      ],
    );
  }
}
