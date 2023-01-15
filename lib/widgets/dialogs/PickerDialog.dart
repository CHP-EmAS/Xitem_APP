import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/utils/StateCodeConverter.dart';
import 'package:xitem/widgets/IconPicker.dart';

class PickerDialog {
  static Future<int?> eventColorPickerDialog({required int initialColor, Map<int, String>? colorLegend}) async {
    BuildContext? currentContext = StateController.navigatorKey.currentContext;
    if (currentContext == null) {
      return null;
    }

    return showDialog<int>(
      context: currentContext,
      builder: (BuildContext context) {
        int currentColor = initialColor;

        return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: colorLegend == null
                ? const Text('Wähle eine Farbe',
                    style: TextStyle(
                      fontSize: 20,
                    ))
                : Text(
                    colorLegend[currentColor] ?? "Keine Beschreibung",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
            content: SingleChildScrollView(
              child: BlockPicker(
                availableColors: ThemeController.eventColors,
                pickerColor: ThemeController.getEventColor(currentColor),
                onColorChanged: (Color pickedColor) {
                  setState(() {
                    currentColor = ThemeController.eventColors.indexOf(pickedColor);
                  });
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
        });
      },
    );
  }

  static Future<int?> iconPickerDialog(int initIconIndex) async {
    BuildContext? currentContext = StateController.navigatorKey.currentContext;
    if (currentContext == null) {
      return null;
    }

    return showDialog<int>(
      context: currentContext,
      builder: (BuildContext context) {
        int currentIconIndex = initIconIndex;

        return AlertDialog(
          title: const Text('Wähle ein Icon',
              style: TextStyle(
                fontSize: 20,
              )),
          content: SingleChildScrollView(
            child: IconPicker(
              currentIconIndex: initIconIndex,
              onIconChanged: (int pickedIconIndex) {
                currentIconIndex = pickedIconIndex;
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
                Navigator.pop(context, currentIconIndex);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<tz.Location?> timezonePickerDialog(tz.Location initLocation) async {
    BuildContext? currentContext = StateController.navigatorKey.currentContext;
    if (currentContext == null) {
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
                  trailing: const Icon(
                    Icons.keyboard_arrow_right,
                    size: 26,
                  ),
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
    if (currentContext == null) {
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
                  trailing: const Icon(
                    Icons.keyboard_arrow_right,
                    size: 26,
                  ),
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
