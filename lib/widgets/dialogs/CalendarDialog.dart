import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/CalendarMember.dart';

class CalendarDialog {
  static Future<void> calendarInformationPopup(Calendar calendar) async {
    DateFormat dateOnlyFormat = DateFormat.yMMMMd('de_DE');

    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return ;
    }

    String creationDate = dateOnlyFormat.format(calendar.creationDate);

    return showDialog(
        context: buildContext,
        builder: (context) {
          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            content: SizedBox(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "ID",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 14, letterSpacing: 2),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${calendar.name}#${calendar.hash}",
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Erstellt am",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 14, letterSpacing: 2),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    creationDate,
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            elevation: 3,
            actions: <Widget>[
              TextButton(
                child: Text('Schließen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 16)),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  static Future<List<bool>?> editMemberPopup(CalendarMember member) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return null;
    }

    return showDialog(
        context: buildContext,
        builder: (BuildContext context) {
          bool isOwner = member.isOwner;
          bool canEditEvents = member.canEditEvents;
          bool canCreateEvents = member.canCreateEvents;

          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
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
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Switch(
                            value: canCreateEvents,
                            onChanged: (value) {
                              setState(() {
                                canCreateEvents = value;

                                if (!value) {
                                  isOwner = false;
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
                            "kann Termine erstellen",
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
                            value: canEditEvents,
                            onChanged: (value) {
                              setState(() {
                                canEditEvents = value;

                                if (!value) {
                                  isOwner = false;
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
                            "kann Termine von anderen Mitgliedern bearbeiten/löschen",
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
                            value: isOwner,
                            onChanged: (value) {
                              setState(() {
                                isOwner = value;

                                if (value) {
                                  canEditEvents = true;
                                  canCreateEvents = true;
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
              TextButton(
                child: Text('Speichern', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  Navigator.pop(context, [isOwner, canCreateEvents, canEditEvents]);
                },
              ),
              TextButton(
                child: Text('Abbrechen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  Navigator.pop(context, null);
                },
              ),
            ],
          );
        });
  }

  static Future<void> calendarInvitationDialog(String calendarHash) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return;
    }

    return showDialog(
        context: buildContext,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            title: const Text("Kalender erstellt ♥"),
            content: Text(
              "Dein Kalender wurde erfolgreich erstellt. Die ID deines Kalenders ist:\n$calendarHash\nDie ID kannst du in den Kalendereinstellungen finden.",
            ),
            elevation: 3,
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              TextButton(
                child: Text("ID kopieren", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: calendarHash));
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text("Ok", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  static Future<InvitationRequest?> createQRCodePopup(String calendarID) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return null;
    }
    
    return showDialog(
        context: buildContext,
        builder: (BuildContext context) {
          bool canCreateEvents = true;
          bool canEditEvents = false;
          int duration = 1440; //1 Tag in min

          double currentValue = 2;

          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            title: const Center(child: Text("QR-Code Einladung erstellen")),
            content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Center(
                        child: Text(
                          "Erstelle eine QR-Code Einladung und lege fest welche Berechtigung diese Einladung zulässt. Aus Sicherheitsgründen muss eine Ablaufspanne angegeben werden.",
                          textAlign: TextAlign.center,
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Switch(
                            value: canCreateEvents,
                            onChanged: (value) {
                              setState(() {
                                canCreateEvents = value;
                              });
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Termine erstellen",
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
                            value: canEditEvents,
                            onChanged: (value) {
                              setState(() {
                                canEditEvents = value;
                              });
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Termine von anderen Mitgliedern bearbeiten/löschen",
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
                            duration = 15;
                            return "15 Minuten";
                          case 1:
                            duration = 120;
                            return "2 Stunden";
                          case 2:
                            duration = 1440;
                            return "1 Tag";
                          case 3:
                            duration = 5760;
                            return "4 Tage";
                          case 4:
                            duration = 10080;
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
              TextButton(
                child: Text('Erstellen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  InvitationRequest newRequestData = InvitationRequest(canCreateEvents, canEditEvents, duration);

                  Navigator.pop(context, newRequestData);
                },
              ),
              TextButton(
                child: Text('Abbrechen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  Navigator.pop(context, null);
                },
              ),
            ],
          );
        });
  }

  static Future<List<bool>?> showQrCodePopup(String invitationToken) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return null;
    }
    
    Map<String, dynamic> qrData = jsonDecode(invitationToken);

    String calendarName = "";

    if (qrData.containsKey("n")) {
      calendarName = qrData["n"];
    }

    return showDialog(
        barrierDismissible: false,
        context: buildContext,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
            content: SizedBox(
              height: 283,
              child: Column(
                children: [
                  Center(
                    child: Text(
                      calendarName,
                      style: const TextStyle(color: Color.fromRGBO(70, 70, 70, 1), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  CustomPaint(
                    size: const Size.square(250),
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
              TextButton(
                child: Text("Schließen",
                    style: TextStyle(
                      color: ThemeController.activeTheme().globalAccentColor,
                      fontSize: 18,
                    )),
                onPressed: () {
                  Navigator.pop(context);
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