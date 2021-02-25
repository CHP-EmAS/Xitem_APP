import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Settings/custom_scroll_behavior.dart';
import 'package:de/Settings/locator.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/Dialogs/event_popups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:table_calendar/table_calendar.dart';

// Example holidays
final Map<DateTime, List> _holidays = {
  DateTime(2019, 1, 1): ['New Year\'s Day'],
  DateTime(2019, 1, 6): ['Epiphany'],
  DateTime(2019, 2, 14): ['Valentine\'s Day'],
  DateTime(2019, 4, 21): ['Easter Sunday'],
  DateTime(2019, 4, 22): ['Easter Monday'],
};

class SingleCalendarScreen extends StatefulWidget {
  SingleCalendarScreen(this._calendarID);

  final String _calendarID;

  @override
  _SingleCalendarScreenState createState() => _SingleCalendarScreenState(_calendarID);
}

class _SingleCalendarScreenState extends State<SingleCalendarScreen> with TickerProviderStateMixin {
  final NavigationService _navigationService = locator<NavigationService>();
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();

  _SingleCalendarScreenState(this._calendarID)
      : _calendar = UserController.calendarList[_calendarID],
        _calendarMenuChoices = UserController.calendarList[_calendarID].isOwner ? _calendarMenuChoicesAdmin : _calendarMenuChoicesMember;

  static const List<CalendarMenuChoice> _calendarMenuChoicesMember = const <CalendarMenuChoice>[
    const CalendarMenuChoice(menuStatus: calendarMenuStatus.NOTES_AND_VOTES, title: 'Notizen & Abstimmungen', icon: Icons.sticky_note_2_outlined),
    const CalendarMenuChoice(menuStatus: calendarMenuStatus.SETTINGS, title: 'Kalender Einstellungen', icon: Icons.settings),
  ];

  static const List<CalendarMenuChoice> _calendarMenuChoicesAdmin = const <CalendarMenuChoice>[
    const CalendarMenuChoice(menuStatus: calendarMenuStatus.NOTES_AND_VOTES, title: 'Notizen & Abstimmungen', icon: Icons.sticky_note_2_outlined),
    const CalendarMenuChoice(menuStatus: calendarMenuStatus.QR_INVITATION, title: 'QR Einladung erstellen', icon: Icons.qr_code),
    const CalendarMenuChoice(menuStatus: calendarMenuStatus.SETTINGS, title: 'Kalender Einstellungen', icon: Icons.settings),
  ];

  final Calendar _calendar;
  final String _calendarID;

  final List<CalendarMenuChoice> _calendarMenuChoices;

  Map<DateTime, List<dynamic>> _events = new Map<DateTime, List<dynamic>>();
  List<dynamic> _selectedEvents;
  AnimationController _animationController;
  CalendarController _calendarController;

  bool _isLoadingEvents = false;
  bool _showAddEventButton = true;

  DateTime currentVisibleMonth;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();

    final _selectedDay = DateTime(now.year, now.month, now.day);
    currentVisibleMonth = DateTime(now.year, now.month);

    setState(() {
      _isLoadingEvents = true;
    });

    _selectedEvents = [];

    _calendar.getUiEvents(_selectedDay.year, _selectedDay.month).then((list) {
      if (currentVisibleMonth.year == now.year && currentVisibleMonth.month == now.month) {
        setState(() {
          _events = list;
          _selectedEvents = _events[_selectedDay] ?? [];
          _isLoadingEvents = false;
        });
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
    if (choice.menuStatus == calendarMenuStatus.SETTINGS) {
      _navigationService.pushNamed('/calendarSettings', arguments: _calendarID);
    } else if (choice.menuStatus == calendarMenuStatus.NOTES_AND_VOTES) {
      _navigationService.pushNamed('/calendarNotesAndVotes', arguments: _calendarID);
    } else if (choice.menuStatus == calendarMenuStatus.QR_INVITATION) {
      await createQRCode();
    }
  }

  Future<bool> createQRCode() async {
    InvitationRequest invitationData = await DialogPopup.asyncCreateQRCodePopup(widget._calendarID);
    if (invitationData == null) return false;

    String invitationToken = await _calendar.getInvitationToken(invitationData.canCreateEvents, invitationData.canEditEvents, invitationData.duration);
    if (invitationToken == null) {
      await DialogPopup.asyncOkDialog("QR-Code konnte nicht erstellt werden!", Api.errorMessage);
      return false;
    }

    invitationToken = '{"n":"${_calendar.name}","k":"' + invitationToken + '"}';
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
      _selectedEvents = _calendar.loadedUIMonths[initDate.year.toString() + initDate.month.toString()].uiEvents[DateTime(initDate.year, initDate.month, initDate.day)];
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
      return;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!success) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      DialogPopup.asyncOkDialog("Event konnten nicht erstellt werden!", Api.errorMessage);
    } else {
      if (selectedCalendar.id == _calendar.id) {
        await _rebuildOnSpecificDate(newEvent.startDate);
      }

      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
    }
  }

  void _editEvent(BigInt eventID) async {
    EventData editedEvent = await EventPopup.showEventSettingDialog(_calendar.id, eventID: eventID);

    if (editedEvent != null) {
      DialogPopup.asyncLoadingDialog(_keyLoader, "Speichere Änderungen...");

      bool success = await _calendar.editEvent(eventID, editedEvent.startDate, editedEvent.endDate, editedEvent.title, editedEvent.description, editedEvent.daylong, editedEvent.color).catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return;
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

      bool success = await _calendar.removeEvent(eventID).catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return;
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

  void _onDaySelected(DateTime day, List<dynamic> events) async {
    setState(() {
      _selectedEvents = events;
    });
  }

  Future<void> _onVisibleDaysChanged(DateTime first, DateTime last, CalendarFormat format) async {
    first = first.add(Duration(days: 7));

    currentVisibleMonth = DateTime(first.year, first.month);

    setState(() {
      _isLoadingEvents = true;
    });

    await _calendar.getUiEvents(first.year, first.month).then((list) {
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

    EventPopup.showEventSettingDialog(_calendar.id, initTime: DateTime(day.year, day.month, day.day, 12), calendarChangeable: true).then((EventData newEvent) {
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
            _navigationService.pop();
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              _calendar.icon,
              color: _calendar.color,
              size: 32,
            ),
            SizedBox(
              width: 15,
            ),
            Text(
              _calendar.name,
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
      floatingActionButton: (_calendar.canCreateEvents && _showAddEventButton)
          ? FloatingActionButton(
              onPressed: () async {
                EventData newEvent = await EventPopup.showEventSettingDialog(_calendar.id, initTime: _calendarController.selectedDay, calendarChangeable: true);
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
        _onDaySelected(date, events);
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

    if (_selectedEvents.length <= 0) {
      return Center(
        child: Text("Keine Events. Zum Erstellen + tippen"),
      );
    }

    return ScrollConfiguration(
      behavior: CustomScrollBehavior(false, true),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _selectedEvents.map((event) {
          bool _canEditThisEvent = _calendar.canEditEvents;

          if (!_canEditThisEvent) {
            if (_calendar.dynamicEventMap.containsKey(event.eventID)) {
              if (UserController.user.userID == _calendar.dynamicEventMap[event.eventID].userID) {
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
                EventPopup.showEventInformation(_calendar.id, event.eventID);
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
                EventPopup.showEventInformation(_calendar.id, event.eventID);
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
                  ]
                : [],
          );
        }).toList(),
      ),
    );
  }
}

enum calendarMenuStatus { SETTINGS, NOTES_AND_VOTES, QR_INVITATION }

class CalendarMenuChoice {
  const CalendarMenuChoice({this.menuStatus, this.title, this.icon});

  final calendarMenuStatus menuStatus;
  final String title;
  final IconData icon;
}
