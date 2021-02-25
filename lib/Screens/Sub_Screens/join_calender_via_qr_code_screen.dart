import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Settings/locator.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'file:///C:/Users/Clemens/Documents/Development/AndroidStudioProjects/xitem/lib/Widgets/icon_picker_widget.dart';
import 'package:de/Widgets/Dialogs/picker_popups.dart';
import 'package:de/Widgets/buttons/loading_button_widget.dart';
import 'package:flutter/material.dart';

class QRCodeCalenderScreen extends StatefulWidget {
  const QRCodeCalenderScreen();

  @override
  State<StatefulWidget> createState() {
    return _QRCodeCalenderScreenState();
  }
}

class _QRCodeCalenderScreenState extends State<QRCodeCalenderScreen> {
  final NavigationService _navigationService = locator<NavigationService>();

  bool _alert = true;

  Color currentColor = Colors.amber;
  IconData currentIcon = default_icons[0];

  void changeIcon(IconData icon) => setState(() => currentIcon = icon);

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
    final scanQRCodeButton = LoadingButton("QR Code scannen", "Erfolgreich erstellt", Colors.amber, () async {
      var options = ScanOptions(restrictFormat: [BarcodeFormat.qr], strings: {"cancel": "Abbrechen", "flash_on": "Licht an", "flash_off": "Licht aus"});

      ScanResult codeScanner = await BarcodeScanner.scan(options: options); //barcode scanner

      if (codeScanner.type == ResultType.Barcode) {
        Map<String, dynamic> qrData = jsonDecode(codeScanner.rawContent);
        if (qrData.containsKey("n") && qrData.containsKey("k")) {
          ConfirmAction answer = await DialogPopup.asyncConfirmDialog("QR-Einladung annehmen?", "Möchtest du den Kalender\n${qrData["n"].toString()}\nbeitreten?");
          if (answer == ConfirmAction.OK) {
            if (await UserController.acceptCalendarInvitation(qrData["k"].toString(), currentColor, currentIcon)) {
              _navigationService.pushNamedAndRemoveUntil('/home/calendar', (route) => false);
              return true;
            } else {
              await DialogPopup.asyncOkDialog("QR-Code Error!", Api.errorMessage);
            }
          }
        } else {
          await DialogPopup.asyncOkDialog("QR-Code Error!", "Der eingelesene QR-Code beinhaltet nicht die nötigen Daten um eine Kalender-Einladung zu verarbeiten!");
        }
      } else if (codeScanner.type == ResultType.Error) {
        await DialogPopup.asyncOkDialog("Scanner Error", codeScanner.rawContent + "\n" + codeScanner.format.toString() + "\n" + codeScanner.formatNote);
      }

      return false;
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
                  "Hier kannst du einen Kalender per QR Code hinzufügen. Lege vorher das Layout fest.",
                  style: TextStyle(
                    color: ThemeController.activeTheme().textColor,
                    letterSpacing: 2,
                    fontSize: 16,
                  ),
                ),
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
                          PickerPopup.showColorPickerDialog(currentColor).then((selectedColor) {
                            if (selectedColor != null) {
                              setState(() {
                                currentColor = selectedColor;
                              });
                            }
                          });
                        },
                        color: currentColor,
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
                        icon: Icon(currentIcon),
                        color: Colors.white70,
                        iconSize: 40,
                        onPressed: () {
                          PickerPopup.showIconPickerDialog(currentIcon).then((selectedIcon) {
                            if (selectedIcon != null) {
                              setState(() {
                                currentIcon = selectedIcon;
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
                SizedBox(height: 10),
                Divider(
                  height: 20,
                  color: ThemeController.activeTheme().dividerColor,
                ),
                SizedBox(height: 10),
                scanQRCodeButton,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
