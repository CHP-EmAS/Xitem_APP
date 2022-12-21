import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/EventController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/models/User.dart';

class EventListBuilder {
  EventListBuilder(this._calendarController);

  static final dateFormat = DateFormat("EEEE, d. MMMM", "de_DE");
  static final timeFormat = DateFormat.Hm('de_DE');
  static final weekdayFormat = DateFormat("EEEE", "de_DE");

  static const int maxForesight = 3;

  final CalendarController _calendarController;

  //--------- Current Event List ---------//
  final List<EventListEntry> _eventEntryList = <EventListEntry>[];

  //All Events Sorted by specific days
  final List<EventListEntry> _eventsToday = <EventListEntry>[];
  final List<EventListEntry> _eventsTomorrow = <EventListEntry>[];
  final List<EventListEntry> _eventsWeek = <EventListEntry>[];
  final List<EventListEntry> _eventsNextWeek = <EventListEntry>[];
  final List<EventListEntry> _eventsMonth = <EventListEntry>[];
  final Map<int, List<EventListEntry>> _nextMonths = <int, List<EventListEntry>>{};

  DateTime getDate(DateTime d) => DateTime(d.year, d.month, d.day);

  void generateEventList() {
    _eventEntryList.clear();

    _eventsToday.clear();
    _eventsTomorrow.clear();
    _eventsWeek.clear();
    _eventsNextWeek.clear();
    _eventsMonth.clear();
    _nextMonths.clear();

    DateTime now = DateTime.now();

    DateTime today = getDate(now);
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    DateTime thisWeekStart = getDate(today.subtract(Duration(days: today.weekday - 1)));
    DateTime thisWeekEnd = getDate(today.add(Duration(days: DateTime.daysPerWeek - today.weekday)));

    DateTime nextWeek = DateTime(now.year, now.month, now.day + 7);
    DateTime nextWeekStart = getDate(nextWeek.subtract(Duration(days: nextWeek.weekday - 1)));
    DateTime nextWeekEnd = getDate(nextWeek.add(Duration(days: DateTime.daysPerWeek - nextWeek.weekday)));

    DateTime thisMonth = DateTime(now.year, now.month);

    for(Event event in _calendarController.combineAllEvents()) {
      DateTime startDay = getDate(event.start);
      DateTime endDay = getDate(event.end);

      DateTime startMonth = DateTime(startDay.year, startDay.month);
      DateTime endMonth = DateTime(endDay.year, endDay.month + 1, 0);

      Calendar? calendar = _calendarController.getCalendar(event.calendarID);
      if(calendar == null) {
        continue;
      }

      if (!today.isAfter(endDay)) {
        if (startDay.compareTo(endDay) == 0) {
          //Gleicher Tag
          if (startDay == today) {
            //Today
            _eventsToday.add(_convertEventToEntry(event, calendar, true, false, false));
          } else if (startDay == tomorrow) {
            //Tomorrow
            _eventsTomorrow.add(_convertEventToEntry(event, calendar, true, false, false));
          } else if (startDay.isAfter(thisWeekStart) && startDay.isBefore(thisWeekEnd) || startDay == thisWeekStart || startDay == thisWeekEnd) {
            //This Week
            _eventsWeek.add(_convertEventToEntry(event, calendar, true, true, true));
          } else if (startDay.isAfter(nextWeekStart) && startDay.isBefore(nextWeekEnd) || startDay == nextWeekStart || startDay == nextWeekEnd) {
            //Next Week
            _eventsNextWeek.add(_convertEventToEntry(event, calendar, true, true, false));
          } else if (startMonth == thisMonth) {
            //This Month
            _eventsMonth.add(_convertEventToEntry(event, calendar, true, true, false));
          } else {
            //Next Months
            for (int addedMonth = 1; addedMonth < maxForesight; addedMonth++) {
              DateTime addedMonthDate = DateTime(now.year, now.month + addedMonth);

              if (startMonth == addedMonthDate) {
                if (!_nextMonths.containsKey(addedMonth)) {
                  _nextMonths[addedMonth] = <EventListEntry>[];
                }

                _nextMonths[addedMonth]?.add(_convertEventToEntry(event, calendar, true, true, false));
              }
            }
          }
        } else {
          //Mehrere Tage

          Duration difference = DateTime(endDay.year, endDay.month, endDay.day, 12).difference(startDay);
          int durationDays = difference.inDays + 1;

          //Today
          if (today.isAfter(startDay) && today.isBefore(endDay) || startDay == today || endDay == today) {
            Duration todayDifference = DateTime(today.year, today.month, today.day, 12).difference(startDay);
            int currentDuration = todayDifference.inDays + 1;

            _eventsToday.add(_convertEventToEntry(event, calendar, false, false, false, duration: durationDays, currentDay: currentDuration));
          }

          //Tomorrow
          if (tomorrow.isAfter(startDay) && tomorrow.isBefore(endDay) || startDay == tomorrow || endDay == tomorrow) {
            Duration tomorrowDifference = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12).difference(startDay);
            int tomorrowDuration = tomorrowDifference.inDays + 1;

            _eventsTomorrow.add(_convertEventToEntry(event, calendar, false, false, false, duration: durationDays, currentDay: tomorrowDuration));
          }

          //This Week
          if (startDay.isBefore(thisWeekEnd) && endDay.isAfter(thisWeekStart) || startDay == thisWeekEnd || endDay == thisWeekStart) {
            _eventsWeek.add(_convertEventToEntry(event, calendar, false, true, false));
          }

          //Next Week
          if (startDay.isBefore(nextWeekEnd) && endDay.isAfter(nextWeekStart) || startDay == nextWeekEnd || endDay == nextWeekStart) {
            _eventsNextWeek.add(_convertEventToEntry(event, calendar, false, true, false));
          }

          //This Month
          if (thisMonth.isBefore(endMonth) && thisMonth.isAfter(startMonth) || startMonth == thisMonth || endMonth == thisMonth) {
            _eventsMonth.add(_convertEventToEntry(event, calendar, false, true, false));
          }

          //Next Months
          for (int addedMonth = 1; addedMonth < maxForesight; addedMonth++) {
            DateTime addedMonthDate = DateTime(now.year, now.month + addedMonth);

            if (addedMonthDate.isBefore(endMonth) && addedMonthDate.isAfter(startMonth) || startMonth == addedMonthDate || endMonth == addedMonthDate) {
              if (!_nextMonths.containsKey(addedMonth)) {
                _nextMonths[addedMonth] = <EventListEntry>[];
              }

              _nextMonths[addedMonth]?.add(_convertEventToEntry(event, calendar, false, true, false));
            }
          }
        }
      }
    }

    if (_eventsToday.isNotEmpty) {
      _sortEventEntryList(_eventsToday);
      _eventEntryList.add(const EventListEntry(EventListEntryType.headline, "Heute", null));
      _eventEntryList.addAll(_eventsToday);
    }

    if (_eventsTomorrow.isNotEmpty) {
      _sortEventEntryList(_eventsTomorrow);
      _eventEntryList.add(const EventListEntry(EventListEntryType.headline, "Morgen", null));
      _eventEntryList.addAll(_eventsTomorrow);
    }

    if (_eventsWeek.isNotEmpty) {
      _sortEventEntryList(_eventsWeek);
      _eventEntryList.add(const EventListEntry(EventListEntryType.headline, "Diese Woche", null));
      _eventEntryList.addAll(_eventsWeek);
    }

    if (_eventsNextWeek.isNotEmpty) {
      _sortEventEntryList(_eventsNextWeek);
      _eventEntryList.add(const EventListEntry(EventListEntryType.headline, "Nächste Woche", null));
      _eventEntryList.addAll(_eventsNextWeek);
    }

    if (_eventsMonth.isNotEmpty) {
      _sortEventEntryList(_eventsMonth);
      _eventEntryList.add(const EventListEntry(EventListEntryType.headline, "Diesen Monat", null));
      _eventEntryList.addAll(_eventsMonth);
    }

    for (int addedMonth = 1; addedMonth < maxForesight; addedMonth++) {
      if (_nextMonths.containsKey(addedMonth)) {
        if (_nextMonths[addedMonth]!.isNotEmpty) {
          String monthName = DateFormat.MMMM("de_DE").format(DateTime(now.year, now.month + addedMonth));

          _sortEventEntryList(_nextMonths[addedMonth]!);
          _eventEntryList.add(EventListEntry(EventListEntryType.headline, monthName, null));
          _eventEntryList.addAll(_nextMonths[addedMonth]!);
        }
      }
    }
  }

  String generateCalendarEventHeadline(Calendar calendar) {
    int count = 0;

    if (_eventsToday.isNotEmpty) {
      for (var listItem in _eventsToday) {
        if (listItem.uiEvent?.calendar.id == calendar.id) count++;
      }

      if (count == 1) {
        return "1 Termin heute";
      } else if (count > 1) {
        return ("$count Termine heute");
      }
    }

    if (_eventsTomorrow.isNotEmpty) {
      for (var listItem in _eventsTomorrow) {
        if (listItem.uiEvent?.calendar.id == calendar.id) count++;
      }

      if (count == 1) {
        return "1 Termin morgen";
      } else if (count > 1) {
        return ("$count Termine morgen");
      }
    }

    if (_eventsWeek.isNotEmpty) {
      for (var listItem in _eventsWeek) {
        if (listItem.uiEvent?.calendar.id == calendar.id) count++;
      }

      if (count == 1) {
        return "1 Termin diese Woche";
      } else if (count > 1) {
        return ("$count Termine diese Woche");
      }
    }

    if (_eventsNextWeek.isNotEmpty) {
      for (var listItem in _eventsNextWeek) {
        if (listItem.uiEvent?.calendar.id == calendar.id) count++;
      }

      if (count == 1) {
        return "1 Termin nächste Woche";
      } else if (count > 1) {
        return ("$count Termine nächste Woche");
      }
    }

    return "Keine anstehenden Termine";
  }

  List<EventListEntry> getGeneratedEventList() {
    return _eventEntryList;
  }

  void _sortEventEntryList(List<EventListEntry> list) {
    list.sort((a, b) {
      if (a.entryType != EventListEntryType.event || b.entryType != EventListEntryType.event) {
        return 0;
      }

      DateTime? aTime = a.uiEvent?.event.start;
      DateTime? bTime = b.uiEvent?.event.start;

      if (aTime == null || bTime == null) {
        return 0;
      }

      if (aTime.isAfter(bTime)) {
        return 1;
      } else if (aTime.isBefore(bTime)) {
        return -1;
      }

      return 0;
    });
  }

  EventListEntry _convertEventToEntry(Event event, Calendar calendar, bool singleDayEvent, bool includeDateStamp, bool dateStampAsWeekday, {int currentDay = 0, int duration = 0}) {
    String firstDateLine = "";
    String secondDateLine = "";

    String title = event.title;

    if (singleDayEvent) {
      if (event.dayLong) {
        if (includeDateStamp) {
          if (dateStampAsWeekday) {
            firstDateLine = weekdayFormat.format(event.start);
          } else {
            firstDateLine = dateFormat.format(event.start);
          }
        } else {
          if (dateStampAsWeekday) {
            firstDateLine = weekdayFormat.format(event.start);
          } else {
            firstDateLine = "Ganztägig";
          }
        }
      } else {
        if (includeDateStamp) {
          if (dateStampAsWeekday) {
            firstDateLine = weekdayFormat.format(event.start);
          } else {
            firstDateLine = dateFormat.format(event.start);
          }
          secondDateLine = "${timeFormat.format(event.start)} - ${timeFormat.format(event.end)} Uhr";
        } else {
          firstDateLine = "${timeFormat.format(event.start)} - ${timeFormat.format(event.end)} Uhr";
        }
      }
    } else {
      if (currentDay != 0 && duration != 0) {
        title += " (Tag $currentDay/$duration)";
      }

      if (event.dayLong) {
        if (includeDateStamp) {
          firstDateLine = "${dateFormat.format(event.start)} -";
          secondDateLine = dateFormat.format(event.end);
        } else {
          firstDateLine = "Ganztägig";
        }
      } else {
        if (currentDay != 0 && duration != 0) {
          if (currentDay == 1) {
            firstDateLine = "Beginn: ${timeFormat.format(event.start)}";
          } else if (currentDay == duration) {
            firstDateLine = "Ende: ${timeFormat.format(event.end)}";
          } else {
            firstDateLine = "Ganztägig";
          }
        } else {
          if (includeDateStamp) {
            firstDateLine = "${dateFormat.format(event.start)}, ${timeFormat.format(event.start)} -";
            secondDateLine = "${dateFormat.format(event.end)}, ${timeFormat.format(event.end)}";
          }
        }
      }
    }

    UiEvent uiEvent = UiEvent(event, calendar, title, firstDateLine, secondDateLine);

    EventListEntry entry = EventListEntry(EventListEntryType.event, "", uiEvent);
    return entry;
  }
}

enum EventListEntryType { headline, event }

class EventListEntry {
  const EventListEntry(this.entryType, this.headlineText, this.uiEvent);

  final UiEvent? uiEvent;
  final EventListEntryType entryType;

  final String headlineText;
}
