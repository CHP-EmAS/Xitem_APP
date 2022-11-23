import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/Dialogs/picker_popups.dart';
import 'package:de/Widgets/buttons/loading_button_widget.dart';
import 'package:de/Widgets/icon_picker_widget.dart';
import 'package:flutter/material.dart';

class CreateCalendarSubPage extends StatefulWidget {
  const CreateCalendarSubPage();

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
  Color _color = Colors.amber;
  IconData _icon = default_icons[0];

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
    final TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.black);

    final nameField = TextField(
      obscureText: false,
      style: style,
      controller: _name,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Name",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final passwordField = TextField(
      obscureText: false,
      style: style,
      controller: _password,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Passwort",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final createCalendarButton = LoadingButton("Kalender erstellen", "Erfolgreich erstellt", Colors.amber, () async {
      FocusScope.of(context).unfocus();

      if (_name.text == "" || _password.text == "") return false;

      return await UserController.createCalendar(_name.text, _password.text, _canJoin, _color, _icon).then((calendarHash) async {
        if (calendarHash != null) {
          await DialogPopup.asyncCalendarInvitationDialog(calendarHash);
          Navigator.pushNamedAndRemoveUntil(context,'/home/calendar', (route) => false);
          return true;
        } else {
          DialogPopup.asyncOkDialog("Der Kalender konnten nicht erstellt werden!", Api.errorMessage);
          return false;
        }
      });
    });

    return Container(
      child: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(30, 40, 30, 0),
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
                SizedBox(height: 10),
                nameField,
                SizedBox(height: 20),
                Text(
                  "Passwort",
                  style: TextStyle(
                    color: ThemeController.activeTheme().headlineColor,
                    letterSpacing: 2,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                passwordField,
                SizedBox(height: 20),
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

                          PickerPopup.showColorPickerDialog(_color).then((selectedColor) {
                            if (selectedColor != null) {
                              setState(() {
                                _color = selectedColor;
                              });
                            }
                          });
                        },
                        color: _color,
                        textColor: ThemeController.activeTheme().textColor,
                        padding: EdgeInsets.all(16),
                        shape: CircleBorder(),
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
                SizedBox(height: 10),
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
                          PickerPopup.showIconPickerDialog(_icon).then((selectedIcon) {
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
                SizedBox(height: 10),
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
                SizedBox(height: 10),
                createCalendarButton,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
