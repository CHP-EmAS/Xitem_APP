import 'package:flutter/material.dart';
import 'package:xitem/controllers/BirthdayController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:intl/intl.dart';

class BirthdayDialog {
  static Future<LocalBirthday?> showBirthdayDialog() async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if (buildContext == null) {
      return null;
    }

    final dateFormat = DateFormat.yMMMMd('de_DE');

    DateTime birthday = DateTime.now();
    final TextEditingController name = TextEditingController();

    return showDialog<LocalBirthday>(
        context: buildContext,
        builder: (BuildContext context) {
          return AlertDialog(
            elevation: 5,
            title: Center(
              child: Text(
                "Geburtstag hinzufügen",
                style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            scrollable: true,
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SizedBox(
                  width: 800,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(hintText: "Name"),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.cake_outlined,
                          size: 25,
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        InkWell(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(2, 10, 0, 10),
                            child: Text(
                              dateFormat.format(birthday),
                              style: TextStyle(
                                color: ThemeController.activeTheme().textColor,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();

                            showDatePicker(context: context, initialDate: birthday, firstDate: DateTime(1900, 1, 1), lastDate: DateTime.now()).then((selectedDate) {
                              if (selectedDate == null) return;

                              setState(() {
                                birthday = selectedDate;
                              });
                            });
                          },
                        ),
                      ],
                    ),
                  ]),
                );
              },
            ),
            actions: <Widget>[
              TextButton(
                child: Text("Hinzufügen", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                onPressed: () {
                  LocalBirthday data = LocalBirthday(name.text, birthday);
                  Navigator.pop(context, data);
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
}
