import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/widgets/dialogs/PickerDialog.dart';
import 'package:xitem/widgets/buttons/LoadingButton.dart';
import 'package:flutter/material.dart';

class JoinCalendarQrSubPage extends StatefulWidget {
  const JoinCalendarQrSubPage(this._calendarController, {super.key});

  final CalendarController _calendarController;

  @override
  State<StatefulWidget> createState() => _JoinCalendarQrSubPageState();
}

class _JoinCalendarQrSubPageState extends State<JoinCalendarQrSubPage> {
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
    final scanQRCodeButton = LoadingButton(buttonText: "QR Code scannen", successText: "Erfolgreich erstellt", buttonColor: Colors.amber, callBack: _scanQrCode);

    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
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
                      onPressed: _showColorPicker,
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
                      onPressed: _showIconPicker,
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
              const SizedBox(height: 10),
              Divider(
                height: 20,
                color: ThemeController.activeTheme().dividerColor,
              ),
              const SizedBox(height: 10),
              scanQRCodeButton,
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _scanQrCode() async {
    // var options = const ScanOptions(restrictFormat: [BarcodeFormat.qr], strings: {"cancel": "Abbrechen", "flash_on": "Licht an", "flash_off": "Licht aus"});
    // ScanResult codeScanner = await BarcodeScanner.scan(options: options);
    //
    // if (codeScanner.type == ResultType.Barcode) {
    //   Map<String, dynamic> qrData = jsonDecode(codeScanner.rawContent);
    //
    //   if (qrData.containsKey("n") && qrData.containsKey("k")) {
    //     ConfirmAction? answer = await StandardDialog.confirmDialog("QR-Einladung annehmen?", "Möchtest du den Kalender\n${qrData["n"].toString()}\nbeitreten?");
    //
    //     if (answer == ConfirmAction.ok) {
    //       ResponseCode acceptInvitation = await widget._calendarController.acceptCalendarInvitation(qrData["k"].toString(), _color, _icon);
    //
    //       if (acceptInvitation != ResponseCode.success) {
    //         String errorMessage;
    //
    //         switch(acceptInvitation) {
    //           case ResponseCode.tokenInvalid:
    //           case ResponseCode.tokenExpired:
    //             errorMessage = "Diese Einladung ist ungültig oder abgelaufen.";
    //             break;
    //           case ResponseCode.calendarNotFound:
    //             errorMessage = "Der Kalender den du betreten möchtest existiert nicht mehr.";
    //             break;
    //           case ResponseCode.calendarNotJoinable:
    //             errorMessage = "Diesem Kalender kann nicht beigetreten werden.";
    //             break;
    //           case ResponseCode.assocUserAlreadyExists:
    //             errorMessage = "Du bist bereits Mitglied in diesem Kalender.";
    //             break;
    //           case ResponseCode.missingArgument:
    //             errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
    //             break;
    //           case ResponseCode.invalidColor:
    //             errorMessage = "Unzulässige Farbe.";
    //             break;
    //           default:
    //             errorMessage = "Beim Beitreten des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
    //         }
    //
    //         await StandardDialog.okDialog("QR-Code Error!", errorMessage);
    //         return false;
    //       }
    //
    //       StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/home/calendar', (route) => false);
    //       return true;
    //     }
    //   } else {
    //     await StandardDialog.okDialog("QR-Code Error!", "Der eingelesene QR-Code beinhaltet nicht die nötigen Daten um eine Kalender-Einladung zu verarbeiten!");
    //   }
    // } else if (codeScanner.type == ResultType.Error) {
    //   await StandardDialog.okDialog("Scanner Error", "${codeScanner.rawContent}\n${codeScanner.format}\n${codeScanner.formatNote}");
    // }

    return false;
  }

  void _showColorPicker() {
    PickerDialog.eventColorPickerDialog(initialColor: _currentColorIndex).then((selectedColor) {
      if (selectedColor != null) {
        setState(() {
          _currentColorIndex = selectedColor;
        });
      }
    });
  }

  void _showIconPicker() {
    PickerDialog.iconPickerDialog(_currentIconIndex).then((selectedIcon) {
      if (selectedIcon != null) {
        setState(() {
          _currentIconIndex = selectedIcon;
        });
      }
    });
  }
}
