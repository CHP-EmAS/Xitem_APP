import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/Dialogs/picker_popups.dart';
import 'package:de/Widgets/buttons/loading_button_widget.dart';
import 'package:de/Widgets/icon_picker_widget.dart';
import 'package:flutter/material.dart';

class JoinCalendarSubPage extends StatefulWidget {
  const JoinCalendarSubPage();

  @override
  State<StatefulWidget> createState() {
    return _JoinCalendarSubPageState();
  }
}

class _JoinCalendarSubPageState extends State<JoinCalendarSubPage> {
  final _id = TextEditingController();
  final _password = TextEditingController();

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
    TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.black);

    final idField = TextField(
      obscureText: false,
      style: style,
      controller: _id,
      decoration: InputDecoration(
          suffixIcon: GestureDetector(
            onTap: () {
              DialogPopup.asyncOkDialog("Kalender ID",
                  "Die Kalender ID ist in den Einstellungen des jeweiligen Kalenders zu finden. Sie besteht aus dem Namen des Kalenders und einer Nummer welche durch einen # getrennt sind.");
            },
            child: Icon(Icons.info_outline),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "ID (Name#1234)",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final passwordField = TextField(
      obscureText: true,
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

    final joinCalendarButton = LoadingButton("Kalender beitreten", "Erfolgreich beigetreten", Colors.amber, () async {
      FocusScope.of(context).unfocus();

      if (_id.text == "" || _password.text == "") return false;

      return await UserController.joinCalendar(_id.text, _password.text, _color, _icon).then((success) async {
        if (success) {
          Navigator.pushNamedAndRemoveUntil(context, '/home/calendar', (route) => false);
          return true;
        } else {
          DialogPopup.asyncOkDialog("Dem Kalender konnten nicht beigetreten werden!", Api.errorMessage);
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
                  "Kalender ID",
                  style: TextStyle(
                    color: ThemeController.activeTheme().headlineColor,
                    letterSpacing: 2,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                idField,
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
                SizedBox(height: 10),
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
                        textColor: Colors.white,
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
                Divider(
                  height: 20,
                  color: ThemeController.activeTheme().dividerColor,
                ),
                SizedBox(height: 10),
                joinCalendarButton,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
