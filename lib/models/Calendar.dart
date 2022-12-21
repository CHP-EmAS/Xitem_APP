import 'package:flutter/material.dart';
import 'package:xitem/controllers/CalendarMemberController.dart';
import 'package:xitem/controllers/EventController.dart';
import 'package:xitem/controllers/NoteController.dart';


class Calendar {
  Calendar({required this.eventController, required this.calendarMemberController, required this.noteController, required this.id, required String fullName, required this.canJoin, required String creationDate, required this.color, required this.icon}) :
        name = fullName.split('#')[0],
        hash = fullName.split('#')[1],
        creationDate = DateTime.parse(creationDate);

  final EventController eventController;
  final CalendarMemberController calendarMemberController;
  final NoteController noteController;
  
  final String id;
  late final DateTime creationDate;

  String name, hash;

  int color;
  IconData icon;
  bool canJoin;

  final Map<int, String> colorLegend = {};
}
