import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Screens/Sub_Screens/calendar_list_screen.dart';
import 'package:de/Screens/Sub_Screens/current_event_list_screen.dart';
import 'package:de/Screens/Sub_Screens/holiday_screen.dart';
import 'package:de/Settings/locator.dart';
import 'package:de/Widgets/Dialogs/event_popups.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(this._startIndex);

  final int _startIndex;

  @override
  _HomeScreenState createState() => _HomeScreenState(_startIndex);
}

enum appMenuStatus { LOGOUT, SETTINGS, PROFILE }

enum appBottomBarStatus { EVENTS, KALENDARS, HOLIDAYS }

class _HomeScreenState extends State<HomeScreen> {
  final NavigationService _navigationService = locator<NavigationService>();

  int _selectedIndex;

  CurrentEventListScreen _currentEventListWidget;
  CalendarListScreen _calendarList;
  HolidayListScreen _holidayList;

  _HomeScreenState(_startIndex) {
    this._selectedIndex = _startIndex;
  }

  @override
  void initState() {
    super.initState();

    _currentEventListWidget = CurrentEventListScreen();
    _calendarList = CalendarListScreen();
    _holidayList = HolidayListScreen();
  }

  static const List<AppMenuChoice> _menuChoices = const <AppMenuChoice>[
    const AppMenuChoice(menuStatus: appMenuStatus.PROFILE, title: 'Account', icon: Icons.account_circle),
    const AppMenuChoice(menuStatus: appMenuStatus.SETTINGS, title: 'Einstellungen', icon: Icons.settings),
    const AppMenuChoice(menuStatus: appMenuStatus.LOGOUT, title: 'Abmelden', icon: Icons.exit_to_app),
  ];

  static List<NavigationItem> _widgetOptions = <NavigationItem>[
    NavigationItem(
      menuStatus: appBottomBarStatus.KALENDARS,
      appbarTitle: "Deine Kalender",
      bottombarIcon: Icons.event,
      bottombarText: "Kalender",
      actionHintText: "Kalender hinzufügen",
      actionIcon: Icons.fiber_new_outlined,
    ),
    NavigationItem(
      menuStatus: appBottomBarStatus.EVENTS,
      appbarTitle: "Anstehende Events",
      bottombarIcon: Icons.home,
      bottombarText: "Home",
      actionHintText: "Event hinzufügen",
      actionIcon: Icons.add,
    ),
    NavigationItem(
      menuStatus: appBottomBarStatus.HOLIDAYS,
      appbarTitle: "Feiertage",
      bottombarIcon: Icons.star,
      bottombarText: "Feiertage",
      actionHintText: "",
      actionIcon: Icons.star,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectMenuChoice(AppMenuChoice choice) {
    if (choice.menuStatus == appMenuStatus.LOGOUT) {
      UserController.logout();
    } else if (choice.menuStatus == appMenuStatus.PROFILE) {
      _navigationService.pushNamed("/profile").then((_) => setState(() {}));
    } else if (choice.menuStatus == appMenuStatus.SETTINGS) {
      _navigationService.pushNamed("/settings").then((_) => setState(() {
        _currentEventListWidget.refreshState();
        _holidayList.refreshState();
      }));
    }
  }

  Widget buildBody() {
    switch (_widgetOptions.elementAt(_selectedIndex).menuStatus) {
      case appBottomBarStatus.EVENTS:
        return _currentEventListWidget;
        break;
      case appBottomBarStatus.KALENDARS:
        return _calendarList;
        break;
      case appBottomBarStatus.HOLIDAYS:
        return _holidayList;
        break;
      default:
        return Center(
          child: Text("Error: Inhalt fehlerhaft!"),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: ThemeController.activeTheme().iconColor, size: 10.0),
        leading: Container(
          padding: EdgeInsets.all(7),
          child: CircleAvatar(
            backgroundImage: FileImage(UserController.user.avatar),
          ),
        ),
        title: Text(
          _widgetOptions.elementAt(_selectedIndex).appbarTitle,
          style: TextStyle(
            color: ThemeController.activeTheme().textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        actions: <Widget>[
          // overflow menu
          PopupMenuButton<AppMenuChoice>(
            onSelected: _selectMenuChoice,
            color: ThemeController.activeTheme().menuPopupBackgroundColor,
            itemBuilder: (BuildContext context) {
              return _menuChoices.map((AppMenuChoice choice) {
                return PopupMenuItem<AppMenuChoice>(
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
              icon: Icon(_widgetOptions[0].bottombarIcon),
              label: _widgetOptions[0].bottombarText,
            ),
            BottomNavigationBarItem(
              icon: Icon(_widgetOptions[1].bottombarIcon),
              label: _widgetOptions[1].bottombarText,
            ),
            BottomNavigationBarItem(
              icon: Icon(_widgetOptions[2].bottombarIcon),
              label: _widgetOptions[2].bottombarText,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: ThemeController.activeTheme().globalAccentColor,
          unselectedItemColor: ThemeController.activeTheme().iconColor,
          backgroundColor: ThemeController.activeTheme().foregroundColor,
          onTap: _onItemTapped,
        ),
      ),
      floatingActionButton: _widgetOptions.elementAt(_selectedIndex).menuStatus == appBottomBarStatus.HOLIDAYS
          ? Center()
          : FloatingActionButton(
              onPressed: () async {
                if (_widgetOptions.elementAt(_selectedIndex).menuStatus == appBottomBarStatus.KALENDARS) {
                  await _navigationService.pushNamed('/createCalendar');
                } else if (_widgetOptions.elementAt(_selectedIndex).menuStatus == appBottomBarStatus.EVENTS) {
                  var keyList = UserController.calendarList.keys.toList();

                  if (keyList.isNotEmpty) {
                    EventData newEvent = await EventPopup.showEventSettingDialog(
                      keyList[0],
                      initTime: DateTime.now(),
                      calendarChangeable: true,
                    );

                    if (newEvent != null) {
                      _currentEventListWidget.addEvent(newEvent);
                    }
                  } else {
                    await _navigationService.pushNamed('/createCalendar');
                  }
                }
              },
              backgroundColor: ThemeController.activeTheme().actionButtonColor,
              tooltip: _widgetOptions.elementAt(_selectedIndex).actionHintText,
              child: Icon(
                _widgetOptions.elementAt(_selectedIndex).actionIcon,
                color: ThemeController.activeTheme().textColor,
                size: 30,
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class NavigationItem {
  NavigationItem({this.menuStatus, this.appbarTitle, this.bottombarIcon, this.bottombarText, this.actionHintText, this.actionIcon});

  final appBottomBarStatus menuStatus;
  final String appbarTitle;

  final IconData bottombarIcon;
  final String bottombarText;

  final String actionHintText;
  final IconData actionIcon;
}

class AppMenuChoice {
  const AppMenuChoice({this.menuStatus, this.title, this.icon});

  final appMenuStatus menuStatus;
  final String title;
  final IconData icon;
}
