import 'dart:io';

import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/AvatarImageProvider.dart';


class ProfilePage extends StatelessWidget {

  ProfilePage(this._authenticatedUser, {super.key});

  final _dateOnlyFormat = DateFormat.yMMMMd('de_DE');
  final AuthenticatedUser _authenticatedUser;

  @override
  Widget build(BuildContext context) {
    String birthday = "-";
    DateTime? userBirthday = _authenticatedUser.birthday;
    if(userBirthday != null) {
      birthday = _dateOnlyFormat.format(userBirthday);
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            StateController.navigatorKey.currentState?.pop(context);
          },
        ),
        title: Text(
          "Dein Account",
          style: TextStyle(
            color: ThemeController.activeTheme().textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        elevation: 3,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings, color: ThemeController.activeTheme().iconColor, size: 30),
            onPressed: () {
              StateController.navigatorKey.currentState?.pushNamed('/editProfile');
            },
          ),
        ],
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: CircleAvatar(
                backgroundImage: AvatarImageProvider.get(_authenticatedUser.avatar),
                radius: 60,
              ),
            ),
            Divider(height: 40, color: ThemeController.activeTheme().dividerColor),
            Text(
              "Name",
              style: TextStyle(
                color: ThemeController.activeTheme().headlineColor,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _authenticatedUser.name,
              style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Geburtstag",
              style: TextStyle(
                color: ThemeController.activeTheme().headlineColor,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              birthday,
              style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Status",
              style: TextStyle(
                color: ThemeController.activeTheme().headlineColor,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _authenticatedUser.role,
              style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Icon(
                  Icons.alternate_email,
                  color: ThemeController.activeTheme().headlineColor,
                ),
                const SizedBox(width: 10),
                Text(
                    _authenticatedUser.email,
                    style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        fontSize: 18,
                        letterSpacing: 2
                    )
                )
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(
                  Icons.star_border,
                  color: ThemeController.activeTheme().headlineColor,
                ),
                const SizedBox(width: 10),
                Text(
                    _dateOnlyFormat.format(_authenticatedUser.registeredAt),
                    style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        fontSize: 18,
                        letterSpacing: 2
                    )
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
