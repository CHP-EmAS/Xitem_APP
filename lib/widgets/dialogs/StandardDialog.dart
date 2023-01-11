import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';

enum ConfirmAction { cancel, accept, ok, error }

class StandardDialog {

  static Future<ConfirmAction?> okDialog(String title, String content) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return ConfirmAction.error;
    }

    return await showDialog<ConfirmAction>(
      context: buildContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
          title: Text(title),
          content: Text(content),
          elevation: 3,
          actions: <Widget>[
            TextButton(
              child: Text("Ok", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
              onPressed: () {
                Navigator.pop(context, ConfirmAction.ok);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<ConfirmAction?> confirmDialog(String title, String content) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return ConfirmAction.error;
    }

    return await showDialog<ConfirmAction>(
      context: buildContext,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
          title: Text(title),
          content: Text(content),
          elevation: 3,
          actions: <Widget>[
            TextButton(
              child: Text("Abbrechen", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
              onPressed: () {
                Navigator.pop(context, ConfirmAction.cancel);
              },
            ),
            TextButton(
              child: Text("OK", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
              onPressed: () {
                Navigator.pop(context, ConfirmAction.ok);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> loadingDialog(String loadingText) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return;
    }

    return showDialog<void>(
        context: buildContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
              onWillPop: () async => false,
              child: SimpleDialog(backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor, elevation: 3, children: <Widget>[
                Center(
                  child: Column(children: [
                    const SpinKitThreeBounce(
                      color: Color.fromARGB(150, 255, 255, 255),
                      size: 30,
                    ),
                    const SizedBox(
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

  static Future<String?> passwordDialog() async {
    TextEditingController textFieldController = TextEditingController();

    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return null;
    }

    return showDialog<String>(
        context: buildContext,
        builder: (context) {
          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            title: const Text('Für diese Aktion benötigen wir dein Passwort'),
            content: TextField(
              controller: textFieldController,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Passwort"),
            ),
            elevation: 3,
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Abbrechen',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text(
                  'Ausführen',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18),
                ),
                onPressed: () {
                  final password = textFieldController.text;
                  textFieldController.clear();
                  Navigator.pop(context, password);
                },
              ),
            ],
          );
        });
  }

  static Future<String?> textDialog(String titel, String hintText, String? text) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return null;
    }

    TextEditingController textFieldController = TextEditingController();
    if(text != null) {
      textFieldController.text = text;
    }

    return showDialog<String>(
        context: buildContext,
        builder: (context) {
          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            title: Text(titel),
            content: TextField(
              controller: textFieldController,
              decoration: InputDecoration(hintText: hintText),
            ),
            elevation: 3,
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Abbrechen',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text(
                  'Ok',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18),
                ),
                onPressed: () {
                  final password = textFieldController.text;
                  textFieldController.clear();
                  Navigator.pop(context, password);
                },
              ),
            ],
          );
        });
  }
}
