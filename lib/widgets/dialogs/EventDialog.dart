import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/AvatarImageProvider.dart';
import 'package:xitem/utils/CustomScrollBehavior.dart';
import 'package:xitem/widgets/dialogs/UserDialog.dart';

class EventDialog {
  static Future<void> showEventInformation(Event event, Calendar calendar, User? creator) async {
    BuildContext? buildContext = StateController.navigatorKey.currentContext;
    if (buildContext == null) {
      return;
    }

    return showDialog<void>(
        context: buildContext,
        builder: (BuildContext context) {
          final dateFormat = DateFormat("EEEE, d. MMM", "de_DE");
          final timeFormat = DateFormat.Hm('de_DE');

          final creationDateFormat = DateFormat.yMMMMd("de_DE");

          String firstDateLine = "";
          String secondDateLine = "";

          String name = event.title;
          String description = event.description ?? "";

          DateTime startDate = event.start;
          DateTime endDate = event.end;

          bool daylong = event.dayLong;
          Color eventColor = ThemeController.getEventColor(event.color);
          String colorText = calendar.colorLegend[event.color] ?? "";

          if (startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day) {
            if (daylong) {
              firstDateLine = dateFormat.format(startDate);
            } else {
              firstDateLine = dateFormat.format(startDate);
              secondDateLine = "${timeFormat.format(startDate)} - ${timeFormat.format(endDate)} Uhr";
            }
          } else {
            if (daylong) {
              firstDateLine = "${dateFormat.format(startDate)} -";
              secondDateLine = dateFormat.format(endDate);
            } else {
              firstDateLine = "${dateFormat.format(startDate)}, ${timeFormat.format(startDate)} -";
              secondDateLine = "${dateFormat.format(endDate)}, ${timeFormat.format(endDate)}";
            }
          }

          return ScrollConfiguration(
            behavior: const CustomScrollBehavior(false, false),
            child: AlertDialog(
              elevation: 5,
              titlePadding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              title: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 17,
                  ),
                  Divider(
                    color: eventColor,
                    height: 0,
                    thickness: 3,
                  ),
                ],
              ),
              scrollable: true,
              backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
              content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 30,
                      color: ThemeController.activeTheme().iconColor,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          firstDateLine,
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                        (secondDateLine == "")
                            ? const Center()
                            : Container(
                                margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                child: Text(
                                  secondDateLine,
                                  style: TextStyle(
                                    color: ThemeController.activeTheme().textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
                if (colorText.isNotEmpty)
                  Column(
                    children: [
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.color_lens_outlined,
                            size: 30,
                            color: ThemeController.activeTheme().iconColor,
                          ),
                          Text(
                            colorText,
                            style: TextStyle(
                              color: ThemeController.activeTheme().textColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (description.isNotEmpty)
                  Column(children: [
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      "Beschreibung:",
                      style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),
                const SizedBox(
                  height: 5,
                ),
                (description == "")
                    ? const Center()
                    : Text(
                        description,
                        style: TextStyle(
                          color: ThemeController.activeTheme().textColor,
                          fontSize: 16,
                        ),
                      ),
                const SizedBox(
                  height: 5,
                ),
                Divider(
                  color: ThemeController.activeTheme().dividerColor,
                  height: 15,
                  thickness: 2,
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 30,
                      color: ThemeController.activeTheme().iconColor,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          calendar.icon,
                          color: ThemeController.getEventColor(calendar.color),
                          size: 30,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          calendar.name,
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Icon(
                    Icons.person,
                    size: 30,
                    color: ThemeController.activeTheme().iconColor,
                  ),
                  creator == null
                      ? Text(
                          "Unbekannt",
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        )
                      : GestureDetector(
                          onTap: () async {
                            UserDialog.userInformationPopup(creator);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                creator.name,
                                style: TextStyle(
                                  color: ThemeController.activeTheme().textColor,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.transparent,
                                backgroundImage: AvatarImageProvider.get(creator.avatar),
                              ),
                            ],
                          ),
                        ),
                ]),
                const SizedBox(
                  height: 5,
                ),
                Divider(
                  color: ThemeController.activeTheme().dividerColor,
                  height: 15,
                  thickness: 2,
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Erstellt am: ${creationDateFormat.format(event.creationDate)}",
                      style: TextStyle(
                        color: ThemeController.activeTheme().textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ]),
              contentPadding: const EdgeInsets.fromLTRB(25, 25, 25, 15),
            ),
          );
        });
  }
}
