import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/HolidayListController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Utils/custom_scroll_behavior.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/Dialogs/event_popups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  CalendarPage({Key key, @required this.linkedCalendar});

  final Calendar linkedCalendar;

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with TickerProviderStateMixin {
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();

  static const List<CalendarMenuChoice> _calendarMenuChoicesMember = const <CalendarMenuChoice>[
    const CalendarMenuChoice(menuStatus: CalendarMenuStatus.NOTES_AND_VOTES, title: 'Notizen & Abstimmungen', icon: Icons.sticky_note_2_outlined),
    const CalendarMenuChoice(menuStatus: CalendarMenuStatus.SETTINGS, title: 'Kalender Einstellungen', icon: Icons.settings),
  ];

  static const List<CalendarMenuChoice> _calendarMenuChoicesAdmin = const <CalendarMenuChoice>[
    const CalendarMenuChoice(menuStatus: CalendarMenuStatus.NOTES_AND_VOTES, title: 'Notizen & Abstimmungen', icon: Icons.sticky_note_2_outlined),
    const CalendarMenuChoice(menuStatus: CalendarMenuStatus.QR_INVITATION, title: 'QR Einladung erstellen', icon: Icons.qr_code),
    const CalendarMenuChoice(menuStatus: CalendarMenuStatus.SETTINGS, title: 'Kalender Einstellungen', icon: Icons.settings),
  ];

  List<CalendarMenuChoice> _calendarMenuChoices;

  Map<DateTime, List<dynamic>> _events = new Map<DateTime, List<dynamic>>();
  Map<DateTime, List<dynamic>> _holidays = new Map<DateTime, List<dynamic>>();

  List<dynamic> _selectedEvents;
  List<dynamic> _selectedHolidays;

  AnimationController _animationController;
  CalendarController _calendarController;

  bool _isLoadingEvents = false;
  bool _showAddEventButton = true;

  DateTime currentVisibleMonth;

  @override
  void initState() {
    super.initState();

    _calendarMenuChoices = widget.linkedCalendar.isOwner ? _calendarMenuChoicesAdmin : _calendarMenuChoicesMember;

    final DateTime now = DateTime.now();
    final selectedDay = DateTime(now.year, now.month, now.day);
    final currentVisibleMonth = DateTime(now.year, now.month);

    setState(() {
      _isLoadingEvents = true;
    });

    _selectedEvents = [];
    _selectedHolidays = [];

    widget.linkedCalendar.getUiEvents(selectedDay.year, selectedDay.month).then((list) {
      if (currentVisibleMonth.year == now.year && currentVisibleMonth.month == now.month) {
        setState(() {
          _events = list;
          _selectedEvents = _events[selectedDay] ?? [];
          _isLoadingEvents = false;
        });
      }
    });

    HolidayController.loadedHolidays.forEach((holiday) {
      DateTime holidayDate = DateTime(holiday.date.year, holiday.date.month, holiday.date.day);

      if(!_holidays.containsKey(holidayDate)) {
        _holidays[holidayDate] = [];
      }

      _holidays[holidayDate].add(holiday.name);

      if(holidayDate == selectedDay) {
        _selectedHolidays.add(holiday.name);
      }
    });

    _calendarController = CalendarController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _selectMenuChoice(CalendarMenuChoice choice) async {
    if (choice.menuStatus == CalendarMenuStatus.SETTINGS) {
      Navigator.pushNamed(context, '/calendarSettings', arguments: widget.linkedCalendar);
    } else if (choice.menuStatus == CalendarMenuStatus.NOTES_AND_VOTES) {
      Navigator.pushNamed(context, '/calendarNotesAndVotes', arguments: widget.linkedCalendar);
    } else if (choice.menuStatus == CalendarMenuStatus.QR_INVITATION) {
      await createQRCode();
    }
  }

  Future<bool> createQRCode() async {
    InvitationRequest invitationData = await DialogPopup.asyncCreateQRCodePopup(widget.linkedCalendar.id);
    if (invitationData == null) return false;

    String invitationToken = await widget.linkedCalendar.getInvitationToken(invitationData.canCreateEvents, invitationData.canEditEvents, invitationData.duration);
    if (invitationToken == null) {
      await DialogPopup.asyncOkDialog("QR-Code konnte nicht erstellt werden!", Api.errorMessage);
      return false;
    }

    invitationToken = '{"n":"${widget.linkedCalendar.name}","k":"' + invitationToken + '"}';
    await DialogPopup.asyncShowQRCodePopup(invitationToken);
    return true;
  }

  Future<void> _rebuildOnSpecificDate(DateTime initDate) async {
    await _onVisibleDaysChanged(DateTime(initDate.year, initDate.month, 1), DateTime(initDate.year, initDate.month + 1, 0), _calendarController.calendarFormat);

    _calendarController.setSelectedDay(
      DateTime(initDate.year, initDate.month, initDate.day),
      runCallback: true,
    );

    setState(() {
      _selectedEvents = widget.linkedCalendar.loadedUIMonths[initDate.year.toString() + initDate.month.toString()].uiEvents[DateTime(initDate.year, initDate.month, initDate.day)];
    });
  }

  void _addEvent(EventData newEvent) async {
    Calendar selectedCalendar = UserController.calendarList[newEvent.selectedCalendar];

    if (selectedCalendar == null) {
      DialogPopup.asyncOkDialog("Event konnten nicht erstellt werden!", "Der Ausgewählte Kalender konnte nicht gefunden werden!");
      return;
    }

    DialogPopup.asyncLoadingDialog(_keyLoader, "Erstelle Event...");

    bool success = await selectedCalendar.createEvent(newEvent).catchError((e) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      return false;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!success) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      DialogPopup.asyncOkDialog("Event konnten nicht erstellt werden!", Api.errorMessage);
    } else {
      if (selectedCalendar.id == widget.linkedCalendar.id) {
        await _rebuildOnSpecificDate(newEvent.startDate);
      }

      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
    }
  }

  void _editEvent(BigInt eventID) async {
    EventData editedEvent = await EventPopup.showEventSettingDialog(widget.linkedCalendar.id, eventID: eventID);

    if (editedEvent != null) {
      DialogPopup.asyncLoadingDialog(_keyLoader, "Speichere Änderungen...");

      bool success = await widget.linkedCalendar.editEvent(eventID, editedEvent.startDate, editedEvent.endDate, editedEvent.title, editedEvent.description, editedEvent.daylong, editedEvent.color).catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return false;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!success) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        DialogPopup.asyncOkDialog("Änderungen konnten nicht gespeichert werden!", Api.errorMessage);
      } else {
        await _rebuildOnSpecificDate(editedEvent.startDate);
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      }
    }
  }

  void _deleteEvent(BigInt eventID) async {
    if (await DialogPopup.asyncConfirmDialog("Event löschen?", "Willst du das Event wirklich löschen? Das Event wird endgültig gelöscht und kann nicht wiederhergestellt werden!") ==
        ConfirmAction.OK) {
      DialogPopup.asyncLoadingDialog(_keyLoader, "Lösche Event...");

      bool success = await widget.linkedCalendar.removeEvent(eventID).catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return false;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!success) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        DialogPopup.asyncOkDialog("Event konnten nicht gelöscht werden!", Api.errorMessage);
      } else {
        await _rebuildOnSpecificDate(_calendarController.selectedDay);
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      }
    }
  }

  void _onDaySelected(DateTime day, List<dynamic> events, List<dynamic> holidays) async {
    setState(() {
      _selectedEvents = events;
      _selectedHolidays = holidays;
    });

    print(holidays.length);
  }

  Future<void> _onVisibleDaysChanged(DateTime first, DateTime last, CalendarFormat format) async {
    first = first.add(Duration(days: 7));

    currentVisibleMonth = DateTime(first.year, first.month);

    setState(() {
      _isLoadingEvents = true;
    });

    await widget.linkedCalendar.getUiEvents(first.year, first.month).then((list) {
      if (currentVisibleMonth.year == first.year && currentVisibleMonth.month == first.month) {
        setState(() {
          _events = list;
          _isLoadingEvents = false;
        });
      }
    });
  }

  void _onDayLongPress(DateTime day, List<dynamic> events, List<dynamic> holidays) {
    _calendarController.setSelectedDay(
      DateTime(day.year, day.month, day.day),
      runCallback: true,
    );

    EventPopup.showEventSettingDialog(widget.linkedCalendar.id, initTime: DateTime(day.year, day.month, day.day, 12), calendarChangeable: true).then((EventData newEvent) {
      if (newEvent != null) {
        _addEvent(newEvent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: ThemeController.activeTheme().iconColor, size: 10.0),
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              widget.linkedCalendar.icon,
              color: widget.linkedCalendar.color,
              size: 32,
            ),
            SizedBox(
              width: 15,
            ),
            Text(
              widget.linkedCalendar.name,
              style: TextStyle(color: ThemeController.activeTheme().textColor),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        elevation: 3,
        actions: <Widget>[
          PopupMenuButton<CalendarMenuChoice>(
            onSelected: _selectMenuChoice,
            color: ThemeController.activeTheme().menuPopupBackgroundColor,
            itemBuilder: (BuildContext context) {
              return _calendarMenuChoices.map((CalendarMenuChoice choice) {
                return PopupMenuItem<CalendarMenuChoice>(
                  value: choice,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Icon(
                        choice.icon,
                        color: ThemeController.activeTheme().menuPopupIconColor,
                        size: 25,
                      ),
                      Text(
                        choice.title,
                        style: TextStyle(color: ThemeController.activeTheme().menuPopupTextColor),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: Column(
        children: <Widget>[
          _buildTableCalendarWithBuilders(),
          const SizedBox(
            height: 10,
          ),
          Divider(
            color: ThemeController.activeTheme().dividerColor,
            thickness: 2,
            height: 2,
          ),
          Expanded(child: _buildEventList()),
        ],
      ),
      floatingActionButton: (widget.linkedCalendar.canCreateEvents && _showAddEventButton)
          ? FloatingActionButton(
              onPressed: () async {
                EventData newEvent = await EventPopup.showEventSettingDialog(widget.linkedCalendar.id, initTime: _calendarController.selectedDay, calendarChangeable: true);
                if (newEvent != null) {
                  _addEvent(newEvent);
                }
              },
              backgroundColor: ThemeController.activeTheme().actionButtonColor,
              tooltip: "Event erstellen",
              child: Icon(
                Icons.add,
                color: ThemeController.activeTheme().textColor,
                size: 30,
              ),
            )
          : Center(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // More advanced TableCalendar configuration (using Builders & Styles)
  Widget _buildTableCalendarWithBuilders() {
    return TableCalendar(
      locale: 'de_DE',
      calendarController: _calendarController,
      events: _events,
      holidays: _holidays,
      initialCalendarFormat: CalendarFormat.month,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.all,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Monat',
        CalendarFormat.week: 'Woche',
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        selectedColor: Colors.amber,
        todayColor: Colors.amberAccent,
        weekdayStyle: TextStyle().copyWith(color: ThemeController.activeTheme().textColor),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle().copyWith(color: ThemeController.activeTheme().textColor),
        weekendStyle: TextStyle().copyWith(color: ThemeController.activeTheme().textColor),
      ),
      headerStyle: HeaderStyle(
        titleTextStyle: TextStyle().copyWith(color: ThemeController.activeTheme().textColor, fontSize: 18),
        formatButtonTextStyle: TextStyle().copyWith(color: ThemeController.activeTheme().textColor),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: ThemeController.activeTheme().textColor,
          size: 30,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: ThemeController.activeTheme().textColor,
          size: 30,
        ),
        formatButtonDecoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: ThemeController.activeTheme().iconColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        centerHeaderTitle: true,
        formatButtonVisible: true,
      ),
      builders: CalendarBuilders(
        markersBuilder: (context, date, events, holidays) {
          final children = <Widget>[];

          if (events.isNotEmpty) {
            children.add(
              Positioned(
                bottom: 5.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(5).map((event) => _buildMarker(event)).toList(),
                ),
              ),
            );
          }

          return children;
        },
      ),
      onDaySelected: (date, events, holidays) {
        _onDaySelected(date, events,holidays);
        _animationController.forward(from: 0.0);
      },
      onDayLongPressed: _onDayLongPress,
      onVisibleDaysChanged: _onVisibleDaysChanged,
    );
  }

  Widget _buildMarker(dynamic event) {
    return Container(
      width: 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 0.3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: event.color,
      ),
    );
  }

  Widget _buildEventList() {
    if (_isLoadingEvents) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFoldingCube(
              color: Colors.amber,
              size: 30,
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              "Lade Events...",
              style: TextStyle(color: ThemeController.activeTheme().textColor),
            )
          ],
        ),
      );
    }

    if (_selectedEvents.length <= 0 && _selectedHolidays.length <= 0) {
      return Center(
        child: Text("Keine Events. Zum Erstellen + tippen"),
      );
    }

    return ScrollConfiguration(
      behavior: CustomScrollBehavior(false, true),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _buildEventTileList()..addAll(_buildHolidayTileList()),
      ),
    );
  }

  List<Widget> _buildEventTileList() {
    return _selectedEvents.map((event) {
      bool _canEditThisEvent = widget.linkedCalendar.canEditEvents;

      if (!_canEditThisEvent) {
        if (widget.linkedCalendar.dynamicEventMap.containsKey(event.eventID)) {
          if (UserController.user.userID == widget.linkedCalendar.dynamicEventMap[event.eventID].userID) {
            _canEditThisEvent = true;
          }
        }
      }

      bool onlyTitle = (event.startTime == "" && event.endTime == "");
      Widget tile;

      if (onlyTitle) {
        tile = ListTile(
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(event.title),
          onTap: () {
            EventPopup.showEventInformation(widget.linkedCalendar.id, event.eventID);
          },
        );
      } else {
        String subTitle = "";

        if (event.startTime == "")
          subTitle = event.endTime;
        else if (event.endTime == "")
          subTitle = event.startTime;
        else
          subTitle = event.startTime + "\n" + event.endTime;

        tile = ListTile(
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(event.title),
          subtitle: Text(subTitle),
          isThreeLine: (event.startTime == "" || event.endTime == "") ? false : true,
          onTap: () {
            EventPopup.showEventInformation(widget.linkedCalendar.id, event.eventID);
          },
        );
      }

      return Slidable(
        enabled: true,
        actionPane: SlidableDrawerActionPane(),
        actionExtentRatio: 0.20,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 3,
          color: ThemeController.activeTheme().cardColor,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: event.color,
                  width: 3,
                ),
              ),
            ),
            child: tile,
          ),
        ),
        actions: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: IconSlideAction(
              caption: 'Teilen',
              color: Colors.indigo,
              icon: Icons.share,
              onTap: () => null,
            ),
          ),
        ],
        secondaryActions: _canEditThisEvent
            ? <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: IconSlideAction(
              caption: 'Bearbeiten',
              color: Colors.grey,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              onTap: () => _editEvent(event.eventID),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: IconSlideAction(
              caption: 'Löschen',
              color: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              onTap: () => _deleteEvent(event.eventID),
            ),
          ),
        ] : [],
      );
    }).toList();
  }

  List<Widget> _buildHolidayTileList() {
    return _selectedHolidays.map((holiday) {
      Widget tile = ListTile(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(holiday),
        subtitle: Text("Feiertag"),
      );

      return Slidable(
          enabled: false,
          actionPane: SlidableDrawerActionPane(),
          actionExtentRatio: 0.20,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            elevation: 3,
            color: ThemeController.activeTheme().cardColor,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color(0xFFF44336),
                    width: 3,
                  ),
                ),
              ),
              child: tile,
            ),
          )
      );
    }).toList();
  }
}

enum CalendarMenuStatus { SETTINGS, NOTES_AND_VOTES, QR_INVITATION }

class CalendarMenuChoice {
  const CalendarMenuChoice({this.menuStatus, this.title, this.icon});

  final CalendarMenuStatus menuStatus;
  final String title;
  final IconData icon;
}
