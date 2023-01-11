import 'package:xitem/models/Calendar.dart';

class Event {
  Event(this.eventID, this.start, this.end, this.title, this.description, this.color, this.calendarID, this.userID, this.dayLong, this.creationDate);

  final BigInt eventID;

  DateTime start;
  DateTime end;

  DateTime creationDate;

  String title;
  String? description;

  int color;

  final String calendarID;
  final String userID;

  bool dayLong;
}

class UiEvent {
  const UiEvent(this.event, this.calendar, this.headline, this.firstLine, this.secondLine);

  final Event event;
  final Calendar calendar;

  final String firstLine;
  final String secondLine;
  final String headline;
}

class EventData {
  EventData(this.selectedCalendar, this.title, this.startDate, this.endDate, this.daylong, this.color, this.description);

  final Calendar selectedCalendar;

  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool daylong;
  final int color;
  final String description;
}
