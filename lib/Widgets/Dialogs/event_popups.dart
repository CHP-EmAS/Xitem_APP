import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/SettingController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Models/Event.dart';
import 'package:de/Models/User.dart';
import 'package:de/Utils/custom_scroll_behavior.dart';
import 'file:///C:/Users/Clemens/Documents/AndroidStudioProjects/live_list/lib/Controller/locator.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/Dialogs/picker_popups.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventData {
  EventData(this.selectedCalendar, this.title, this.startDate, this.endDate, this.daylong, this.color, this.description);

  final String selectedCalendar;

  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool daylong;
  final Color color;
  final String description;
}

class EventPopup {

  static Future<EventData> showEventSettingDialog(String calendarID, {BigInt eventID, bool calendarChangeable = false, DateTime initTime}) async {
    if (initTime == null) {
      initTime = DateTime.now();
    }

    return showDialog<EventData>(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          if (!UserController.calendarList.containsKey(calendarID)) {
            DialogPopup.asyncOkDialog("Unerwarteter Fehler", "Zugehöriger Kalender konnte nicht gefunden werden!");
            _navigationService.pop(null);
          }

          Calendar _calendar = UserController.calendarList[calendarID];

          bool _editEvent = false;

          final dateFormat = new DateFormat.yMMMEd('de_DE');
          final timeFormat = new DateFormat.Hm('de_DE');

          final TextEditingController _title = TextEditingController();
          final TextEditingController _description = TextEditingController();

          DateTime _startDate = DateTime(initTime.year, initTime.month, initTime.day, initTime.hour, 0, 0);
          DateTime _endDate = DateTime(initTime.year, initTime.month, initTime.day, initTime.hour + 1, 0, 0);
          bool _daylong = false;

          Color _currentColor = SettingController.getEventStandardColor();

          if (eventID != null) {
            _editEvent = true;

            if (!_calendar.dynamicEventMap.containsKey(eventID)) {
              DialogPopup.asyncOkDialog("Unerwarteter Fehler", "Event konnte nicht gefunden werden!");
              _navigationService.pop();
            }

            Event loadedEvent = _calendar.dynamicEventMap[eventID];

            _title.text = loadedEvent.title;
            _startDate = loadedEvent.start;
            _endDate = loadedEvent.end;
            _daylong = loadedEvent.dayLong;
            _currentColor = loadedEvent.color;
            _description.text = loadedEvent.description;
          }

          return ScrollConfiguration(
            behavior: CustomScrollBehavior(false, false),
            child: AlertDialog(
              elevation: 5,
              title: Center(
                child: Text(
                  _editEvent ? "Event bearbeiten" : "Event erstellen",
                  style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              scrollable: true,
              backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
              content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return Container(
                  width: 800,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: _title,
                        decoration: InputDecoration(hintText: "Event Titel"),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      calendarChangeable
                          ? DropdownButton<Calendar>(
                              value: _calendar,
                              hint: Text("Kalender"),
                              icon: Icon(Icons.keyboard_arrow_down, color: ThemeController.activeTheme().iconColor),
                              iconSize: 30,
                              underline: Container(),
                              isExpanded: true,
                              onTap: () {
                                FocusScope.of(context).unfocus();
                              },
                              onChanged: (Calendar newValue) {
                                setState(() {
                                  _calendar = newValue;
                                });
                              },
                              items: UserController.calendarList.entries
                                  .map<DropdownMenuItem<Calendar>>((MapEntry<String, Calendar> element) => DropdownMenuItem<Calendar>(
                                        value: element.value,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Icon(
                                              element.value.icon,
                                              color: element.value.color,
                                              size: 30,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              element.value.name,
                                              style: TextStyle(
                                                color: ThemeController.activeTheme().textColor,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            )
                          : Center(),
                      calendarChangeable ? SizedBox(height: 10) : Center(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 30,
                                color: ThemeController.activeTheme().iconColor,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                "Ganztägig",
                                style: TextStyle(
                                  color: ThemeController.activeTheme().textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _daylong,
                            onChanged: (value) {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _daylong = value;
                              });
                            },
                            activeTrackColor: Colors.amber,
                            activeColor: Colors.amberAccent,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          InkWell(
                            child: Container(
                              margin: EdgeInsets.fromLTRB(2, 10, 0, 10),
                              child: Text(
                                dateFormat.format(_startDate),
                                style: TextStyle(
                                  color: ThemeController.activeTheme().textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            onTap: () {
                              FocusScope.of(context).unfocus();

                              showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(1900, 1, 1), lastDate: DateTime(2200, 12, 31)).then((selectedDate) {
                                if (selectedDate == null) return;

                                setState(() {
                                  _startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, _startDate.hour, _startDate.minute);

                                  if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(Duration(hours: 1));
                                });
                              });
                            },
                          ),
                          _daylong
                              ? Center()
                              : InkWell(
                                  child: Container(
                                    margin: EdgeInsets.fromLTRB(0, 10, 2, 10),
                                    child: Text(
                                      timeFormat.format(_startDate),
                                      style: TextStyle(
                                        color: ThemeController.activeTheme().textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    FocusScope.of(context).unfocus();

                                    DialogPopup.asyncTimeSliderDialog(TimeOfDay(hour: _startDate.hour, minute: _startDate.minute)).then((selectedTime) {
                                      if (selectedTime != null) {
                                        setState(() {
                                          _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day, selectedTime.hour, selectedTime.minute);
                                          if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(Duration(hours: 1));
                                        });
                                      }
                                    });
                                  }),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          InkWell(
                            child: Container(
                              margin: EdgeInsets.fromLTRB(2, 10, 0, 10),
                              child: Text(
                                dateFormat.format(_endDate),
                                style: TextStyle(
                                  color: ThemeController.activeTheme().textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            onTap: () {
                              FocusScope.of(context).unfocus();

                              showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2200, 12, 31)).then((selectedDate) {
                                if (selectedDate == null) return;

                                setState(() {
                                  _endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, _endDate.hour, _endDate.minute);

                                  if (_endDate.isBefore(_startDate)) _endDate = _startDate;
                                });
                              });
                            },
                          ),
                          _daylong
                              ? Center()
                              : InkWell(
                                  child: Container(
                                    margin: EdgeInsets.fromLTRB(0, 10, 2, 10),
                                    child: Text(
                                      timeFormat.format(_endDate),
                                      style: TextStyle(
                                        color: ThemeController.activeTheme().textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    FocusScope.of(context).unfocus();

                                    DialogPopup.asyncTimeSliderDialog(TimeOfDay(hour: _endDate.hour, minute: _endDate.minute)).then((selectedTime) {
                                      if (selectedTime != null) {
                                        setState(() {
                                          _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, selectedTime.hour, selectedTime.minute);

                                          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
                                        });
                                      }
                                    });
                                  },
                                ),
                        ],
                      ),
                      Divider(
                        thickness: 2,
                        height: 20,
                        color: ThemeController.activeTheme().dividerColor,
                      ),
                      InkWell(
                        onTap: () {
                          FocusScope.of(context).unfocus();

                          PickerPopup.showColorPickerDialog(_currentColor).then((selectedColor) {
                            if (selectedColor != null) {
                              setState(() {
                                _currentColor = selectedColor;
                              });
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Icon(
                                Icons.brush,
                                size: 30,
                                color: _currentColor,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                "Event Farbe",
                                style: TextStyle(
                                  color: ThemeController.activeTheme().textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        thickness: 2,
                        height: 20,
                        color: ThemeController.activeTheme().dividerColor,
                      ),
                      TextField(
                        maxLength: 200,
                        controller: _description,
                        decoration: InputDecoration(hintText: "Beschreibung"),
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                  ),
                );
              }),
              actions: <Widget>[
                new FlatButton(
                  child: new Text(_editEvent ? 'Speichern' : "Erstellen", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                  onPressed: () {
                    EventData data = new EventData(_calendar.id, _title.text, _startDate, _endDate, _daylong, _currentColor, _description.text);
                    _navigationService.pop(data);
                  },
                ),
                new FlatButton(
                  child: new Text('Abbrechen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                  onPressed: () {
                    _navigationService.pop(null);
                  },
                ),
              ],
            ),
          );
        });
  }

  static Future<void> showEventInformation(String calendarID, BigInt eventID) async {
    return showDialog<EventData>(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          if (!UserController.calendarList.containsKey(calendarID)) {
            DialogPopup.asyncOkDialog("Unerwarteter Fehler", "Zugehöriger Kalender konnte nicht gefunden werden!");
            _navigationService.pop(null);
          }

          Calendar _calendar = UserController.calendarList[calendarID];

          if (!_calendar.dynamicEventMap.containsKey(eventID)) {
            DialogPopup.asyncOkDialog("Unerwarteter Fehler", "Event konnte nicht gefunden werden!");
            _navigationService.pop(null);
          }

          Event loadedEvent = _calendar.dynamicEventMap[eventID];

          final dateFormat = new DateFormat("EEEE, d. MMM", "de_DE");
          final timeFormat = new DateFormat.Hm('de_DE');

          final creationDateFormat = new DateFormat.yMMMMd("de_DE");

          String firstDateLine = "";
          String secondDateLine = "";

          String _name = loadedEvent.title;
          String _description = loadedEvent.description == null ? "" : loadedEvent.description;

          DateTime _startDate = loadedEvent.start;
          DateTime _endDate = loadedEvent.end;

          bool _daylong = loadedEvent.dayLong;
          Color _currentColor = loadedEvent.color;

          PublicUser creatorData = UserController.getPublicUserInformation(loadedEvent.userID);
          if (creatorData == null) {
            creatorData = UserController.unknownUser;
          }

          if (_startDate.year == _endDate.year && _startDate.month == _endDate.month && _startDate.day == _endDate.day) {
            if (_daylong) {
              firstDateLine = dateFormat.format(_startDate);
            } else {
              firstDateLine = dateFormat.format(_startDate);
              secondDateLine = timeFormat.format(_startDate) + " - " + timeFormat.format(_endDate) + " Uhr";
            }
          } else {
            if (_daylong) {
              firstDateLine = dateFormat.format(_startDate) + " -";
              secondDateLine = dateFormat.format(_endDate);
            } else {
              firstDateLine = dateFormat.format(_startDate) + ", " + timeFormat.format(_startDate) + " -";
              secondDateLine = dateFormat.format(_endDate) + ", " + timeFormat.format(_endDate);
            }
          }

          return ScrollConfiguration(
            behavior: CustomScrollBehavior(false, false),
            child: AlertDialog(
              elevation: 5,
              titlePadding: EdgeInsets.fromLTRB(0, 15, 0, 0),
              title: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      _name,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 17,
                  ),
                  Divider(
                    color: _currentColor,
                    height: 0,
                    thickness: 3,
                  ),
                ],
              ),
              scrollable: true,
              backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
              content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 30,
                      color: ThemeController.activeTheme().iconColor,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          firstDateLine,
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                        (secondDateLine == "")
                            ? Center()
                            : Container(
                                margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                child: Text(
                                  secondDateLine,
                                  style: TextStyle(
                                    color: ThemeController.activeTheme().textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
                (_description == "")
                    ? Center()
                    : SizedBox(
                        height: 15,
                      ),
                (_description == "")
                    ? Center()
                    : Text(
                        "Notiz:",
                        style: TextStyle(
                          color: ThemeController.activeTheme().headlineColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                SizedBox(
                  height: 5,
                ),
                (_description == "")
                    ? Center()
                    : Text(
                        _description,
                        style: TextStyle(
                          color: ThemeController.activeTheme().textColor,
                          fontSize: 16,
                        ),
                      ),
                SizedBox(
                  height: 5,
                ),
                Divider(
                  color: ThemeController.activeTheme().dividerColor,
                  height: 15,
                  thickness: 2,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 30,
                      color: ThemeController.activeTheme().iconColor,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          _calendar.icon,
                          color: _calendar.color,
                          size: 30,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          _calendar.name,
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Icon(
                    Icons.person,
                    size: 30,
                    color: ThemeController.activeTheme().iconColor,
                  ),
                  GestureDetector(
                    onTap: () async {
                      DialogPopup.asyncUserInformationPopup(creatorData.userID);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          creatorData.name,
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          backgroundImage: creatorData.avatar != null ? FileImage(creatorData.avatar) : AssetImage("images/avatar.png"),
                        ),
                      ],
                    ),
                  ),
                ]),
                SizedBox(
                  height: 5,
                ),
                Divider(
                  color: ThemeController.activeTheme().dividerColor,
                  height: 15,
                  thickness: 2,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Erstellt am: " + creationDateFormat.format(loadedEvent.creationDate),
                      style: TextStyle(
                        color: ThemeController.activeTheme().textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ]),
              contentPadding: EdgeInsets.fromLTRB(25, 25, 25, 5),
              actionsPadding: EdgeInsets.zero,
              actions: <Widget>[
                new FlatButton(
                  child: new Text("Schließen", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                  onPressed: () {
                    _navigationService.pop();
                  },
                ),
              ],
            ),
          );
        });
  }
}
