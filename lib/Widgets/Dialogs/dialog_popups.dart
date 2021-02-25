import 'dart:convert';

import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Models/Member.dart';
import 'package:de/Models/User.dart';
import 'package:de/Settings/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum ConfirmAction { CANCEL, ACCEPT, OK }

class DialogPopup {
  static final NavigationService _navigationService = locator<NavigationService>();

  static Future<ConfirmAction> asyncOkDialog(String title, String content) {
    return showDialog<ConfirmAction>(
      context: _navigationService.navigatorKey.currentContext,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
          title: new Text(title),
          content: new Text(content),
          elevation: 3,
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Ok", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
              onPressed: () {
                _navigationService.pop(ConfirmAction.OK);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<ConfirmAction> asyncConfirmDialog(String title, String content) {
    return showDialog<ConfirmAction>(
      context: _navigationService.navigatorKey.currentContext,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
          title: new Text(title),
          content: new Text(content),
          elevation: 3,
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("OK", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
              onPressed: () {
                _navigationService.pop(ConfirmAction.OK);
              },
            ),
            new FlatButton(
              child: new Text("Abbrechen", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
              onPressed: () {
                _navigationService.pop(ConfirmAction.CANCEL);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> asyncLoadingDialog(GlobalKey key, String loadingText) async {
    return showDialog<void>(
        context: _navigationService.navigatorKey.currentContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new WillPopScope(
              onWillPop: () async => false,
              child: SimpleDialog(key: key, backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor, elevation: 3, children: <Widget>[
                Center(
                  child: Column(children: [
                    SpinKitThreeBounce(
                      color: Color.fromARGB(150, 255, 255, 255),
                      size: 30,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      loadingText,
                      style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18),
                    )
                  ]),
                )
              ]));
        });
  }

  static Future<String> asyncPasswordDialog() {
    TextEditingController _textFieldController = TextEditingController();

    return showDialog<String>(
        context: _navigationService.navigatorKey.currentContext,
        builder: (context) {
          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            title: Text('Für diese Aktion benötigen wir dein Passwort'),
            content: TextField(
              controller: _textFieldController,
              obscureText: true,
              decoration: InputDecoration(hintText: "Passwort"),
            ),
            elevation: 3,
            actions: <Widget>[
              new FlatButton(
                child: new Text(
                  'Ok',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18),
                ),
                onPressed: () {
                  final password = _textFieldController.text;
                  _textFieldController.clear();
                  _navigationService.pop(password);
                },
              ),
              new FlatButton(
                child: new Text(
                  'Abbrechen',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18),
                ),
                onPressed: () {
                  _navigationService.pop("");
                },
              ),
            ],
          );
        });
  }

  static Future<void> asyncUserInformationPopup(String userID) async {
    DateFormat dateOnlyFormat = new DateFormat.yMMMMd('de_DE');

    PublicUser user = UserController.getPublicUserInformation(userID);
    if (user == null) return;

    String birthday = "nicht angegeben";

    if (user.birthday != null) {
      birthday = dateOnlyFormat.format(user.birthday);
    }

    return showDialog(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            content: Container(
              height: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: CircleAvatar(
                      backgroundImage: FileImage(user.avatar),
                      radius: 40,
                    ),
                  ),
                  Divider(height: 20, color: ThemeController.activeTheme().dividerColor),
                  Text(
                    "Name",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 12, letterSpacing: 2),
                  ),
                  SizedBox(height: 5),
                  Text(
                    user.name,
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Geburtstag",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 12, letterSpacing: 2),
                  ),
                  SizedBox(height: 5),
                  Text(
                    birthday,
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Status",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 12, letterSpacing: 2),
                  ),
                  SizedBox(height: 5),
                  Text(
                    user.role,
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            elevation: 3,
            actions: <Widget>[
              new FlatButton(
                child: new Text(
                  'Schließen',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 16),
                ),
                onPressed: () {
                  _navigationService.pop();
                },
              )
            ],
          );
        });
  }

  static Future<void> asyncProfilePictureDialog(String userID) async {
    PublicUser user = UserController.getPublicUserInformation(userID);
    if (user == null) return;

    return showDialog(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          return GestureDetector(
            onTap: () {
              _navigationService.pop();
            },
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(image: DecorationImage(image: FileImage(user.avatar), fit: BoxFit.scaleDown)),
              ),
            ),
          );
        });
  }

  static Future<void> asyncCalendarInformationPopup(String calendarID) async {
    DateFormat dateOnlyFormat = new DateFormat.yMMMMd('de_DE');

    Calendar calendar = UserController.calendarList[calendarID];

    if (calendar == null) return;

    String creationDate = dateOnlyFormat.format(calendar.creationDate);

    return showDialog(
        context: _navigationService.navigatorKey.currentContext,
        builder: (context) {
          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            content: Container(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "ID",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 14, letterSpacing: 2),
                  ),
                  SizedBox(height: 5),
                  Text(
                    calendar.name + "#" + calendar.hash,
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Erstellt am",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 14, letterSpacing: 2),
                  ),
                  SizedBox(height: 5),
                  Text(
                    creationDate,
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            elevation: 3,
            actions: <Widget>[
              new FlatButton(
                child: new Text('Schließen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 16)),
                onPressed: () {
                  _navigationService.pop();
                },
              )
            ],
          );
        });
  }

  static Future<List<bool>> asyncEditMemberPopup(String calendarID, AssociatedUser member) async {
    return showDialog(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          bool _isOwner = member.isOwner;
          bool _canEditEvents = member.canEditEvents;
          bool _canCreateEvents = member.canCreateEvents;

          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: 184,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        "Mitgliedsberechtigungen",
                        style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Switch(
                            value: _canCreateEvents,
                            onChanged: (value) {
                              setState(() {
                                _canCreateEvents = value;

                                if (!value) {
                                  _isOwner = false;
                                }
                              });
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "kann Events erstellen",
                            style: TextStyle(color: ThemeController.activeTheme().headlineColor, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Switch(
                            value: _canEditEvents,
                            onChanged: (value) {
                              setState(() {
                                _canEditEvents = value;

                                if (!value) {
                                  _isOwner = false;
                                }
                              });
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "kann Events von anderen Mitgliedern bearbeiten/löschen",
                            style: TextStyle(color: ThemeController.activeTheme().headlineColor, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Switch(
                            value: _isOwner,
                            onChanged: (value) {
                              setState(() {
                                _isOwner = value;

                                if (value) {
                                  _canEditEvents = true;
                                  _canCreateEvents = true;
                                }
                              });
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "ist Kalenderadmin",
                            style: TextStyle(color: ThemeController.activeTheme().headlineColor, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            elevation: 3,
            actions: <Widget>[
              new FlatButton(
                child: new Text('Speichern', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  _navigationService.pop([_isOwner, _canCreateEvents, _canEditEvents]);
                },
              ),
              new FlatButton(
                child: new Text('Abbrechen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  _navigationService.pop(null);
                },
              ),
            ],
          );
        });
  }

  static Future<void> asyncCalendarInvitationDialog(String calendarHash) async {
    return showDialog(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            title: new Text("Kalender erstellt ♥"),
            content: new Text(
              "Dein Kalender wurde erfolgreich erstellt. Die ID deines Kalenders ist:\n" + calendarHash + "\nDie ID kannst du in den Kalendereinstellungen finden.",
            ),
            elevation: 3,
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new FlatButton(
                child: new Text("ID kopieren", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: calendarHash));
                  _navigationService.pop();
                },
              ),
              new FlatButton(
                child: new Text("Ok", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  _navigationService.pop();
                },
              ),
            ],
          );
        });
  }

  static Future<TimeOfDay> asyncTimeSliderDialog(TimeOfDay initTime) {
    return showDialog<TimeOfDay>(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          TimeOfDay _currentTime = initTime;

          return AlertDialog(
            contentPadding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            content: TimePickerWidget(
                maxDateTime: DateTime(0, 0, 0, 23, 59),
                minDateTime: DateTime(0, 0, 0, 0, 0),
                dateFormat: "HH:mm",
                initDateTime: DateTime(0, 0, 0, _currentTime.hour, _currentTime.minute),
                locale: DateTimePickerLocale.de,
                pickerTheme: DateTimePickerTheme(
                    itemTextStyle: TextStyle(color: ThemeController.activeTheme().infoDialogTextColor),
                    showTitle: false,
                    backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
                    pickerHeight: 120,
                    itemHeight: 40),
                onChange: (selectedTime, selectedIndex) {
                  _currentTime = TimeOfDay(hour: selectedTime.hour, minute: selectedTime.minute);
                }),
            elevation: 3,
            actions: <Widget>[
              new FlatButton(
                child: new Text(
                  'Ok',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 16),
                ),
                onPressed: () {
                  _navigationService.pop(_currentTime);
                },
              ),
              new FlatButton(
                child: new Text(
                  'Abbrechen',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 16),
                ),
                onPressed: () {
                  _navigationService.pop(null);
                },
              ),
            ],
          );
        });
  }

  static Future<InvitationRequest> asyncCreateQRCodePopup(String calendarID) async {
    return showDialog(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          bool _canCreateEvents = true;
          bool _canEditEvents = false;
          int _duration = 1440; //1 Tag in min

          double currentValue = 2;

          return AlertDialog(
            contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            title: Center(child: Text("QR-Code Einladung erstellen")),
            content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                        child: Text(
                      "Erstelle eine QR-Code Einladung und lege fest welche Berechtigung diese Einladung zulässt. Aus Sicherheitsgründen muss eine Ablaufspanne angegeben werden.",
                      textAlign: TextAlign.center,
                    )),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Switch(
                            value: _canCreateEvents,
                            onChanged: (value) {
                              setState(() {
                                _canCreateEvents = value;
                              });
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Events erstellen",
                            style: TextStyle(color: ThemeController.activeTheme().headlineColor, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Switch(
                            value: _canEditEvents,
                            onChanged: (value) {
                              setState(() {
                                _canEditEvents = value;
                              });
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Events von anderen Mitgliedern bearbeiten/löschen",
                            style: TextStyle(color: ThemeController.activeTheme().headlineColor, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: currentValue,
                      min: 0,
                      max: 4,
                      divisions: 4,
                      inactiveColor: Colors.grey[700],
                      activeColor: Colors.amber,
                      label: () {
                        switch (currentValue.toInt()) {
                          case 0:
                            _duration = 15;
                            return "15 Minuten";
                          case 1:
                            _duration = 120;
                            return "2 Stunden";
                          case 2:
                            _duration = 1440;
                            return "1 Tag";
                          case 3:
                            _duration = 5760;
                            return "4 Tage";
                          case 4:
                            _duration = 10080;
                            return "7 Tage";
                        }
                      }(),
                      onChanged: (double value) {
                        setState(() {
                          currentValue = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            elevation: 3,
            actions: <Widget>[
              new FlatButton(
                child: new Text('Erstellen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  InvitationRequest newRequestData = new InvitationRequest(_canCreateEvents, _canEditEvents, _duration);

                  _navigationService.pop(newRequestData);
                },
              ),
              new FlatButton(
                child: new Text('Abbrechen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  _navigationService.pop(null);
                },
              ),
            ],
          );
        });
  }

  static Future<List<bool>> asyncShowQRCodePopup(String invitationToken) async {
    Map<String, dynamic> qrData = jsonDecode(invitationToken);

    String calendarName = "";

    if (qrData.containsKey("n")) {
      calendarName = qrData["n"];
    }

    return showDialog(
        barrierDismissible: false,
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
            content: Container(
              height: 283,
              child: Column(
                children: [
                  Center(
                    child: Text(
                      calendarName,
                      style: TextStyle(color: Color.fromRGBO(70, 70, 70, 1), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  CustomPaint(
                    size: Size.square(250),
                    painter: QrPainter(
                      data: invitationToken,
                      gapless: true,
                      version: QrVersions.auto,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              new FlatButton(
                child: new Text("Schließen",
                    style: TextStyle(
                      color: ThemeController.activeTheme().globalAccentColor,
                      fontSize: 18,
                    )),
                onPressed: () {
                  _navigationService.pop();
                },
              ),
            ],
          );
        });
  }
}

class InvitationRequest {
  InvitationRequest(this.canCreateEvents, this.canEditEvents, this.duration);

  final bool canCreateEvents;
  final bool canEditEvents;
  final int duration;
}
