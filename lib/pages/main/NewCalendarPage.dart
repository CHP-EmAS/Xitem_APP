import 'package:de/Controllers/ThemeController.dart';
import 'package:de/pages/sub/CreateCalendarSubPage.dart';
import 'package:de/pages/sub/JoinCalendarQrSubPage.dart';
import 'package:de/pages/sub/JoinCalendarSubPage.dart';
import 'package:flutter/material.dart';

class NewCalendarPage extends StatefulWidget {
  const NewCalendarPage();

  @override
  State<StatefulWidget> createState() {
    return _NewCalendarPageState();
  }
}

class _NewCalendarPageState extends State<NewCalendarPage> with SingleTickerProviderStateMixin {
  final List<Tab> _myTabs = <Tab>[
    Tab(child: Text("Erstellen", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16))),
    Tab(child: Text("Beitreten", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16))),
    Tab(child: Text("QR Code", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16))),
  ];

  TabController _tabController;

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
              Navigator.pushNamedAndRemoveUntil(context, '/home/calendar', (route) => false);
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
        body: TabBarView(controller: _tabController, children: [CreateCalendarSubPage(), JoinCalendarSubPage(), JoinCalendarQrSubPage()]));
  }
}
