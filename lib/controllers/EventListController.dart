import 'package:de/controllers/SettingController.dart';
import 'package:de/controllers/UserController.dart';
import 'package:de/models/Calendar.dart';
import 'package:de/models/Event.dart';
import 'package:de/models/Voting.dart';
import 'package:intl/intl.dart';

class EventListController {
  //--------- Current Event List ---------//
  static List<EventListEntry> eventEntryList = new List<EventListEntry>();

  //All Events Sorted by specific days
  static List<EventListEntry> _eventsToday = new List<EventListEntry>();
  static List<EventListEntry> _eventsTomorrow = new List<EventListEntry>();
  static List<EventListEntry> _eventsWeek = new List<EventListEntry>();
  static List<EventListEntry> _eventsNextWeek = new List<EventListEntry>();
  static List<EventListEntry> _eventsMonth = new List<EventListEntry>();
  static Map<int, List<EventListEntry>> _nextMonths = new Map<int, List<EventListEntry>>();

  //Votings which the User has not yet completed
  static List<EventListEntry> _notCompletedVotings = new List<EventListEntry>();

  static EventListEntry convertEventToEntry(Event event, bool singleDayEvent, bool includeDateStamp, bool dateStampAsWeekday, {int currentDay, int duration}) {
    final dateFormat = new DateFormat("EEEE, d. MMMM", "de_DE");
    final timeFormat = new DateFormat.Hm('de_DE');
    final weekdayFormat = new DateFormat("EEEE", "de_DE");

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
          secondDateLine = timeFormat.format(event.start) + " - " + timeFormat.format(event.end) + " Uhr";
        } else {
          firstDateLine = timeFormat.format(event.start) + " - " + timeFormat.format(event.end) + " Uhr";
        }
      }
    } else {
      if (currentDay != null && duration != null) {
        title += " (Tag " + currentDay.toString() + "/" + duration.toString() + ")";
      }

      if (event.dayLong) {
        if (includeDateStamp) {
          firstDateLine = dateFormat.format(event.start) + " -";
          secondDateLine = dateFormat.format(event.end);
        } else {
          firstDateLine = "Ganztägig";
        }
      } else {
        if (currentDay != null && duration != null) {
          if (currentDay == 1) {
            firstDateLine = "Beginn: " + timeFormat.format(event.start);
          } else if (currentDay == duration) {
            firstDateLine = "Ende: " + timeFormat.format(event.end);
          } else {
            firstDateLine = "Ganztägig";
          }
        } else {
          if (includeDateStamp) {
            firstDateLine = dateFormat.format(event.start) + ", " + timeFormat.format(event.start) + " -";
            secondDateLine = dateFormat.format(event.end) + ", " + timeFormat.format(event.end);
          }
        }
      }
    }

    CalendarEvent calendarEvent = new CalendarEvent(event.eventID, firstDateLine, secondDateLine, title, event.color, event.calendarID);

    EventListEntry entry = new EventListEntry(EntryType.EVENT, "", calendarEvent, null);
    return entry;
  }

  static DateTime getDate(DateTime d) => DateTime(d.year, d.month, d.day);

  static void generateEventList() {
    eventEntryList.clear();

    _notCompletedVotings.clear();

    _eventsToday.clear();
    _eventsTomorrow.clear();
    _eventsWeek.clear();
    _eventsNextWeek.clear();
    _eventsMonth.clear();
    _nextMonths.clear();

    final int maxForesight = 3;

    DateTime now = DateTime.now();

    DateTime today = getDate(now);
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    DateTime thisWeekStart = getDate(today.subtract(Duration(days: today.weekday - 1)));
    DateTime thisWeekEnd = getDate(today.add(Duration(days: DateTime.daysPerWeek - today.weekday)));

    DateTime nextWeek = DateTime(now.year, now.month, now.day + 7);
    DateTime nextWeekStart = getDate(nextWeek.subtract(Duration(days: nextWeek.weekday - 1)));
    DateTime nextWeekEnd = getDate(nextWeek.add(Duration(days: DateTime.daysPerWeek - nextWeek.weekday)));

    DateTime thisMonth = DateTime(now.year, now.month);

    UserController.calendarList.forEach((calendarID, calendar) {

      if(SettingController.getShowNewVotingOnEventScreen()) {
        calendar.votingMap.forEach((votingID, voting) {
          if (!voting.userHasVoted) {
            EventListEntry entry = new EventListEntry(EntryType.VOTING, "", null, voting);
            _notCompletedVotings.add(entry);
          }
        });
      }

      calendar.dynamicEventMap.forEach((eventID, event) {
        DateTime startDay = getDate(event.start);
        DateTime endDay = getDate(event.end);

        DateTime startMonth = DateTime(startDay.year, startDay.month);
        DateTime endMonth = DateTime(endDay.year, endDay.month + 1, 0);

        if (!today.isAfter(endDay)) {
          if (startDay.compareTo(endDay) == 0) {
            //Gleicher Tag

            if (startDay == today) {
              //Today
              _eventsToday.add(convertEventToEntry(event, true, false, false));
            } else if (startDay == tomorrow) {
              //Tomorrow
              _eventsTomorrow.add(convertEventToEntry(event, true, false, false));
            } else if (startDay.isAfter(thisWeekStart) && startDay.isBefore(thisWeekEnd) || startDay == thisWeekStart || startDay == thisWeekEnd) {
              //This Week
              _eventsWeek.add(convertEventToEntry(event, true, true, true));
            } else if (startDay.isAfter(nextWeekStart) && startDay.isBefore(nextWeekEnd) || startDay == nextWeekStart || startDay == nextWeekEnd) {
              //Next Week
              _eventsNextWeek.add(convertEventToEntry(event, true, true, false));
            } else if (startMonth == thisMonth) {
              //This Month
              _eventsMonth.add(convertEventToEntry(event, true, true, false));
            } else {
              //Next Months
              for (int addedMonth = 1; addedMonth < maxForesight; addedMonth++) {
                DateTime addedMonthDate = DateTime(now.year, now.month + addedMonth);

                if (startMonth == addedMonthDate) {
                  if (!_nextMonths.containsKey(addedMonth)) _nextMonths[addedMonth] = new List<EventListEntry>();

                  _nextMonths[addedMonth].add(convertEventToEntry(event, true, true, false));
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

              _eventsToday.add(convertEventToEntry(event, false, false, false, duration: durationDays, currentDay: currentDuration));
            }

            //Tomorrow
            if (tomorrow.isAfter(startDay) && tomorrow.isBefore(endDay) || startDay == tomorrow || endDay == tomorrow) {
              Duration tomorrowDifference = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12).difference(startDay);
              int tomorrowDuration = tomorrowDifference.inDays + 1;

              _eventsTomorrow.add(convertEventToEntry(event, false, false, false, duration: durationDays, currentDay: tomorrowDuration));
            }

            //This Week
            if (startDay.isBefore(thisWeekEnd) && endDay.isAfter(thisWeekStart) || startDay == thisWeekEnd || endDay == thisWeekStart) {
              _eventsWeek.add(convertEventToEntry(event, false, true, false));
            }

            //Next Week
            if (startDay.isBefore(nextWeekEnd) && endDay.isAfter(nextWeekStart) || startDay == nextWeekEnd || endDay == nextWeekStart) {
              _eventsNextWeek.add(convertEventToEntry(event, false, true, false));
            }

            //This Month
            if (thisMonth.isBefore(endMonth) && thisMonth.isAfter(startMonth) || startMonth == thisMonth || endMonth == thisMonth) {
              _eventsMonth.add(convertEventToEntry(event, false, true, false));
            }

            //Next Months
            for (int addedMonth = 1; addedMonth < maxForesight; addedMonth++) {
              DateTime addedMonthDate = DateTime(now.year, now.month + addedMonth);

              if (addedMonthDate.isBefore(endMonth) && addedMonthDate.isAfter(startMonth) || startMonth == addedMonthDate || endMonth == addedMonthDate) {
                if (!_nextMonths.containsKey(addedMonth)) _nextMonths[addedMonth] = new List<EventListEntry>();

                _nextMonths[addedMonth].add(convertEventToEntry(event, false, true, false));
              }
            }
          }
        }
      });
    });

    if (_notCompletedVotings.isNotEmpty) {
      eventEntryList.add(new EventListEntry(EntryType.HEADLINE, "Deine Stimme wird benötigt ♥", null, null));
      eventEntryList.addAll(_notCompletedVotings);
    }

    if (_eventsToday.isNotEmpty) {
      _sortEventEntryList(_eventsToday);
      eventEntryList.add(new EventListEntry(EntryType.HEADLINE, "Heute", null, null));
      eventEntryList.addAll(_eventsToday);
    }

    if (_eventsTomorrow.isNotEmpty) {
      _sortEventEntryList(_eventsTomorrow);
      eventEntryList.add(new EventListEntry(EntryType.HEADLINE, "Morgen", null, null));
      eventEntryList.addAll(_eventsTomorrow);
    }

    if (_eventsWeek.isNotEmpty) {
      _sortEventEntryList(_eventsWeek);
      eventEntryList.add(new EventListEntry(EntryType.HEADLINE, "Diese Woche", null, null));
      eventEntryList.addAll(_eventsWeek);
    }

    if (_eventsNextWeek.isNotEmpty) {
      _sortEventEntryList(_eventsNextWeek);
      eventEntryList.add(new EventListEntry(EntryType.HEADLINE, "Nächste Woche", null, null));
      eventEntryList.addAll(_eventsNextWeek);
    }

    if (_eventsMonth.isNotEmpty) {
      _sortEventEntryList(_eventsMonth);
      eventEntryList.add(new EventListEntry(EntryType.HEADLINE, "Diesen Monat", null, null));
      eventEntryList.addAll(_eventsMonth);
    }

    for (int addedMonth = 1; addedMonth < maxForesight; addedMonth++) {
      if (_nextMonths.containsKey(addedMonth)) {
        if (_nextMonths[addedMonth].isNotEmpty) {
          String monthName = DateFormat.MMMM("de_DE").format(DateTime(now.year, now.month + addedMonth));

          _sortEventEntryList(_nextMonths[addedMonth]);
          eventEntryList.add(new EventListEntry(EntryType.HEADLINE, monthName, null, null));
          eventEntryList.addAll(_nextMonths[addedMonth]);
        }
      }
    }
  }

  static void _sortEventEntryList(List<EventListEntry> list) {
    list.sort((a, b) {
      if (a.entryType != EntryType.EVENT || b.entryType != EntryType.EVENT) return 0;

      if (!UserController.calendarList.containsKey(a.event.calendarID) || !UserController.calendarList.containsKey(b.event.calendarID)) return 0;

      Calendar aCalendar = UserController.calendarList[a.event.calendarID];
      Calendar bCalendar = UserController.calendarList[b.event.calendarID];

      if (!aCalendar.dynamicEventMap.containsKey(a.event.eventID) || !bCalendar.dynamicEventMap.containsKey(b.event.eventID)) return 0;

      DateTime aTime = aCalendar.dynamicEventMap[a.event.eventID].start;
      DateTime bTime = bCalendar.dynamicEventMap[b.event.eventID].start;

      if (aTime.isAfter(bTime))
        return 1;
      else if (aTime.isBefore(bTime)) return -1;

      return 0;
    });
  }

  static String generateCalendarEventHeadline(String calendarID) {
    int count = 0;

    if (_eventsToday.isNotEmpty) {
      _eventsToday.forEach((listItem) {
        if (listItem.event.calendarID == calendarID) count++;
      });

      if (count == 1) {
        return "1 Termin heute";
      } else if (count > 1) {
        return (count.toString() + " Termine heute");
      }
    }

    if (_eventsTomorrow.isNotEmpty) {
      _eventsTomorrow.forEach((listItem) {
        if (listItem.event.calendarID == calendarID) count++;
      });

      if (count == 1) {
        return "1 Termin morgen";
      } else if (count > 1) {
        return (count.toString() + " Termine morgen");
      }
    }

    if (_eventsWeek.isNotEmpty) {
      _eventsWeek.forEach((listItem) {
        if (listItem.event.calendarID == calendarID) count++;
      });

      if (count == 1) {
        return "1 Termin diese Woche";
      } else if (count > 1) {
        return (count.toString() + " Termine diese Woche");
      }
    }

    if (_eventsNextWeek.isNotEmpty) {
      _eventsNextWeek.forEach((listItem) {
        if (listItem.event.calendarID == calendarID) count++;
      });

      if (count == 1) {
        return "1 Termin nächste Woche";
      } else if (count > 1) {
        return (count.toString() + " Termine nächste Woche");
      }
    }

    return "Keine anstehenden Termine";
  }
}

enum EntryType { HEADLINE, VOTING, EVENT }

class EventListEntry {
  EventListEntry(this.entryType, this.headlineText, this.event, this.voting);

  final CalendarEvent event;
  final EntryType entryType;

  final String headlineText;

  final Voting voting;
}
