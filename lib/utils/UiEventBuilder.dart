import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:intl/intl.dart';

class UiEventBuilder {
  static final timeFormat = DateFormat.Hm('de_DE');

  static Map<DateTime, List<UiEvent>> convertEvent(Event event, Calendar calendar, DateTime invalidAfter, DateTime invalidBefore) {
    Map<DateTime, List<UiEvent>> uiEvents = <DateTime, List<UiEvent>>{};

    DateTime startDay = DateTime(event.start.year, event.start.month, event.start.day);
    DateTime endDay = DateTime(event.end.year, event.end.month, event.end.day);

    if (startDay.compareTo(endDay) == 0) { //Gleicher Tag
      if (startDay.isBefore(invalidBefore) || startDay.isAfter(invalidAfter)) {
        return uiEvents;
      }

      UiEvent newUiEvent = UiEvent(
          event,
          calendar,
          event.title,
          event.dayLong ? "Ganztägig" : ("Start: ${timeFormat.format(event.start)}"),
          event.dayLong ? "" : ("Ende: ${timeFormat.format(event.end)}"),
      );

      if (!uiEvents.containsKey(startDay)) {
        uiEvents[startDay] = <UiEvent>[];
      }

      uiEvents[startDay]!.add(newUiEvent);
    } else { //Mehrere Tage
      Duration difference = DateTime(endDay.year, endDay.month, endDay.day, 12).difference(startDay);

      int loopDays = difference.inDays + 1;

      for (int day = 0; day < loopDays; day++) {
        DateTime iteratedStartDay = DateTime(startDay.year, startDay.month, startDay.day + day, 0, 0, 0);

        if (iteratedStartDay.isBefore(invalidBefore) || iteratedStartDay.isAfter(invalidAfter)) {
          continue;
        }

        String startString = "";
        String endString = "";

        if (day == 0) {
          startString = event.dayLong ? "Ganztägig" : ("Start: ${timeFormat.format(event.start)}");
        } else if ((day + 1) == loopDays) {
          startString = event.dayLong ? "" : ("Ende: ${timeFormat.format(event.end)}");
        }

        UiEvent newCalendarEvent = UiEvent(
            event,
            calendar,
            "${event.title} (Tag ${day + 1}/$loopDays)",
            startString,
            endString,
        );

        if (!uiEvents.containsKey(iteratedStartDay)) {
          uiEvents[iteratedStartDay] = <UiEvent>[];
        }

        uiEvents[iteratedStartDay]!.add(newCalendarEvent);
      }
    }

    return uiEvents;
  }
}