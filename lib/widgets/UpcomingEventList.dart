import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/CalendarMemberController.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/EventListBuilder.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/utils/CustomScrollBehavior.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:xitem/widgets/SlidableEventCard.dart';

class UpcomingEventList extends StatelessWidget {
  final CalendarController _calendarController;

  final List<EventListEntry> _eventEntryList;
  final AuthenticatedUser _appUser;

  final void Function(String) _onCalendarIconTapped;
  final void Function(UiEvent) _onEventTapped;
  final void Function(UiEvent) _onEventEditTapped;
  final void Function(UiEvent) _onEventDeleteTapped;

  const UpcomingEventList(this._calendarController, this._eventEntryList, this._appUser, this._onCalendarIconTapped, this._onEventTapped, this._onEventEditTapped, this._onEventDeleteTapped, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const CustomScrollBehavior(false, true),
      child: _eventEntryList.isNotEmpty
          ? ListView.builder(
              itemCount: _eventEntryList.length,
              itemBuilder: _buildItemsForListView,
            )
          : Center(
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  _calendarController.getCalendarMap().isEmpty
                      ? "Herzlich Willkommen bei Xitem! ♥\n\n Drücke '+' unten Links um deinen ersten Kalender zu erstellen oder einem bestehenden Kalender beizutreten."
                      : "Keine anstehenden Termine in den nächsten Monaten.\nDrücke '+' unten Links um ein neuen Termin zu erstellen.",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }

  Widget _buildItemsForListView(BuildContext context, int index) {
    EventListEntry currentEntry = _eventEntryList[index];

    if (currentEntry.entryType == EventListEntryType.headline) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(5, 13, 5, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentEntry.headlineText, style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 20, fontWeight: FontWeight.w500)),
            Divider(
              color: ThemeController.activeTheme().headlineColor,
              height: 5,
              thickness: 2,
            )
          ],
        ),
      );
    } else if (currentEntry.entryType == EventListEntryType.event) {
      UiEvent? uiEvent = currentEntry.uiEvent;
      if(uiEvent != null) {
        return _buildEvent(uiEvent);
      }
    }

    return const Center();
  }

  Widget _buildEvent(UiEvent uiEvent) {
    bool canEditThisEvent = uiEvent.calendar.calendarMemberController
        .getCalendarMember(_appUser.id)
        ?.canEditEvents ?? false;

    if (!canEditThisEvent) {
      if (_appUser.id == uiEvent.event.userID) {
        canEditThisEvent = true;
      }
    }

    Widget tile;
    String subTitle = "";

    if (uiEvent.firstLine == "") {
      subTitle = uiEvent.secondLine;
    } else if (uiEvent.secondLine == "") {
      subTitle = uiEvent.firstLine;
    } else {
      subTitle = "${uiEvent.firstLine}\n${uiEvent.secondLine}";
    }

    tile = ListTile(
      focusColor: Colors.red,
      visualDensity: VisualDensity.compact,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      trailing: IconButton(
        color: Colors.transparent,
        splashColor: Colors.transparent,
        icon: Icon(
          uiEvent.calendar.icon,
          size: 35,
          color: ThemeController.getEventColor(uiEvent.calendar.color),
        ),
        onPressed: () => _onCalendarIconTapped(uiEvent.calendar.id),
      ),
      title: Text(uiEvent.headline),
      subtitle: Text(subTitle),
      isThreeLine: (uiEvent.firstLine == "" || uiEvent.secondLine == "") ? false : true,
      onTap: () => _onEventTapped(uiEvent),
    );

    return SlidableEventCard(
        color: ThemeController.getEventColor(uiEvent.event.color),
        editable: canEditThisEvent,
        content: tile,
        onEventShareTapped: () => {},
        onEventEditTapped: () => _onEventEditTapped(uiEvent),
        onEventDeleteTapped: () => _onEventDeleteTapped(uiEvent)
    );
  }
}
