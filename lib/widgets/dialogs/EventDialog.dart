import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/main.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/AvatarImageProvider.dart';
import 'package:xitem/utils/CustomScrollBehavior.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xitem/widgets/dialogs/PickerDialog.dart';
import 'package:xitem/widgets/dialogs/UserDialog.dart';

class EventDialog {

  static Future<EventData?> showEventSettingDialog(Calendar calendar, List<Calendar> calendarList, {Event? event, bool calendarChangeable = false, DateTime? initTime}) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return null;
    }

    initTime ??= DateTime.now();

    bool editEvent = false;

    final dateFormat = DateFormat.yMMMEd('de_DE');
    final timeFormat = DateFormat.Hm('de_DE');

    final TextEditingController title = TextEditingController();
    final TextEditingController description = TextEditingController();

    DateTime startDate = DateTime(initTime.year, initTime.month, initTime.day, initTime.hour, 0, 0);
    DateTime endDate = DateTime(initTime.year, initTime.month, initTime.day, initTime.hour + 1, 0, 0);
    bool daylong = false;

    int currentColor = Xitem.settingController.getEventStandardColor();

    if (event != null) {
      editEvent = true;

      title.text = event.title;
      startDate = event.start;
      endDate = event.end;
      daylong = event.dayLong;
      currentColor = event.color;
      description.text = event.description ?? "";
    }

    return showDialog<EventData>(
        context: buildContext,
        builder: (BuildContext context) {
          return ScrollConfiguration(
            behavior: const CustomScrollBehavior(false, false),
            child: AlertDialog(
              elevation: 5,
              title: Center(
                child: Text(
                  editEvent ? "Event bearbeiten" : "Event erstellen",
                  style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              scrollable: true,
              backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
              content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return SizedBox(
                  width: 800,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(hintText: "Event Titel"),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      calendarChangeable ? DropdownButton<Calendar>(
                              value: calendar,
                              hint: const Text("Kalender"),
                              icon: Icon(Icons.keyboard_arrow_down, color: ThemeController.activeTheme().iconColor),
                              iconSize: 30,
                              underline: Container(),
                              isExpanded: true,
                              onTap: () {
                                FocusScope.of(context).unfocus();
                              },
                              onChanged: (Calendar? selectedCalendar) {
                                if(selectedCalendar != null) {
                                  setState(() {
                                    calendar = selectedCalendar;
                                  });
                                }
                              },
                              items: calendarList.map((Calendar element) => DropdownMenuItem<Calendar>(
                                        value: element,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Icon(
                                              element.icon,
                                              color: ThemeController.getEventColor(element.color),
                                              size: 30,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              element.name,
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
                          : const Center(),
                      calendarChangeable ? const SizedBox(height: 10) : const Center(),
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
                              const SizedBox(
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
                            value: daylong,
                            onChanged: (value) {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                daylong = value;
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
                              margin: const EdgeInsets.fromLTRB(2, 10, 0, 10),
                              child: Text(
                                dateFormat.format(startDate),
                                style: TextStyle(
                                  color: ThemeController.activeTheme().textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            onTap: () {
                              FocusScope.of(context).unfocus();

                              showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(1900, 1, 1), lastDate: DateTime(2200, 12, 31)).then((selectedDate) {
                                if (selectedDate == null) return;

                                setState(() {
                                  startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startDate.hour, startDate.minute);

                                  if (endDate.isBefore(startDate)) endDate = startDate.add(const Duration(hours: 1));
                                });
                              });
                            },
                          ),
                          daylong
                              ? const Center()
                              : InkWell(
                                  child: Container(
                                    margin: const EdgeInsets.fromLTRB(0, 10, 2, 10),
                                    child: Text(
                                      timeFormat.format(startDate),
                                      style: TextStyle(
                                        color: ThemeController.activeTheme().textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    FocusScope.of(context).unfocus();

                                    PickerDialog.timePickerDialog(TimeOfDay(hour: startDate.hour, minute: startDate.minute)).then((selectedTime) {
                                      if (selectedTime != null) {
                                        setState(() {
                                          startDate = DateTime(startDate.year, startDate.month, startDate.day, selectedTime.hour, selectedTime.minute);
                                          if (endDate.isBefore(startDate)) endDate = startDate.add(const Duration(hours: 1));
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
                              margin: const EdgeInsets.fromLTRB(2, 10, 0, 10),
                              child: Text(
                                dateFormat.format(endDate),
                                style: TextStyle(
                                  color: ThemeController.activeTheme().textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            onTap: () {
                              FocusScope.of(context).unfocus();

                              showDatePicker(context: context, initialDate: endDate, firstDate: startDate, lastDate: DateTime(2200, 12, 31)).then((selectedDate) {
                                if (selectedDate == null) return;

                                setState(() {
                                  endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endDate.hour, endDate.minute);

                                  if (endDate.isBefore(startDate)) endDate = startDate;
                                });
                              });
                            },
                          ),
                          daylong
                              ? const Center()
                              : InkWell(
                                  child: Container(
                                    margin: const EdgeInsets.fromLTRB(0, 10, 2, 10),
                                    child: Text(
                                      timeFormat.format(endDate),
                                      style: TextStyle(
                                        color: ThemeController.activeTheme().textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    FocusScope.of(context).unfocus();

                                    PickerDialog.timePickerDialog(TimeOfDay(hour: endDate.hour, minute: endDate.minute)).then((selectedTime) {
                                      if (selectedTime != null) {
                                        setState(() {
                                          endDate = DateTime(endDate.year, endDate.month, endDate.day, selectedTime.hour, selectedTime.minute);

                                          if (endDate.isBefore(startDate)) endDate = startDate;
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

                          PickerDialog.eventColorPickerDialog(currentColor).then((selectedColor) {
                            if (selectedColor != null) {
                              setState(() {
                                currentColor = selectedColor;
                              });
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Icon(
                                Icons.brush,
                                size: 30,
                                color: ThemeController.getEventColor(currentColor),
                              ),
                              const SizedBox(
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
                        controller: description,
                        decoration: const InputDecoration(hintText: "Beschreibung"),
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                  ),
                );
              }),
              actions: <Widget>[
                TextButton(
                  child: Text(editEvent ? 'Speichern' : "Erstellen", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                  onPressed: () {
                    EventData data = EventData(calendar.id, title.text, startDate, endDate, daylong, currentColor, description.text);
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
            ),
          );
        });
  }

  static Future<void> showEventInformation(Event event, Calendar calendar, User? creator) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if(buildContext == null) {
      return;
    }

    return showDialog<void>(
        context: buildContext,
        builder: (BuildContext context) {
          final dateFormat = DateFormat("EEEE, d. MMM", "de_DE");
          final timeFormat = DateFormat.Hm('de_DE');

          final creationDateFormat = DateFormat.yMMMMd("de_DE");

          String firstDateLine = "";
          String secondDateLine = "";

          String name = event.title;
          String description = event.description ?? "";

          DateTime startDate = event.start;
          DateTime endDate = event.end;

          bool daylong = event.dayLong;
          Color currentColor = ThemeController.getEventColor(event.color);

          if (startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day) {
            if (daylong) {
              firstDateLine = dateFormat.format(startDate);
            } else {
              firstDateLine = dateFormat.format(startDate);
              secondDateLine = "${timeFormat.format(startDate)} - ${timeFormat.format(endDate)} Uhr";
            }
          } else {
            if (daylong) {
              firstDateLine = "${dateFormat.format(startDate)} -";
              secondDateLine = dateFormat.format(endDate);
            } else {
              firstDateLine = "${dateFormat.format(startDate)}, ${timeFormat.format(startDate)} -";
              secondDateLine = "${dateFormat.format(endDate)}, ${timeFormat.format(endDate)}";
            }
          }

          return ScrollConfiguration(
            behavior: const CustomScrollBehavior(false, false),
            child: AlertDialog(
              elevation: 5,
              titlePadding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              title: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 17,
                  ),
                  Divider(
                    color: currentColor,
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
                            ? const Center()
                            : Container(
                                margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
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
                (description == "")
                    ? const Center()
                    : const SizedBox(
                        height: 15,
                      ),
                (description == "")
                    ? const Center()
                    : Text(
                        "Notiz:",
                        style: TextStyle(
                          color: ThemeController.activeTheme().headlineColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(
                  height: 5,
                ),
                (description == "")
                    ? const Center()
                    : Text(
                        description,
                        style: TextStyle(
                          color: ThemeController.activeTheme().textColor,
                          fontSize: 16,
                        ),
                      ),
                const SizedBox(
                  height: 5,
                ),
                Divider(
                  color: ThemeController.activeTheme().dividerColor,
                  height: 15,
                  thickness: 2,
                ),
                const SizedBox(
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
                          calendar.icon,
                          color: ThemeController.getEventColor(calendar.color),
                          size: 30,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          calendar.name,
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Icon(
                    Icons.person,
                    size: 30,
                    color: ThemeController.activeTheme().iconColor,
                  ),
                  creator == null ? Text(
                    "Unbekannt",
                    style: TextStyle(
                      color: ThemeController.activeTheme().textColor,
                      fontSize: 16,
                    ),
                  ) : GestureDetector(
                    onTap: () async {
                      UserDialog.userInformationPopup(creator);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          creator.name,
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          backgroundImage: AvatarImageProvider.get(creator.avatar),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(
                  height: 5,
                ),
                Divider(
                  color: ThemeController.activeTheme().dividerColor,
                  height: 15,
                  thickness: 2,
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Erstellt am: ${creationDateFormat.format(event.creationDate)}",
                      style: TextStyle(
                        color: ThemeController.activeTheme().textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ]),
              contentPadding: const EdgeInsets.fromLTRB(25, 25, 25, 5),
              actionsPadding: EdgeInsets.zero,
              actions: <Widget>[
                TextButton(
                  child: Text("Schließen", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }
}
