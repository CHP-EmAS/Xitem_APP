import 'package:flutter/cupertino.dart';

class Note {
  Note(this.noteID, this.title, this.content, this.color, this.pinned, this.associatedCalendar, this.ownerID, this.creationDate, this.modificationDate);

  final BigInt noteID;

  String title;
  String content;

  int color;
  bool pinned;

  final String associatedCalendar;
  final String ownerID;

  DateTime creationDate;
  DateTime modificationDate;
}
