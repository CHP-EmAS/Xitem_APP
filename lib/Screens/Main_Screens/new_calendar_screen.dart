import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Screens/Sub_Screens/create_calendar_screen.dart';
import 'package:de/Screens/Sub_Screens/join_calendar_screen.dart';
import 'package:de/Screens/Sub_Screens/join_calender_via_qr_code_screen.dart';
import 'package:de/Settings/locator.dart';
import 'package:flutter/material.dart';

class NewCalendarScreen extends StatefulWidget {
  const NewCalendarScreen();

  @override
  State<StatefulWidget> createState() {
    return _NewCalendarScreenState();
  }
}

class _NewCalendarScreenState extends State<NewCalendarScreen> with SingleTickerProviderStateMixin {
  final NavigationService _navigationService = locator<NavigationService>();

  final List<Tab> myTabs = <Tab>[
    Tab(child: Text("Erstellen", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16))),
    Tab(child: Text("Beitreten", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16))),
    Tab(child: Text("QR Code", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16))),
  ];

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: myTabs.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            color: ThemeController.activeTheme().iconColor,
            onPressed: () {
              _navigationService.pushNamedAndRemoveUntil('/home/calendar', (route) => false);
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: myTabs,
          ),
          title: Text(
            "Neuen Kalender hinzufügen",
            style: TextStyle(color: ThemeController.activeTheme().textColor),
          ),
          centerTitle: true,
          backgroundColor: ThemeController.activeTheme().foregroundColor,
          elevation: 0,
        ),
        backgroundColor: ThemeController.activeTheme().backgroundColor,
        body: TabBarView(controller: _tabController, children: [CreateCalendarScreen(), JoinCalendarScreen(), QRCodeCalenderScreen()]));
  }
}
