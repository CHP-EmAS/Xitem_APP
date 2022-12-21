import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/widgets/buttons/LoadingButton.dart';
import 'package:xitem/widgets/IconPicker.dart';
import 'package:flutter/material.dart';
import 'package:xitem/widgets/dialogs/CalendarDialog.dart';
import 'package:xitem/widgets/dialogs/PickerDialog.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';

class CreateCalendarSubPage extends StatefulWidget {
  const CreateCalendarSubPage(this._calendarController, {super.key});

  final CalendarController _calendarController;

  @override
  State<StatefulWidget> createState() {
    return _CreateCalendarSubPageState();
  }
}

class _CreateCalendarSubPageState extends State<CreateCalendarSubPage> {

  final _name = TextEditingController();
  final _password = TextEditingController();

  bool _canJoin = true;
  bool _alert = true;
  int _color = ThemeController.defaultEventColorIndex;
  IconData _icon = IconPicker.defaultIcons[0];

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

    final nameField = TextField(
      obscureText: false,
      style: style,
      controller: _name,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Name",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final passwordField = TextField(
      obscureText: false,
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

    final createCalendarButton = LoadingButton("Kalender erstellen", "Erfolgreich erstellt", Colors.amber, _createCalendar);

    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Kalender Name",
                style: TextStyle(
                  color: ThemeController.activeTheme().headlineColor,
                  letterSpacing: 2,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              nameField,
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
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Switch(
                      value: _canJoin,
                      onChanged: (value) {
                        FocusScope.of(context).unfocus();

                        setState(() {
                          _canJoin = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Text(
                      "Andere Nutzer können beitreten",
                      style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
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

                        PickerDialog.eventColorPickerDialog(_color).then((selectedColor) {
                          if (selectedColor != null) {
                            setState(() {
                              _color = selectedColor;
                            });
                          }
                        });
                      },
                      color: ThemeController.getEventColor(_color),
                      textColor: ThemeController.activeTheme().textColor,
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
                      icon: Icon(_icon),
                      color: Colors.white70,
                      iconSize: 40,
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        PickerDialog.iconPickerDialog(_icon).then((selectedIcon) {
                          if (selectedIcon != null) {
                            setState(() {
                              _icon = selectedIcon;
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
              Divider(height: 20, color: ThemeController.activeTheme().dividerColor),
              const SizedBox(height: 10),
              createCalendarButton,
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _createCalendar() async {
    FocusScope.of(context).unfocus();

    if (_name.text == "" || _password.text == "") return false;

    return await widget._calendarController.createCalendar(_name.text, _password.text, _canJoin, _color, _icon).then((createCalendar) async {
      String? calendarHash = createCalendar.value;

      String errorMessage = "";
      if(createCalendar.code != ResponseCode.success) {
        switch (createCalendar.code) {
          case ResponseCode.missingArgument:
            errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
            break;
          case ResponseCode.invalidTitle:
            errorMessage = "Unzulässiger Name. Zulässige Zeichen: a-z, A-Z, 0-9, Leerzeichen, _, -";
            break;
          case ResponseCode.shortPassword:
            errorMessage = "Das Passwort muss mindestens 6 Zeichen lang sein.";
            break;
          default:
            errorMessage = "Beim Erstellen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
            break;
        }
      }

      if (calendarHash != null) {
        await CalendarDialog.calendarInvitationDialog(calendarHash);
        StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/home/calendar', (route) => false);
        return true;
      } else {
        StandardDialog.okDialog("Der Kalender konnten nicht erstellt werden!", errorMessage);
        return false;
      }
    });
  }
}
