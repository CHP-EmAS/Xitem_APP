import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/AvatarImageProvider.dart';

class UserDialog {
  static Future<void> userInformationPopup(User user) async {
    DateFormat dateOnlyFormat = DateFormat.yMMMMd('de_DE');

    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return ;
    }

    String strBirthday = "nicht angegeben";
    DateTime? birthday = user.birthday;
    if (birthday != null) {
      strBirthday = dateOnlyFormat.format(birthday);
    }

    return showDialog(
        context: buildContext,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            content: SizedBox(
              height: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: CircleAvatar(
                      backgroundImage: AvatarImageProvider.get(user.avatar),
                      radius: 40,
                    ),
                  ),
                  Divider(height: 20, color: ThemeController.activeTheme().dividerColor),
                  Text(
                    "Name",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 12, letterSpacing: 2),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user.name,
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Geburtstag",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 12, letterSpacing: 2),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    strBirthday,
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Status",
                    style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 12, letterSpacing: 2),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user.role,
                    style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            elevation: 3,
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Schließen',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  static Future<void> profilePictureDialog(File? avatar) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return ;
    }
    
    return showDialog(
        context: buildContext,
        builder: (BuildContext context) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(image: DecorationImage(image: AvatarImageProvider.get(avatar), fit: BoxFit.scaleDown)),
              ),
            ),
          );
        });
  }
}