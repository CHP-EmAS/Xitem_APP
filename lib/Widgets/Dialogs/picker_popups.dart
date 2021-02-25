import 'package:de/Controllers/HolidayListController.dart';
import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Settings/locator.dart';
import 'file:///C:/Users/Clemens/Documents/Development/AndroidStudioProjects/xitem/lib/Widgets/icon_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:timezone/timezone.dart' as tz;

class PickerPopup {
  static final NavigationService _navigationService = locator<NavigationService>();

  static Future<Color> showColorPickerDialog(Color initColor) {
    return showDialog<Color>(
      context: _navigationService.navigatorKey.currentContext,
      builder: (BuildContext context) {
        Color _currentColor = initColor;

        return AlertDialog(
          title: Text('Wähle eine Farbe',
              style: TextStyle(
                fontSize: 20,
              )),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _currentColor,
              onColorChanged: (Color pickedColor) {
                _currentColor = pickedColor;
              },
            ),
          ),
          elevation: 3,
          actions: <Widget>[
            new FlatButton(
              child: new Text("Auswählen",
                  style: TextStyle(
                    color: ThemeController.activeTheme().globalAccentColor,
                    fontSize: 18,
                  )),
              onPressed: () {
                _navigationService.pop(_currentColor);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<IconData> showIconPickerDialog(IconData initIcon) {
    print("it's a me!");

    return showDialog<IconData>(
      context: _navigationService.navigatorKey.currentContext,
      builder: (BuildContext context) {
        IconData _currentIcon = initIcon;

        return AlertDialog(
          title: Text('Wähle ein Icon',
              style: TextStyle(
                fontSize: 20,
              )),
          content: SingleChildScrollView(
            child: IconPicker(
              pickerIcon: _currentIcon,
              onIconChanged: (IconData pickedIcon) {
                _currentIcon = pickedIcon;
              },
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Auswählen",
                  style: TextStyle(
                    color: ThemeController.activeTheme().globalAccentColor,
                    fontSize: 18,
                  )),
              onPressed: () {
                _navigationService.pop(_currentIcon);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<tz.Location> showTimezonePickerDialog(tz.Location initLocation) {

    List<String> locationKeyList = tz.timeZoneDatabase.locations.keys.toList(growable: false);

    return showDialog<tz.Location>(
      context: _navigationService.navigatorKey.currentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Wähle eine Zeitzone',
              style: TextStyle(
                fontSize: 20,
              )),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: locationKeyList.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  selected: initLocation.name == tz.timeZoneDatabase.locations[locationKeyList[index]].name,
                  title: Text(tz.timeZoneDatabase.locations[locationKeyList[index]].name),
                  trailing: Icon(Icons.keyboard_arrow_right, size: 26,),
                  onTap: () {
                    _navigationService.pop(tz.timeZoneDatabase.locations[locationKeyList[index]]);
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

  static Future<StateCode> showStateCodePickerDialog(StateCode initStateCode) {
    
    List<StateCode> stateList = StateCode.values;

    return showDialog<StateCode>(
      context: _navigationService.navigatorKey.currentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Wähle ein Bundesland',
              style: TextStyle(
                fontSize: 20,
              )),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: stateList.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  selected: stateList[index] == initStateCode,
                  title: Text(HolidayController.getStateName(stateList[index])),
                  trailing: Icon(Icons.keyboard_arrow_right, size: 26,),
                  onTap: () {
                    _navigationService.pop(stateList[index]);
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
