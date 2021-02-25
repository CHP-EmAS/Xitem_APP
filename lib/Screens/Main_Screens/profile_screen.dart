import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Settings/locator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Controllers/UserController.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NavigationService _navigationService = locator<NavigationService>();

  final dateOnlyFormat = new DateFormat.yMMMMd('de_DE');

  String _name = "-";
  String _birthday = "-";
  String _status = "-";
  String _email = "-";
  String _regAt = "-";

  @override
  void initState() {
    if (UserController.user.name != null) {
      _name = UserController.user.name;
    }

    if (UserController.user.birthday != null) {
      _birthday = dateOnlyFormat.format(UserController.user.birthday);
    }

    if (UserController.user.role != null) {
      _status = UserController.user.role;
    }

    if (UserController.user.email != null) {
      _email = UserController.user.email;
    }

    if (UserController.user.registeredAt != null) {
      _regAt = dateOnlyFormat.format(UserController.user.registeredAt);
    }

    super.initState();
  }

  void update() {
    setState(() {
      if (UserController.user.name != null) _name = UserController.user.name;
      if (UserController.user.birthday != null) _birthday = dateOnlyFormat.format(UserController.user.birthday);
      if (UserController.user.role != null) _status = UserController.user.role;
      if (UserController.user.email != null) _email = UserController.user.email;
      if (UserController.user.registeredAt != null) _regAt = dateOnlyFormat.format(UserController.user.registeredAt);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    imageCache.clear();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            _navigationService.pop();
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
          new IconButton(
            icon: Icon(Icons.settings, color: ThemeController.activeTheme().iconColor, size: 30),
            onPressed: () {
              _navigationService.pushNamed('/editProfile').then((value) {
                setState(() {
                  update();
                });
              });
            },
          ),
        ],
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: Padding(
        padding: EdgeInsets.fromLTRB(30, 40, 30, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: CircleAvatar(
                backgroundImage: FileImage(UserController.user.avatar),
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
            SizedBox(height: 5),
            Text(
              _name,
              style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 25, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Geburtstag",
              style: TextStyle(
                color: ThemeController.activeTheme().headlineColor,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 5),
            Text(
              _birthday,
              style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 25, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Status",
              style: TextStyle(
                color: ThemeController.activeTheme().headlineColor,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 5),
            Text(
              _status,
              style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, letterSpacing: 2, fontSize: 25, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              children: <Widget>[
                Icon(
                  Icons.alternate_email,
                  color: ThemeController.activeTheme().headlineColor,
                ),
                SizedBox(width: 10),
                Text(_email, style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 18, letterSpacing: 2))
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(
                  Icons.star_border,
                  color: ThemeController.activeTheme().headlineColor,
                ),
                SizedBox(width: 10),
                Text(_regAt, style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 18, letterSpacing: 2))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
