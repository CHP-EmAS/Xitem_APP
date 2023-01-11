import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/main.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/CustomScrollBehavior.dart';
import 'package:xitem/widgets/dialogs/PickerDialog.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key, required this.arguments});

  final EventPageArguments arguments;

  @override
  State<StatefulWidget> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late final DateTime _initialDate = widget.arguments.initialStartDate ?? DateTime.now();
  late final bool _editMode = widget.arguments.eventToEdit != null ? true : false;

  final _dateFormat = DateFormat.yMMMEd('de_DE');
  final _timeFormat = DateFormat.Hm('de_DE');

  late Calendar _selectedCalendar = widget.arguments.initialCalendar;

  late DateTime _startDate = DateTime(_initialDate.year, _initialDate.month, _initialDate.day, _initialDate.hour, 0, 0);
  late DateTime _endDate = DateTime(_initialDate.year, _initialDate.month, _initialDate.day, _initialDate.hour + 1, 0, 0);

  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();

  bool _daylong = false;
  int _currentColor = Xitem.settingController.getEventStandardColor();

  @override
  void initState() {
    super.initState();

    if (widget.arguments.calendarList.every((element) => element.id != widget.arguments.initialCalendar.id)) {
      widget.arguments.calendarList.add(widget.arguments.initialCalendar);
    }

    Event? tmpEvent = widget.arguments.eventToEdit;
    if (tmpEvent != null) {
      _title.text = tmpEvent.title;
      _startDate = tmpEvent.start;
      _endDate = tmpEvent.end;
      _daylong = tmpEvent.dayLong;
      _currentColor = tmpEvent.color;
      _description.text = tmpEvent.description ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            color: ThemeController.activeTheme().iconColor,
            onPressed: () {
              StateController.navigatorKey.currentState?.pop();
            },
          ),
          title: Text(
            _editMode ? "Termin bearbeiten" : "Termin erstellen",
            style: TextStyle(
              color: ThemeController.activeTheme().textColor,
            ),
          ),
          centerTitle: true,
          actions: [IconButton(icon: const Icon(Icons.check, color: Colors.lightGreen, size: 28), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18), onPressed: _onCheckPressed)],
          backgroundColor: ThemeController.activeTheme().foregroundColor,
          elevation: 3,
        ),
        backgroundColor: ThemeController.activeTheme().backgroundColor,
        body: ScrollConfiguration(
            behavior: const CustomScrollBehavior(false, true),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    //Titel
                    TextField(
                      controller: _title,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: "Titel", focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber, width: 2))),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    //Calendar
                    if (widget.arguments.calendarChangeable && !_editMode) _buildCalendarSelector(),
                    //Day Long
                    _buildDayLongSelector(),
                    //Start Date
                    _buildDateTimeSelector(
                      dateTime: _startDate,
                      onDateTap: () => _onDateTapped(_DateTimeType.startDate),
                      onTimeTap: () => _onTimeTapped(_DateTimeType.startDate),
                    ),
                    //End Date
                    _buildDateTimeSelector(
                      dateTime: _endDate,
                      onDateTap: () => _onDateTapped(_DateTimeType.endDate),
                      onTimeTap: () => _onTimeTapped(_DateTimeType.endDate),
                    ),
                    Divider(
                      thickness: 2,
                      height: 20,
                      color: ThemeController.activeTheme().dividerColor,
                    ),
                    //Color
                    _buildColorSelector(),
                    Divider(
                      thickness: 2,
                      height: 20,
                      color: ThemeController.activeTheme().dividerColor,
                    ),
                    //Description
                    TextField(
                      maxLength: 200,
                      controller: _description,
                      decoration: const InputDecoration(hintText: "Beschreibung", focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber, width: 2))),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                    ),
                  ],
                ),
              ),
            )));
  }

  Widget _buildCalendarSelector() {
    return Column(
      children: [
        DropdownButton<Calendar>(
          value: _selectedCalendar,
          hint: const Text("Kalender"),
          icon: Icon(Icons.keyboard_arrow_down, color: ThemeController.activeTheme().iconColor),
          iconSize: 30,
          underline: Container(),
          isExpanded: true,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          onChanged: (Calendar? newCalendar) {
            if (newCalendar != null) {
              setState(() {
                _selectedCalendar = newCalendar;
              });
            }
          },
          items: widget.arguments.calendarList
              .map((Calendar element) => DropdownMenuItem<Calendar>(
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
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDayLongSelector() {
    return Row(
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
        Transform.translate(
            offset: const Offset(10.0, 0.0),
            child: Switch(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              value: _daylong,
              onChanged: (value) {
                FocusScope.of(context).unfocus();
                setState(() {
                  _daylong = value;
                });
              },
              activeTrackColor: Colors.amber,
              activeColor: Colors.amberAccent,
            )),
      ],
    );
  }

  Widget _buildDateTimeSelector({required DateTime dateTime, required VoidCallback onDateTap, required VoidCallback onTimeTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        InkWell(
          onTap: onDateTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(2, 10, 0, 10),
            child: Text(
              _dateFormat.format(dateTime),
              style: TextStyle(
                color: ThemeController.activeTheme().textColor,
                fontSize: 16,
              ),
            ),
          ),
        ),
        _daylong
            ? const Center()
            : InkWell(
                onTap: onTimeTap,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 10, 2, 10),
                  child: Text(
                    _timeFormat.format(dateTime),
                    style: TextStyle(
                      color: ThemeController.activeTheme().textColor,
                      fontSize: 16,
                    ),
                  ),
                )),
      ],
    );
  }

  Widget _buildColorSelector() {
    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();

        PickerDialog.eventColorPickerDialog(initialColor: _currentColor, colorLegend: _selectedCalendar.colorLegend).then((selectedColor) {
          if (selectedColor != null) {
            setState(() {
              _currentColor = selectedColor;
            });
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.color_lens_outlined,
                  size: 30,
                  color: ThemeController.activeTheme().iconColor,
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  "Farbe",
                  style: TextStyle(
                    color: ThemeController.activeTheme().textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  _selectedCalendar.colorLegend[_currentColor] ?? "",
                  style: TextStyle(
                    color: ThemeController.activeTheme().textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ThemeController.getEventColor(_currentColor),
                    boxShadow: [BoxShadow(color: ThemeController.getEventColor(_currentColor).withOpacity(0.8), offset: const Offset(1, 2), blurRadius: 5)],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _onCheckPressed() async {
    EventData eventData = EventData(_selectedCalendar, _title.text, _startDate, _endDate, _daylong, _currentColor, _description.text);

    bool success = false;
    if (_editMode) {
      Event? tmpEvent = widget.arguments.eventToEdit;
      if (tmpEvent != null) {
        success = await _onEditEvent(eventData, tmpEvent);
      }
    } else {
      success = await _onCreateEvent(eventData);
    }

    if (success) {
      StateController.navigatorKey.currentState?.pop();
    }
  }

  void _onDateTapped(_DateTimeType type) async {
    FocusScope.of(context).unfocus();

    if(type == _DateTimeType.startDate) {
      showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(1900, 1, 1), lastDate: DateTime(2200, 12, 31)).then((selectedDate) {
        if (selectedDate == null) return;

        setState(() {
          _startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, _startDate.hour, _startDate.minute);

          if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(const Duration(hours: 1));
        });
      });
    } else {
      showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2200, 12, 31)).then((selectedDate) {
        if (selectedDate == null) return;

        setState(() {
          _endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, _endDate.hour, _endDate.minute);

          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        });
      });
    }
  }

  void _onTimeTapped(_DateTimeType type) async {
    FocusScope.of(context).unfocus();

    if(type == _DateTimeType.startDate) {
      showTimePicker(context: context, initialTime: TimeOfDay(hour: _startDate.hour, minute: _startDate.minute)).then((selectedTime) {
        if (selectedTime != null) {
          setState(() {
            _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day, selectedTime.hour, selectedTime.minute);
            if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(const Duration(hours: 1));
          });
        }
      });
    } else {
      showTimePicker(context: context, initialTime: TimeOfDay(hour: _endDate.hour, minute: _endDate.minute)).then((selectedTime) {
        if (selectedTime != null) {
          setState(() {
            _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, selectedTime.hour, selectedTime.minute);
            if (_endDate.isBefore(_startDate)) _endDate = _startDate;
          });
        }
      });
    }
  }

  Future<bool> _onCreateEvent(EventData newEvent) async {
    StandardDialog.loadingDialog("Erstelle Event...");

    ResponseCode createEvent = await _selectedCalendar.eventController.createEvent(newEvent).catchError((e) {
      return ResponseCode.unknown;
    });

    if (createEvent != ResponseCode.success) {
      StateController.navigatorKey.currentState?.pop();

      String errorMessage;

      switch (createEvent) {
        case ResponseCode.missingArgument:
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case ResponseCode.invalidTitle:
          errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
          break;
        case ResponseCode.endBeforeStart:
          errorMessage = "Das Enddatum muss nach dem Startdatum liegen.";
          break;
        case ResponseCode.startAfter1900:
          errorMessage = "Das Startdatum muss nach dem 01.01.1900 liegen.";
          break;
        case ResponseCode.accessForbidden:
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
          break;
        case ResponseCode.invalidColor:
          errorMessage = "Unzulässige Farbe.";
          break;
        default:
          errorMessage = "Beim Erstellen des Events ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      }

      StandardDialog.okDialog("Event konnte nicht erstellt werden!", errorMessage);
      return false;
    }

    StateController.navigatorKey.currentState?.pop();
    return true;
  }

  Future<bool> _onEditEvent(EventData editedEvent, Event originalEvent) async {
    StandardDialog.loadingDialog("Speichere Änderungen...");

    ResponseCode editEvent = await widget.arguments.initialCalendar.eventController
        .editEvent(originalEvent.eventID, editedEvent.startDate, editedEvent.endDate, editedEvent.title, editedEvent.description, editedEvent.daylong, editedEvent.color)
        .catchError((e) {
      return ResponseCode.unknown;
    });

    if (editEvent != ResponseCode.success) {
      StateController.navigatorKey.currentState?.pop();

      String errorMessage;

      switch (editEvent) {
        case ResponseCode.accessForbidden:
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
          break;
        case ResponseCode.eventNotFound:
          errorMessage = "Event konnte nicht gefunden werden.";
          break;
        case ResponseCode.invalidColor:
          errorMessage = "Unzulässige Farbe.";
          break;
        case ResponseCode.invalidTitle:
          errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
          break;
        case ResponseCode.startAfter1900:
          errorMessage = "Das Startdatum muss nach dem 01.01.1900 liegen.";
          break;
        case ResponseCode.endBeforeStart:
          errorMessage = "Das Enddatum muss nach dem Startdatum liegen.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
      }

      StandardDialog.okDialog("Änderungen konnten nicht gespeichert werden!", errorMessage);
      return false;
    }

    StateController.navigatorKey.currentState?.pop();
    return true;
  }
}

enum _DateTimeType {
  startDate,
  endDate
}

class EventPageArguments {
  final Calendar initialCalendar;
  final List<Calendar> calendarList;
  final bool calendarChangeable;
  final Event? eventToEdit;
  final DateTime? initialStartDate;

  EventPageArguments({required this.initialCalendar, required this.calendarList, calendarChangeable, this.eventToEdit, this.initialStartDate}) : calendarChangeable = calendarChangeable ?? false;
}
