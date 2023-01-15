import 'package:flutter/material.dart';
import 'package:xitem/controllers/BirthdayController.dart';
import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/EventController.dart';
import 'package:xitem/controllers/HolidayController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/controllers/UserController.dart';
import 'package:xitem/main.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/models/SpecialEvent.dart';
import 'package:xitem/pages/main/EventPage.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/AvatarImageProvider.dart';
import 'package:xitem/utils/EventListBuilder.dart';
import 'package:xitem/utils/StateCodeConverter.dart';
import 'package:xitem/widgets/CalendarList.dart';
import 'package:xitem/widgets/SpecialEventList.dart';
import 'package:xitem/widgets/UpcomingEventList.dart';
import 'package:xitem/widgets/dialogs/BirthdayDialog.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';
import 'package:xitem/widgets/dialogs/UserDialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.initialSubPage, required this.userController, required this.calendarController, required this.holidayController, required this.birthdayController});

  final HomeSubPage initialSubPage;
  final UserController userController;
  final CalendarController calendarController;
  final HolidayController holidayController;
  final BirthdayController birthdayController;

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final EventListBuilder _eventListBuilder;

  late HomeSubPage _selectedSubPage;

  static final List<_MenuChoice> _homeMenuChoices = <_MenuChoice>[
    const _MenuChoice(menuStatus: _AppMenuStatus.profile, title: 'Account', icon: Icons.account_circle),
    const _MenuChoice(menuStatus: _AppMenuStatus.settings, title: 'Einstellungen', icon: Icons.settings),
    const _MenuChoice(menuStatus: _AppMenuStatus.logout, title: 'Abmelden', icon: Icons.exit_to_app),
  ];

  static final List<_NavigationItem> _navigationOptions = <_NavigationItem>[
    _NavigationItem(
      menuStatus: HomeSubPage.calendars,
      appbarTitle: "Deine Kalender",
      bottomBarIcon: Icons.event,
      bottomBarText: "Kalender",
      actionHintText: "Kalender hinzufügen",
      actionIcon: Icons.fiber_new_outlined,
    ),
    _NavigationItem(
      menuStatus: HomeSubPage.events,
      appbarTitle: "Anstehende Termine",
      bottomBarIcon: Icons.home,
      bottomBarText: "Home",
      actionHintText: "Termin hinzufügen",
      actionIcon: Icons.add,
    ),
    _NavigationItem(
      menuStatus: HomeSubPage.holidays,
      appbarTitle: "Feiertage",
      bottomBarIcon: Icons.star,
      bottomBarText: "Feiertage",
      actionHintText: "Geburtstag hinzufügen",
      actionIcon: Icons.cake,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _eventListBuilder = EventListBuilder(widget.calendarController);
    _eventListBuilder.generateEventList();

    _selectedSubPage = widget.initialSubPage;
  }

  Widget buildBody() {
    switch (_selectedSubPage) {
      case HomeSubPage.events:
        return UpcomingEventList(
          calendarController: widget.calendarController,
          userController: widget.userController,
          eventEntryList: _eventListBuilder.getGeneratedEventList(),
          appUser: widget.userController.getAuthenticatedUser(),
          onCalendarIconTapped: _onCalendarIconTapped,
          onEventTapped: (p0) {},
          onEventSharedTapped: (p0) {},
          onEventEditTapped: _onEditEvent,
          onEventDeleteTapped: _onDeleteEvent,
        );
      case HomeSubPage.calendars:
        List<UiCalendarCard> calendarCards = [];

        widget.calendarController.getCalendarMap().values.forEach((calendar) {
          calendarCards.add(UiCalendarCard(calendar, _eventListBuilder.generateCalendarEventHeadline(calendar)));
        });

        return CalendarList(calendarList: calendarCards, onCalendarCardTap: _onCalendarIconTapped);
      case HomeSubPage.holidays:
        return SpecialEventList(
          birthdayList: widget.birthdayController.birthdays(),
          holidayList: widget.holidayController.upcomingHolidays(),
          currentLoadedStateName: StateCodeConverter.getStateName(Xitem.settingController.getHolidayStateCode()),
          onDeleteLocalBirthday: onDeleteLocalBirthday,
        );
      default:
        return const Center(
          child: Text("Error: Inhalt fehlerhaft!"),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: ThemeController.activeTheme().iconColor, size: 25.0),
        leading: Container(
          padding: const EdgeInsets.all(7),
          child: CircleAvatar(
            backgroundImage: AvatarImageProvider.get(widget.userController.getAuthenticatedUser().avatar),
            child: GestureDetector(
              onTap: () async {
                UserDialog.profilePictureDialog(widget.userController.getAuthenticatedUser().avatar);
              },
            ),
          ),
        ),
        title: Text(
          _navigationOptions.elementAt(_selectedSubPage.index).appbarTitle,
          style: TextStyle(
            color: ThemeController.activeTheme().textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        actions: <Widget>[
          PopupMenuButton<_MenuChoice>(
            onSelected: _onHomeMenuChoiceTapped,
            color: ThemeController.activeTheme().menuPopupBackgroundColor,
            itemBuilder: (BuildContext context) {
              return _homeMenuChoices.map((_MenuChoice choice) {
                return PopupMenuItem<_MenuChoice>(
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
      body: Center(child: buildBody()),
      bottomNavigationBar: BottomAppBar(
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(_navigationOptions[0].bottomBarIcon),
              label: _navigationOptions[0].bottomBarText,
            ),
            BottomNavigationBarItem(
              icon: Icon(_navigationOptions[1].bottomBarIcon),
              label: _navigationOptions[1].bottomBarText,
            ),
            BottomNavigationBarItem(
              icon: Icon(_navigationOptions[2].bottomBarIcon),
              label: _navigationOptions[2].bottomBarText,
            ),
          ],
          currentIndex: _selectedSubPage.index,
          selectedItemColor: ThemeController.activeTheme().globalAccentColor,
          unselectedItemColor: ThemeController.activeTheme().iconColor,
          backgroundColor: ThemeController.activeTheme().foregroundColor,
          onTap: (index) {
            _onNavigatorItemTapped(HomeSubPage.values[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onActionButtonPressed,
        backgroundColor: ThemeController.activeTheme().actionButtonColor,
        tooltip: _navigationOptions.elementAt(_selectedSubPage.index).actionHintText,
        child: Icon(
          _navigationOptions.elementAt(_selectedSubPage.index).actionIcon,
          color: ThemeController.activeTheme().textColor,
          size: 30,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _onActionButtonPressed() async {
    if (_navigationOptions.elementAt(_selectedSubPage.index).menuStatus == HomeSubPage.calendars) {
      StateController.navigatorKey.currentState?.pushNamed('/createCalendar').then((value) => setState(() => {}));
    } else if (_navigationOptions.elementAt(_selectedSubPage.index).menuStatus == HomeSubPage.events) {
      Map<String, Calendar> calendars = widget.calendarController.getCalendarMap();

      if (calendars.isNotEmpty) {
        StateController.navigatorKey.currentState?.pushNamed(
          "/event",
          arguments: EventPageArguments(initialCalendar: calendars.values.first, calendarList: calendars.values.toList(), calendarChangeable: true, initialStartDate: DateTime.now())
        ).then((value) => {
          setState(() {
            _eventListBuilder.generateEventList();
          })
        });
      } else {
        StateController.navigatorKey.currentState?.pushNamed('/createCalendar').then((value) => setState(() => {}));
      }
    } else if (_navigationOptions.elementAt(_selectedSubPage.index).menuStatus == HomeSubPage.holidays) {
      onCreateLocalBirthday();
    }
  }

  void _onNavigatorItemTapped(HomeSubPage subPage) {
    setState(() {
      _selectedSubPage = subPage;
    });
  }

  void _onHomeMenuChoiceTapped(_MenuChoice choice) {
    if (choice.menuStatus == _AppMenuStatus.logout) {
      StateController.logOut();
      StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/startup', (Route<dynamic> route) => false);
    } else if (choice.menuStatus == _AppMenuStatus.profile) {
      StateController.navigatorKey.currentState?.pushNamed("/profile").then((_) => setState(() {}));
    } else if (choice.menuStatus == _AppMenuStatus.settings) {
      StateController.navigatorKey.currentState?.pushNamed("/settings").then((_) => setState(() {}));
    }
  }

  void _onCalendarIconTapped(String selectedCalendar) {
    StateController.navigatorKey.currentState?.pushNamed("/calendar", arguments: selectedCalendar).then((value) => setState(() {
          _eventListBuilder.generateEventList();
        }));
  }

  void _onEditEvent(UiEvent eventToEdit) async {
    Calendar? calendar = widget.calendarController.getCalendar(eventToEdit.calendar.id);
    EventController? eventController = widget.calendarController.getCalendar(eventToEdit.calendar.id)?.eventController;
    if (calendar == null || eventController == null) {
      return;
    }

    Event? event = eventController.getEvent(eventToEdit.event.eventID);
    if (event == null) {
      return;
    }

    List<Calendar> calendarList = widget.calendarController.getCalendarMap().values.toList();
    StateController.navigatorKey.currentState?.pushNamed("/event", arguments: EventPageArguments(initialCalendar: calendar, calendarList: calendarList, eventToEdit: event))
        .then((value) => {
          setState(() {
            _eventListBuilder.generateEventList();
          })
        });
  }

  void _onDeleteEvent(UiEvent eventToDelete) async {
    EventController? eventController = widget.calendarController.getCalendar(eventToDelete.calendar.id)?.eventController;
    if (eventController == null) {
      return;
    }

    ConfirmAction? confirm = await StandardDialog.confirmDialog("Event löschen?", "Willst du das Event wirklich löschen? Das Event wird endgültig gelöscht und kann nicht wiederhergestellt werden!");

    if (confirm != ConfirmAction.ok) {
      return;
    }

    StandardDialog.loadingDialog("Lösche Event...");

    ResponseCode deleteEvent = await eventController.removeEvent(eventToDelete.event.eventID).catchError((e) {
      StateController.navigatorKey.currentState?.pop();
      return ResponseCode.unknown;
    });

    if (deleteEvent != ResponseCode.success) {
      String errorMessage;

      switch (deleteEvent) {
        case ResponseCode.accessForbidden:
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu löschen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Löschen des Events ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      }

      StateController.navigatorKey.currentState?.pop();
      StandardDialog.okDialog("Event konnte nicht gelöscht werden!", errorMessage);
      return;
    }

    setState(() {
      _eventListBuilder.generateEventList();
    });

    StateController.navigatorKey.currentState?.pop();
  }

  void onCreateLocalBirthday() async {
    LocalBirthday? newBirthday = await BirthdayDialog.showBirthdayDialog();

    StandardDialog.loadingDialog("Füge Geburtstag hinzu...");

    if (newBirthday != null) {
      await widget.birthdayController.addBirthdayToLocalStorage(newBirthday);
      setState(() {});
    }

    StateController.navigatorKey.currentState?.pop();
  }

  void onDeleteLocalBirthday(Birthday birthday) async {
    ConfirmAction? deleteBirthday = await StandardDialog.confirmDialog("Geburtstag entfernen", "Willst du den Geburtstag von ${birthday.name} aus der Liste entfernen?");
    String? uuid = birthday.localID;

    if (deleteBirthday == ConfirmAction.ok && uuid != null) {
      await widget.birthdayController.removeBirthdayFromLocalStorage(uuid);
      setState(() {});
    }
  }
}

class _NavigationItem {
  _NavigationItem({required this.menuStatus, required this.appbarTitle, required this.bottomBarIcon, required this.bottomBarText, required this.actionHintText, required this.actionIcon});

  final HomeSubPage menuStatus;
  final String appbarTitle;

  final IconData bottomBarIcon;
  final String bottomBarText;

  final String actionHintText;
  final IconData actionIcon;
}

class _MenuChoice {
  const _MenuChoice({required this.menuStatus, required this.title, required this.icon});

  final _AppMenuStatus menuStatus;
  final String title;
  final IconData icon;
}

enum _AppMenuStatus { logout, settings, profile }

enum HomeSubPage { calendars, events, holidays }
