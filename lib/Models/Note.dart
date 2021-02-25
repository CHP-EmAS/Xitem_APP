import 'package:de/Controllers/ApiController.dart';
import 'package:flutter/cupertino.dart';

class Note {
  Note(this.noteID, this.title, this.content, this.color, this.pinned, this.associatedCalendar, this.ownerID, this.creationDate, this.modificationDate);

  final BigInt noteID;

  String title;
  String content;

  Color color;
  bool pinned;

  final String associatedCalendar;
  final String ownerID;

  DateTime creationDate;
  DateTime modificationDate;

  Future<void> reload() async {
    Note reloadedNote = await Api.loadSingleNote(associatedCalendar, noteID);

    if (reloadedNote == null) return;

    if (this.noteID != reloadedNote.noteID) {
      print("Unexpected Error when reloading a Note, IDs not equal!");
      return;
    }

    this.creationDate = reloadedNote.creationDate;

    this.title = reloadedNote.title;
    this.content = reloadedNote.content;
  }
}
