import 'package:xitem/controllers/EventController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/utils/UiEventBuilder.dart';

class EventMonth {
  EventMonth(this._year, this._month, this._calendar) {
    _invalidAfter = DateTime(_year, _month + 1, 1).add(EventController.monthlyOverhangRange);
    _invalidBefore = DateTime(_year, _month, 1).subtract(EventController.monthlyOverhangRange);
  }

  final int _year;
  final int _month;

  late final DateTime _invalidBefore;
  late final DateTime _invalidAfter;

  final Calendar _calendar;

  final Map<DateTime, List<UiEvent>> _uiEvents = <DateTime, List<UiEvent>>{};

  void addOrReplaceEvent(Event event) {
    removeUiEventById(event.eventID);
    Map<DateTime, List<UiEvent>> newEvents = UiEventBuilder.convertEvent(event, _calendar, _invalidAfter, _invalidBefore);

    newEvents.forEach((day, newEventList) { 
      if(!_uiEvents.containsKey(day)) {
        _uiEvents[day] = [];
      }
      _uiEvents[day]!.addAll(newEventList);
    });
  }

  void removeUiEventById(BigInt eventToDelete) {
    _uiEvents.forEach((day, eventList) {
      eventList.removeWhere((element) => element.event.eventID == eventToDelete);
    });
  }

  List<UiEvent> getUiEventsByDay(DateTime day) {
    DateTime dateOnly = DateTime(day.year, day.month, day.day);
    return _uiEvents[dateOnly] ?? [];
  }

  @override
  String toString() {
    String object = "Year: $_year, Month: $_month, Calendar ID: ${_calendar.id}\n";
    object += "Range: $_invalidBefore - $_invalidAfter\n";
    object += "Event count: ${_uiEvents.length}";
    return object;
  }
}