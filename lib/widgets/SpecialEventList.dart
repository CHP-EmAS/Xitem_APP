import 'dart:core';
import 'package:xitem/controllers/BirthdayController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/models/SpecialEvent.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xitem/utils/AvatarImageProvider.dart';
import 'package:xitem/widgets/dialogs/UserDialog.dart';

class SpecialEventList extends StatelessWidget {
  static final DateFormat _dateOnlyFormatWithYear = DateFormat.yMMMMEEEEd('de_DE');

  final List<Birthday> birthdayList;
  final List<PublicHoliday> holidayList;

  final String currentLoadedStateName;

  final Function(Birthday) onDeleteLocalBirthday;

  const SpecialEventList({super.key, required this.birthdayList, required this.holidayList, required this.currentLoadedStateName, required this.onDeleteLocalBirthday});

  Widget _buildBirthdayListView() {
    return Column(
      children: birthdayList.map((birthdayEntry) {
        DateTime nextBirthday = birthdayEntry.nextBirthday();
        String? localID = birthdayEntry.localID;

        Widget birthdayTile = ListTile(
          dense: true,
          leading: birthdayEntry.avatar != null ? CircleAvatar(
            radius: 21,
            backgroundColor: Colors.transparent,
            backgroundImage: AvatarImageProvider.get(birthdayEntry.avatar),
            child: GestureDetector(
              onTap: () async {
                UserDialog.profilePictureDialog(birthdayEntry.avatar);
              },
            ),
          ) : const Icon(
            Icons.cake,
            size: 35,
          ),
          title: Text(
            birthdayEntry.name,
            style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 18),
          ),
          subtitle: Text(_dateOnlyFormatWithYear.format(nextBirthday), style: TextStyle(color: ThemeController.activeTheme().cardSmallInfoColor)),
          trailing: Text(
            birthdayEntry.getAgeInYear(nextBirthday.year).toString(),
            style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          onLongPress: localID != null ? () => onDeleteLocalBirthday(birthdayEntry) : null,
        );

        return Card(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 3,
          color: ThemeController.activeTheme().cardColor,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.amber,
                  width: 3,
                ),
              ),
            ),
            child: birthdayTile
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPublicHolidayListView() {
    return Column(
      children: holidayList.map((publicHoliday) {
        return Card(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 3,
          color: ThemeController.activeTheme().cardColor,
          child: Container(
            decoration: const BoxDecoration(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ListView(
          children: <Widget>[
            birthdayList.isEmpty
                ? const Center()
                : Column(
                    children: [
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      SizedBox(height: (birthdayList.length.toDouble() * 75), child: _buildBirthdayListView()),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Feiertage $currentLoadedStateName",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: ThemeController.activeTheme().headlineColor,
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 10),
            SizedBox(height: (holidayList.length.toDouble() * 75), child: _buildPublicHolidayListView()),
            const SizedBox(height: 10),
          ],
        ));
  }
}
