import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:xitem/models/SpecialEvent.dart';
import 'package:xitem/utils/StateCodeConverter.dart';
import 'package:xitem/widgets/IconPicker.dart';

class PickerDialog {

  static Future<int?> eventColorPickerDialog(int initColor) async {
    BuildContext? currentContext = StateController.navigatorKey.currentContext;
    if(currentContext == null) {
      return null;
    }

    return showDialog<int>(
      context: currentContext,
      builder: (BuildContext context) {
        int currentColor = initColor;

        return AlertDialog(
          title: const Text('Wähle eine Farbe',
              style: TextStyle(
                fontSize: 20,
              )),
          content: SingleChildScrollView(
            child: BlockPicker(
              availableColors: ThemeController.eventColors,
              pickerColor: ThemeController.getEventColor(currentColor),
              onColorChanged: (Color pickedColor) {
                currentColor = ThemeController.eventColors.indexOf(pickedColor);
              },
            ),
          ),
          elevation: 3,
          actions: <Widget>[
            TextButton(
              child: Text("Auswählen",
                  style: TextStyle(
                    color: ThemeController.activeTheme().globalAccentColor,
                    fontSize: 18,
                  )),
              onPressed: () {
                Navigator.pop(context, currentColor);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<IconData?> iconPickerDialog(IconData initIcon) async {
    BuildContext? currentContext = StateController.navigatorKey.currentContext;
    if(currentContext == null) {
      return null;
    }

    return showDialog<IconData>(
      context: currentContext,
      builder: (BuildContext context) {
        IconData currentIcon = initIcon;

        return AlertDialog(
          title: const Text('Wähle ein Icon',
              style: TextStyle(
                fontSize: 20,
              )),
          content: SingleChildScrollView(
            child: IconPicker(
              pickerIcon: currentIcon,
              onIconChanged: (IconData pickedIcon) {
                currentIcon = pickedIcon;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Auswählen",
                  style: TextStyle(
                    color: ThemeController.activeTheme().globalAccentColor,
                    fontSize: 18,
                  )),
              onPressed: () {
                Navigator.pop(context, currentIcon);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<TimeOfDay?> timePickerDialog(TimeOfDay initTime) async {
    BuildContext? currentContext = StateController.navigatorKey.currentContext;
    if(currentContext == null) {
      return null;
    }

    return showDialog<TimeOfDay>(
        context: currentContext,
        builder: (BuildContext context) {
          TimeOfDay currentTime = initTime;

          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            // content: TimePickerWidget(
            //     maxDateTime: DateTime(0, 0, 0, 23, 59),
            //     minDateTime: DateTime(0, 0, 0, 0, 0),
            //     dateFormat: "HH:mm",
            //     initDateTime: DateTime(0, 0, 0, currentTime.hour, currentTime.minute),
            //     locale: DateTimePickerLocale.de,
            //     pickerTheme: DateTimePickerTheme(
            //         itemTextStyle: TextStyle(color: ThemeController.activeTheme().infoDialogTextColor),
            //         showTitle: false,
            //         backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
            //         pickerHeight: 120,
            //         itemHeight: 40),
            //     onChange: (selectedTime, selectedIndex) {
            //       currentTime = TimeOfDay(hour: selectedTime.hour, minute: selectedTime.minute);
            //     }),
            elevation: 3,
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Ok',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pop(context, currentTime);
                },
              ),
              TextButton(
                child: Text(
                  'Abbrechen',
                  style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pop(context, null);
                },
              ),
            ],
          );
        });
  }

  static Future<tz.Location?> timezonePickerDialog(tz.Location initLocation) async {
    BuildContext? currentContext = StateController.navigatorKey.currentContext;
    if(currentContext == null) {
      return null;
    }

    List<String> locationKeyList = tz.timeZoneDatabase.locations.keys.toList(growable: false);

    return showDialog<tz.Location>(
      context: currentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wähle eine Zeitzone',
              style: TextStyle(
                fontSize: 20,
              )),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: locationKeyList.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  selected: initLocation.name == tz.timeZoneDatabase.locations[locationKeyList[index]]?.name,
                  title: Text(tz.timeZoneDatabase.locations[locationKeyList[index]]?.name ?? "--"),
                  trailing: const Icon(Icons.keyboard_arrow_right, size: 26,),
                  onTap: () {
                    Navigator.pop(context, tz.timeZoneDatabase.locations[locationKeyList[index]]);
                  },
                );
              },
            ),
          ),
          elevation: 3,
        );
      },
    );
  }

  static Future<StateCode?> stateCodePickerDialog(StateCode initStateCode) async {
    BuildContext? currentContext = StateController.navigatorKey.currentContext;
    if(currentContext == null) {
      return null;
    }

    List<StateCode> stateList = StateCode.values;

    return showDialog<StateCode>(
      context: currentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wähle ein Bundesland',
              style: TextStyle(
                fontSize: 20,
              )),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: stateList.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  selected: stateList[index] == initStateCode,
                  title: Text(StateCodeConverter.getStateName(stateList[index])),
                  trailing: const Icon(Icons.keyboard_arrow_right, size: 26,),
                  onTap: () {
                    Navigator.pop(context, stateList[index]);
                  },
                );
              },
            ),
          ),
          elevation: 3,
        );
      },
    );
  }
}
