import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Widgets/Dialogs/event_popups.dart';
import 'package:de/pages/sub/CalendarListSubPage.dart';
import 'package:de/pages/sub/EventListSubPage.dart';
import 'package:de/pages/sub/HolidayListSubPage.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage(this._startIndex);

  final int _startIndex;

  @override
  _HomePageState createState() => _HomePageState(_startIndex);
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex;

  EventListSubPage _currentEventListWidget;
  CalendarListSubPage _calendarList;
  HolidayListSubPage _holidayList;

  static final List<AppMenuChoice> _menuChoices = <AppMenuChoice>[
    const AppMenuChoice(menuStatus: AppMenuStatus.PROFILE, title: 'Account', icon: Icons.account_circle),
    const AppMenuChoice(menuStatus: AppMenuStatus.SETTINGS, title: 'Einstellungen', icon: Icons.settings),
    const AppMenuChoice(menuStatus: AppMenuStatus.LOGOUT, title: 'Abmelden', icon: Icons.exit_to_app),
  ];

  static final List<NavigationItem> _widgetOptions = <NavigationItem>[
    NavigationItem(
      menuStatus: AppBottomBarStatus.CALENDARS,
      appbarTitle: "Deine Kalender",
      bottomBarIcon: Icons.event,
      bottomBarText: "Kalender",
      actionHintText: "Kalender hinzufügen",
      actionIcon: Icons.fiber_new_outlined,
    ),
    NavigationItem(
      menuStatus: AppBottomBarStatus.EVENTS,
      appbarTitle: "Anstehende Events",
      bottomBarIcon: Icons.home,
      bottomBarText: "Home",
      actionHintText: "Event hinzufügen",
      actionIcon: Icons.add,
    ),
    NavigationItem(
      menuStatus: AppBottomBarStatus.HOLIDAYS,
      appbarTitle: "Feiertage",
      bottomBarIcon: Icons.star,
      bottomBarText: "Feiertage",
      actionHintText: "Geburtstag hinzufügen",
      actionIcon: Icons.cake,
    ),
  ];

  _HomePageState(_startIndex) {
    this._selectedIndex = _startIndex;
  }

  @override
  void initState() {
    super.initState();

    _currentEventListWidget = new EventListSubPage();
    _calendarList = new CalendarListSubPage();
    _holidayList = new HolidayListSubPage();
  }

  Widget buildBody() {
    switch (_widgetOptions.elementAt(_selectedIndex).menuStatus) {
      case AppBottomBarStatus.EVENTS:
        return _currentEventListWidget;
        break;
      case AppBottomBarStatus.CALENDARS:
        return _calendarList;
        break;
      case AppBottomBarStatus.HOLIDAYS:
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
              icon: Icon(_widgetOptions[0].bottomBarIcon),
              label: _widgetOptions[0].bottomBarText,
            ),
            BottomNavigationBarItem(
              icon: Icon(_widgetOptions[1].bottomBarIcon),
              label: _widgetOptions[1].bottomBarText,
            ),
            BottomNavigationBarItem(
              icon: Icon(_widgetOptions[2].bottomBarIcon),
              label: _widgetOptions[2].bottomBarText,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: ThemeController.activeTheme().globalAccentColor,
          unselectedItemColor: ThemeController.activeTheme().iconColor,
          backgroundColor: ThemeController.activeTheme().foregroundColor,
          onTap: _onItemTapped,
        ),
      ),
      floatingActionButton: _widgetOptions.elementAt(_selectedIndex).menuStatus == AppBottomBarStatus.HOLIDAYS
          ? Center()
          : FloatingActionButton(
              onPressed: _floatingActionButtonPressed,
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

  void _floatingActionButtonPressed() async {
    if (_widgetOptions.elementAt(_selectedIndex).menuStatus == AppBottomBarStatus.CALENDARS) {
      await Navigator.pushNamed(context, '/createCalendar');
    } else if (_widgetOptions.elementAt(_selectedIndex).menuStatus == AppBottomBarStatus.EVENTS) {
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
        await Navigator.pushNamed(context, '/createCalendar');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectMenuChoice(AppMenuChoice choice) async {
    if (choice.menuStatus == AppMenuStatus.LOGOUT) {
      await UserController.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (Route<dynamic> route) => false);
    } else if (choice.menuStatus == AppMenuStatus.PROFILE) {
      Navigator.pushNamed(context, "/profile").then((_) => setState(() {}));
    } else if (choice.menuStatus == AppMenuStatus.SETTINGS) {
      Navigator.pushNamed(context, "/settings").then((_) => setState(() {
        _currentEventListWidget.refreshState();
        _holidayList.refreshState();
      }));
    }
  }
}

class NavigationItem {
  NavigationItem({this.menuStatus, this.appbarTitle, this.bottomBarIcon, this.bottomBarText, this.actionHintText, this.actionIcon});

  final AppBottomBarStatus menuStatus;
  final String appbarTitle;

  final IconData bottomBarIcon;
  final String bottomBarText;

  final String actionHintText;
  final IconData actionIcon;
}

class AppMenuChoice {
  const AppMenuChoice({this.menuStatus, this.title, this.icon});

  final AppMenuStatus menuStatus;
  final String title;
  final IconData icon;
}

enum AppMenuStatus { LOGOUT, SETTINGS, PROFILE }
enum AppBottomBarStatus { EVENTS, CALENDARS, HOLIDAYS }

