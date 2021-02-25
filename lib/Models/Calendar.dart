import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Interfaces/api_interfaces.dart';
import 'package:de/Models/Event.dart';
import 'package:de/Models/Member.dart';
import 'package:de/Models/Note.dart';
import 'package:de/Models/Voting.dart';
import 'package:de/Widgets/Dialogs/event_popups.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Calendar {
  Calendar(this.id, String fullName, bool canJoin, String creationDate, Color color, IconData icon, bool isOwner, bool canCreateEvents, bool canEditEvents) {
    this.name = fullName.split('#')[0];
    this.hash = fullName.split('#')[1];
    this.canJoin = canJoin;
    this.creationDate = DateTime.parse(creationDate);

    this.color = color;
    this.icon = icon;

    this.isOwner = isOwner;
    this.canCreateEvents = canCreateEvents;
    this.canEditEvents = canEditEvents;
  }

  //Calendar Information
  final String id; //ID = UUIDV4

  //name = Kalendername (in Einstellung änderbar!), hash = leichter ID, wird benötigt um einem Kalender beizutreten bsp. Name#1234
  //Damit ein beliebiger Kalendername gewählt werden kann wird ein eindeutiger hashwert angehängt.
  String name, hash;

  //Datum an dem der Kalender erstellt wurde (Dateonly)
  DateTime creationDate;

  //Farbe und Icon die der angemeldete Nutzer für diesen Kalender eingestellt hat
  Color color;
  IconData icon;

  //Kann man diesem Kalender beitreten? False = nein
  bool canJoin;

  //Berechtigungs Informationen des angemeldeten Nutzers bezüglich des Kalenders
  bool isOwner, canCreateEvents, canEditEvents;

  //Mitgliederlist wird sortiert nach Rang
  List<AssociatedUser> assocUserList = new List<AssociatedUser>();

  //Event Listen
  Map<BigInt, Event> dynamicEventMap = new Map<BigInt, Event>();
  Map<String, LoadedMonth> loadedUIMonths = new Map<String, LoadedMonth>();

  Map<int, Voting> votingMap = new Map<int, Voting>();
  Map<BigInt, Note> noteMap = new Map<BigInt, Note>();

  Future<bool> reload() async {
    Calendar reloadedCalendar = await Api.loadSingleCalendar(id);

    if (reloadedCalendar == null) return false;

    if (this.id != reloadedCalendar.id) {
      print("Unexpected Error when loading Calendar, IDs not equal!");
      return false;
    }

    this.name = reloadedCalendar.name;
    this.hash = reloadedCalendar.hash;
    this.canJoin = reloadedCalendar.canJoin;
    this.creationDate = reloadedCalendar.creationDate;
    this.color = reloadedCalendar.color;
    this.icon = reloadedCalendar.icon;
    this.isOwner = reloadedCalendar.isOwner;
    this.canCreateEvents = reloadedCalendar.canCreateEvents;
    this.canEditEvents = reloadedCalendar.canEditEvents;

    assocUserList.clear();
    dynamicEventMap.clear();
    loadedUIMonths.clear();
    votingMap.clear();
    noteMap.clear();

    bool assocUserLoadedCorrectly = await loadAssociatedUsers();
    bool currentEventsLoadedCorrectly = await loadCurrentEvents();
    bool votingsLoadedCorrectly = await loadAllVotings();
    bool notesLoadedCorrectly = await loadAllNotes();

    return (assocUserLoadedCorrectly && currentEventsLoadedCorrectly && votingsLoadedCorrectly && notesLoadedCorrectly);
  }

  Future<bool> changeCalendarLayout(Color color, IconData icon) async {
    if (await Api.patchCalendarLayout(this.id, PatchCalendarLayoutRequest(color, icon))) {
      await reload();
      return true;
    }

    return false;
  }

  Future<bool> changeCalendarInformation(String name, bool canJoin, String password) async {
    if (password == "") password = null;

    if (await Api.patchCalendar(this.id, PatchCalendarRequest(name, canJoin, password))) {
      await reload();
      return true;
    }

    return false;
  }

  Future<String> getInvitationToken(bool canCreateEvents, bool canEditEvents, int duration) async {
    return Api.getCalendarInvitationToken(this.id, CalendarInvitationTokenRequest(canCreateEvents, canEditEvents, duration));
  }

  //Associated User functions
  Future<bool> loadAssociatedUsers() async {
    List<AssociatedUser> loadedUsers = await Api.loadAssociatedUsers(this.id);

    if (loadedUsers == null) return false;
    this.assocUserList = loadedUsers;

    sortAssociatedUsers();

    print(loadedUsers.length.toString() + " Members loaded in Calendar " + this.name);

    return true;
  }

  Future<bool> removeAssociatedUsers(String userID, String userPassword) async {
    if (!await Api.checkHashPassword(userPassword)) return false;

    if (!await Api.removeAssociatedUser(this.id, userID)) return false;

    int memberIndex = -1;
    this.assocUserList.asMap().forEach((index, member) {
      if (member.userID == userID) {
        memberIndex = index;
      }
    });

    if (memberIndex >= 0 && memberIndex < assocUserList.length) {
      assocUserList.removeAt(memberIndex);
    }

    return true;
  }

  void sortAssociatedUsers() {
    assocUserList.sort((a, b) {
      if (a.userID == UserController.user.userID) return 1;
      if (b.userID == UserController.user.userID) return -1;

      if (a.isOwner && !b.isOwner) return -1;
      if (!a.isOwner && b.isOwner) return 1;
      if (a.isOwner && b.isOwner) return 0;

      if (a.canEditEvents && !b.canEditEvents) return -1;
      if (!a.canEditEvents && b.canEditEvents) return 1;
      if (a.canEditEvents && b.canEditEvents) return 0;

      if (a.canCreateEvents && !b.canCreateEvents) return -1;
      if (!a.canCreateEvents && b.canCreateEvents) return 1;

      return 0;
    });
  }

  //Event functions
  Future<bool> loadCurrentEvents() async {
    DateTime now = DateTime.now();

    List<Event> loadedEvents = await Api.loadEvents(this.id, DateTime(now.year, now.month - 6, 1).subtract(Duration(days: 7)), DateTime(now.year, now.month + 7, 1).add(Duration(days: 7)));

    if (loadedEvents == null) return false;

    for (int loadedMonth = -6; loadedMonth <= 6; loadedMonth++) {
      DateTime loadedDate = DateTime(now.year, now.month + loadedMonth);

      String monthlyKey = loadedDate.year.toString() + loadedDate.month.toString();
      loadedUIMonths[monthlyKey] = new LoadedMonth(loadedDate.year, loadedDate.month, this.id);

      loadedUIMonths[monthlyKey].addEventsManually(loadedEvents, true);
    }

    loadedEvents.forEach((event) {
      dynamicEventMap[event.eventID] = event;
    });

    return true;
  }

  Future<Map<DateTime, List<CalendarEvent>>> getUiEvents(int year, int month) async {
    String monthlyKey = year.toString() + month.toString();

    if (!loadedUIMonths.containsKey(monthlyKey)) {
      loadedUIMonths[monthlyKey] = new LoadedMonth(year, month, this.id);
    }

    if (!loadedUIMonths[monthlyKey].isLoaded()) {
      List<Event> events = await loadedUIMonths[monthlyKey].load();

      events.forEach((event) {
        dynamicEventMap[event.eventID] = event;
      });
    }

    return new Map<DateTime, List<CalendarEvent>>.from(loadedUIMonths[monthlyKey].uiEvents);
  }

  Future<bool> createEvent(EventData newEvent) async {
    BigInt eventID = await Api.createEvent(this.id, CreateEventRequest(newEvent.startDate, newEvent.endDate, newEvent.title, newEvent.daylong, newEvent.description, newEvent.color));
    if (eventID == null) return false;

    await reload();

    return true;
  }

  Future<bool> editEvent(BigInt eventID, DateTime newStartDate, DateTime newEndDate, String newTitle, String newDescription, bool dayLong, Color newColor) async {
    if (await Api.patchEvent(this.id, eventID, PatchEventRequest(newStartDate, newEndDate, newTitle, dayLong, newDescription, newColor))) {
      await reload();
      return true;
    }

    return false;
  }

  Future<bool> removeEvent(BigInt eventToRemove) async {
    bool success = await Api.deleteEvent(this.id, eventToRemove);

    if (!success) return false;

    if (dynamicEventMap.remove(eventToRemove) == null) print("Error Event to remove was not in EventList");

    _removeSingleUIEvent(eventToRemove);

    return true;
  }

  void _removeSingleUIEvent(BigInt eventToDelete) {
    loadedUIMonths.forEach((monthlyKey, loadedMonth) {
      loadedMonth.uiEvents.forEach((date, eventList) {
        List<CalendarEvent> copiedEventList = new List<CalendarEvent>.from(eventList);

        copiedEventList.forEach((calendarEvent) {
          if (calendarEvent.eventID == eventToDelete) {
            if (eventList.remove(calendarEvent))
              print("UIEvent gelöscht!");
            else
              print("UIEvent nicht gelöscht!");
          }
        });
      });
    });
  }

  // voting functions
  Future<bool> loadAllVotings() async {
    List<Voting> votings = await Api.loadAllVoting(this.id);
    if (votings == null) return false;

    votingMap.clear();

    votings.forEach((voting) {
      votingMap[voting.votingID] = voting;
    });

    return true;
  }

  Future<bool> createVoting(String title, bool multipleChoice, bool abstentionAllowed, List<NewChoice> choices) async {
    int votingID = await Api.createVoting(this.id, CreateVotingRequest(title, multipleChoice, abstentionAllowed, choices));
    if (votingID == null) return false;

    await reload();

    return true;
  }

  Future<bool> removeVoting(int votingID) async {
    bool success = await Api.deleteVoting(this.id, votingID);

    if (!success) return false;

    await loadAllVotings();

    return true;
  }

  Future<bool> vote(int votingID, List<int> votes) async {
    bool success = await Api.vote(this.id, votingID, VoteRequest(votes));
    if (!success) return false;

    await reload();

    return true;
  }

  // note functions
  Future<bool> loadAllNotes() async {
    List<Note> notes = await Api.loadAllNotes(this.id);
    if (notes == null) return false;

    noteMap.clear();

    notes.forEach((note) {
      noteMap[note.noteID] = note;
    });

    return true;
  }

  Future<bool> createNote(String title, String content, bool pinned, Color color) async {
    BigInt noteID = await Api.createNote(this.id, CreateNoteRequest(title, content, pinned, color));
    if (noteID == null) return false;

    await reload();

    return true;
  }

  Future<bool> removeNote(BigInt noteID) async {
    bool success = await Api.deleteNote(this.id, noteID);

    if (!success) return false;

    await loadAllNotes();

    return true;
  }

  Future<bool> changeNote(BigInt noteID, String title, String content, bool pinned, Color color) async {
    bool success = await Api.patchNote(this.id, noteID, PatchNoteRequest(title, content, pinned, color));
    if (!success) return false;

    await reload();

    return true;
  }
}

class LoadedMonth {
  LoadedMonth(this.year, this.month, this.calendarID);

  final int year;
  final int month;

  final String calendarID;

  bool _isCompletelyLoaded = false;
  Map<DateTime, List<CalendarEvent>> uiEvents = new Map<DateTime, List<CalendarEvent>>();

  final timeFormat = new DateFormat.Hm('de_DE');

  void addEventsManually(List<Event> events, bool setLoadedFlag) {
    if (events == null) return;

    events.forEach((event) {
      _convertEventToUiEvent(event);
    });

    if (setLoadedFlag) _isCompletelyLoaded = true;
  }

  Future<List<Event>> load() async {
    List<Event> events = await Api.loadEvents(this.calendarID, DateTime(year, month, 1).subtract(Duration(days: 7)), DateTime(year, month + 1, 1).add(Duration(days: 7)));

    if (events == null) return null;

    events.forEach((event) {
      _convertEventToUiEvent(event);
    });

    _isCompletelyLoaded = true;
    return events;
  }

  void _convertEventToUiEvent(Event event) {
    DateTime startDay = DateTime(event.start.year, event.start.month, event.start.day);
    DateTime endDay = DateTime(event.end.year, event.end.month, event.end.day);

    if (startDay.compareTo(endDay) == 0) {
      //Gleicher Tag

      if (startDay.isBefore(DateTime(year, month, 1).subtract(Duration(days: 7))))
        return;
      else if (startDay.isAfter(DateTime(year, month + 1, 1).add(Duration(days: 7)))) return;

      if (!uiEvents.containsKey(startDay)) {
        uiEvents[startDay] = new List<CalendarEvent>();
      }

      CalendarEvent newCalendarEvent = new CalendarEvent(
          event.eventID, //ID
          event.dayLong ? "Ganztägig" : ("Start: " + timeFormat.format(event.start)), //starttime String
          event.dayLong ? "" : ("Ende: " + timeFormat.format(event.end)), //endtime String
          event.title, //title
          event.color, //color
          event.calendarID //calendar ID
      );

      uiEvents[startDay].add(newCalendarEvent);
    } else {
      //Mehrere Tage
      Duration difference = DateTime(endDay.year, endDay.month, endDay.day, 12).difference(startDay);

      int loopDays = difference.inDays + 1;

      for (int day = 0; day < loopDays; day++) {
        DateTime iteratedStartDay = DateTime(startDay.year, startDay.month, startDay.day + day, 0, 0, 0);

        if (iteratedStartDay.isBefore(DateTime(year, month, 1).subtract(Duration(days: 7))))
          continue;
        else if (iteratedStartDay.isAfter(DateTime(year, month + 1, 1).add(Duration(days: 7)))) continue;

        if (!uiEvents.containsKey(iteratedStartDay)) {
          uiEvents[iteratedStartDay] = new List<CalendarEvent>();
        }

        String startString = "";
        String endString = "";

        if (day == 0)
          startString = event.dayLong ? "Ganztägig" : ("Start: " + timeFormat.format(event.start)); //starttime String
        else if ((day + 1) == loopDays) startString = event.dayLong ? "" : ("Ende: " + timeFormat.format(event.end)); //endtime String

        CalendarEvent newCalendarEvent = new CalendarEvent(
            event.eventID, //ID
            startString, //starttime String
            endString, //endtime String
            event.title + " (Tag " + (day + 1).toString() + "/" + (loopDays).toString() + ")", //title
            event.color, //color
            event.calendarID //calendar ID
        );

        uiEvents[iteratedStartDay].add(newCalendarEvent);
      }
    }
  }

  bool isLoaded() {
    return _isCompletelyLoaded;
  }
}
