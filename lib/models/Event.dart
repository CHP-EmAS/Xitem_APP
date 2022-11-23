import 'package:de/controllers/ApiController.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Event {
  Event(this.eventID, this.start, this.end, this.title, this.description, this.color, this.calendarID, this.userID, this.dayLong, this.creationDate);

  final BigInt eventID;

  DateTime start;
  DateTime end;

  DateTime creationDate;

  String title;
  String description;

  Color color;

  final String calendarID;
  final String userID;

  bool dayLong;

  Future<void> reload() async {
    Event reloadedEvent = await Api.loadSingleEvent(calendarID, eventID);

    if (reloadedEvent == null) return;

    if (this.eventID != reloadedEvent.eventID) {
      print("Unexpected Error when reloading Event, IDs not equal!");
      return;
    }

    this.start = reloadedEvent.start;
    this.end = reloadedEvent.end;

    this.creationDate = reloadedEvent.creationDate;
    this.color = reloadedEvent.color;

    this.title = reloadedEvent.title;
    this.description = reloadedEvent.description;

    this.dayLong = reloadedEvent.dayLong;
  }
}

class CalendarEvent {
  CalendarEvent(this.eventID, this.startTime, this.endTime, this.title, this.color, this.calendarID);

  final BigInt eventID;

  String startTime;
  String endTime;

  String title;
  Color color;

  String calendarID;
}
