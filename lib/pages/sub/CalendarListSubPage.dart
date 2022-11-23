import 'package:de/Controllers/EventListController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Settings/custom_scroll_behavior.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CalendarListSubPage extends StatefulWidget {
  const CalendarListSubPage();

  @override
  State<StatefulWidget> createState() {
    return _CalendarListSubPageState();
  }
}

class _CalendarListSubPageState extends State<CalendarListSubPage> {
  List<String> _calendarIDs = [];
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    UserController.calendarList.forEach((calendarID, calendar) {
      _calendarIDs.add(calendarID);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: CustomScrollBehavior(false, true),
      child: SmartRefresher(
        header: WaterDropMaterialHeader(
          color: ThemeController.activeTheme().actionButtonColor,
          backgroundColor: ThemeController.activeTheme().foregroundColor,
        ),
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: _calendarIDs.isNotEmpty
            ? ListView.builder(
                itemCount: _calendarIDs.length,
                itemBuilder: _buildItemsForListView,
              )
            : Center(
                child: Container(
                  margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Text(
                    "Herzlich Willkommen bei Xitem! ♥\n\n Drücke 'NEW' unten Links um deinen ersten Kalender zu erstellen oder einem bestehenden Kalender beizutreten.",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildItemsForListView(BuildContext context, int index) {
    double marginTop = 4.0;
    double marginBot = 4.0;

    if (index == 0) {
      marginTop = 10.0;
    } else if (index == _calendarIDs.length - 1) {
      marginBot = 10.0;
    }

    return Card(
      elevation: 5,
      margin: EdgeInsets.fromLTRB(4, marginTop, 4, marginBot),
      child: ListTile(
        leading: Icon(
          UserController.calendarList[_calendarIDs[index]].icon,
          size: 40,
          color: UserController.calendarList[_calendarIDs[index]].color,
        ),
        title: Text(
          UserController.calendarList[_calendarIDs[index]].name,
          style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 18),
        ),
        subtitle: Text(EventListController.generateCalendarEventHeadline(_calendarIDs[index]), style: TextStyle(color: ThemeController.activeTheme().cardSmallInfoColor)),
        trailing: Icon(Icons.keyboard_arrow_right, size: 35, color: ThemeController.activeTheme().cardSmallInfoColor),
        onTap: () {
          Navigator.pushNamed(context, '/calendar', arguments: _calendarIDs[index]).then((value) {
            setState(() {});
          });
        },
      ),
      color: ThemeController.activeTheme().cardColor,
    );
  }

  void _onRefresh() async {
    bool reloadCompleted = await UserController.loadAllCalendars();

    if (reloadCompleted) {
      if(super.mounted) {
        setState(() {});
      }
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }
  }
}
