import 'dart:io';

import 'package:de/Controllers/HolidayListController.dart';
import 'package:de/Controllers/SettingController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Models/User.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class HolidayListScreen extends StatefulWidget {
  _HolidayListScreenState hlss;

  refreshState() {
    if(hlss.mounted)
      hlss.refreshState();
  }

  @override
  State<StatefulWidget> createState() {
    hlss = _HolidayListScreenState();
    return hlss;
  }
}

class _HolidayListScreenState extends State<HolidayListScreen> {
  List<BirthdayEntry> _birthdayUserList = new List<BirthdayEntry>();

  DateFormat _dateOnlyFormatWithYear = new DateFormat.yMMMMEEEEd('de_DE');

  @override
  void initState() {
    generateBirthdayList();
    super.initState();
  }

  void refreshState() {
    setState(() {
      generateBirthdayList();
    });
  }

  void generateBirthdayList() {
    _birthdayUserList.clear();

    if(SettingController.getShowBirthdaysOnHolidayScreen()) {
      UserController.publicUserList.forEach((userID, user) {
        if (user.birthday != null) {
          BirthdayEntry newBirthdayEntry = BirthdayEntry(user.userID);
          _birthdayUserList.add(newBirthdayEntry);
        }
      });
    }

    _birthdayUserList.sort((entryA, entryB) {
      if (entryA.convertedBirthday == entryB.convertedBirthday)
        return 0;
      else if (entryA.convertedBirthday.isAfter(entryB.convertedBirthday))
        return 1;
      else
        return -1;
    });
  }

  Widget _buildBirthdayListView() {
    return Container(
      child: Column(
        children: _birthdayUserList.map((birthdayEntry) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            elevation: 3,
            color: ThemeController.activeTheme().cardColor,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.amber,
                    width: 3,
                  ),
                ),
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.transparent,
                  backgroundImage: birthdayEntry.userAvatar != null ? FileImage(birthdayEntry.userAvatar) : AssetImage("images/avatar.png"),
                  child: GestureDetector(
                    onTap: () async {
                      DialogPopup.asyncProfilePictureDialog(birthdayEntry.userID);
                    },
                  ),
                ),
                title: Text(
                  birthdayEntry.name,
                  style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 18),
                ),
                subtitle: Text(_dateOnlyFormatWithYear.format(birthdayEntry.convertedBirthday), style: TextStyle(color: ThemeController.activeTheme().cardSmallInfoColor)),
                trailing: Text(
                  (birthdayEntry.convertedBirthday.year - birthdayEntry.originalBirthday.year).toString(),
                  style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPublicHolidayListView() {
    return Container(
      child: Column(
        children: HolidayController.loadedHolidays.map((publicHoliday) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            elevation: 3,
            color: ThemeController.activeTheme().cardColor,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.lightGreen,
                    width: 3,
                  ),
                ),
              ),
              child: ListTile(
                dense: true,
                title: Text(
                  publicHoliday.name,
                  style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 18),
                ),
                subtitle: Text(_dateOnlyFormatWithYear.format(publicHoliday.date), style: TextStyle(color: ThemeController.activeTheme().cardSmallInfoColor)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      child: ListView(
        children: <Widget>[
          _birthdayUserList.isEmpty
              ? Center()
              : Column(
                  children: [
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        "Geburtstage",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: ThemeController.activeTheme().headlineColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(height: (_birthdayUserList.length.toDouble() * 75), child: _buildBirthdayListView()),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        "Feiertage " + HolidayController.getStateName(HolidayController.currentLoadedState),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: ThemeController.activeTheme().headlineColor,
                        ),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: 10),
          Container(height: (HolidayController.loadedHolidays.length.toDouble() * 75), child: _buildPublicHolidayListView()),
          SizedBox(height: 10),
        ],
      ),
    ));
  }
}

class BirthdayEntry {
  final String userID;

  final DateTime originalBirthday;
  final DateTime convertedBirthday;
  final String name;
  final File userAvatar;

  BirthdayEntry._(this.userID, this.originalBirthday, this.convertedBirthday, this.name, this.userAvatar);

  factory BirthdayEntry(String userID) {
    PublicUser user = UserController.getPublicUserInformation(userID);

    DateTime now = DateTime.now();
    DateTime thisYearBirthday = new DateTime(now.year, user.birthday.month, user.birthday.day);
    DateTime nextBirthday;

    if (thisYearBirthday.isBefore(DateTime.now())) {
      nextBirthday = new DateTime(now.year + 1, thisYearBirthday.month, thisYearBirthday.day);
    } else {
      nextBirthday = thisYearBirthday;
    }

    return new BirthdayEntry._(userID, user.birthday, nextBirthday, user.name, user.avatar);
  }
}
