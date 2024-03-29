import 'package:xitem/models/Calendar.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/utils/CustomScrollBehavior.dart';
import 'package:flutter/material.dart';

class CalendarList extends StatelessWidget {

  final List<UiCalendarCard> calendarList;
  final void Function(String) onCalendarCardTap;

  const CalendarList({super.key, required this.calendarList, required this.onCalendarCardTap});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const CustomScrollBehavior(false, true),
      child: calendarList.isNotEmpty
          ? ListView.builder(
              itemCount: calendarList.length,
              itemBuilder: _buildItemsForListView,
            )
          : Center(
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: const Text(
                  "Herzlich Willkommen bei Xitem! ♥\n\n Drücke 'NEW' unten Links um deinen ersten Kalender zu erstellen oder einem bestehenden Kalender beizutreten.",
                  textAlign: TextAlign.center,
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
    } else if (index == calendarList.length - 1) {
      marginBot = 10.0;
    }

    UiCalendarCard calendarCard = calendarList[index];

    return Card(
      elevation: 5,
      margin: EdgeInsets.fromLTRB(4, marginTop, 4, marginBot),
      color: ThemeController.activeTheme().cardColor,
      child: ListTile(
        leading: Icon(
          ThemeController.getCalendarIcon(calendarCard.calendar.iconIndex),
          size: 40,
          color: ThemeController.getEventColor(calendarCard.calendar.colorIndex),
        ),
        title: Text(
          calendarCard.calendar.name,
          style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 18),
        ),
        subtitle: Text(calendarCard.upcomingEventsNews, style: TextStyle(color: ThemeController.activeTheme().cardSmallInfoColor)),
        trailing: Icon(Icons.keyboard_arrow_right, size: 35, color: ThemeController.activeTheme().cardSmallInfoColor),
        onTap: () => onCalendarCardTap(calendarCard.calendar.id),
      ),
    );
  }
}

class UiCalendarCard {
  UiCalendarCard(this.calendar, this.upcomingEventsNews);

  final Calendar calendar;
  final String upcomingEventsNews;
}
