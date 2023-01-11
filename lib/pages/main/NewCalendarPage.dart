import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/pages/sub/CreateCalendarSubPage.dart';
import 'package:xitem/pages/sub/JoinCalendarQrSubPage.dart';
import 'package:xitem/pages/sub/JoinCalendarSubPage.dart';
import 'package:flutter/material.dart';

class NewCalendarPage extends StatefulWidget {
  const NewCalendarPage({super.key, required this.calendarController});

  final CalendarController calendarController;

  @override
  State<StatefulWidget> createState() => _NewCalendarPageState();
}

class _NewCalendarPageState extends State<NewCalendarPage> with SingleTickerProviderStateMixin {
  final List<Tab> _myTabs = <Tab>[
    Tab(child: Text("Erstellen", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16))),
    Tab(child: Text("Beitreten", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16))),
    Tab(child: Text("QR Code", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16))),
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _myTabs.length);
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
              StateController.navigatorKey.currentState?.pop();
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: _myTabs,
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
        body: TabBarView(controller: _tabController, children: [CreateCalendarSubPage(widget.calendarController), JoinCalendarSubPage(widget.calendarController), JoinCalendarQrSubPage(widget.calendarController)]));
  }
}
