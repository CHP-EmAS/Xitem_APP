import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Models/User.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class ProfilePage extends StatelessWidget {

  ProfilePage({Key key, @required this.appUser});

  final dateOnlyFormat = new DateFormat.yMMMMd('de_DE');
  final AppUser appUser;

  @override
  Widget build(BuildContext context) {
    imageCache.clear();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            Navigator.pop(context);
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
              Navigator.pushNamed(context, '/editProfile');
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
                backgroundImage: FileImage(appUser.avatar),
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
              appUser.name != null ? appUser.name : "-",
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
              appUser.birthday != null ? dateOnlyFormat.format(appUser.birthday) : "-",
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
              appUser.role != null ? appUser.role : "-",
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
                Text(
                    appUser.email != null ? appUser.email : "-",
                    style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        fontSize: 18,
                        letterSpacing: 2
                    )
                )
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
                Text(
                    appUser.registeredAt != null ? appUser.registeredAt : "-",
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
