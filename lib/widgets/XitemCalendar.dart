
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:xitem/controllers/BirthdayController.dart';
import 'package:xitem/controllers/HolidayController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/controllers/UserController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/models/EventMonth.dart';
import 'package:xitem/models/SpecialEvent.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/AvatarImageProvider.dart';
import 'package:xitem/utils/CustomScrollBehavior.dart';
import 'package:xitem/utils/StateCodeConverter.dart';
import 'package:xitem/widgets/SlidableEventCard.dart';
import 'package:xitem/widgets/dialogs/EventDialog.dart';
import 'package:xitem/widgets/dialogs/UserDialog.dart';

class XitemCalendar extends StatefulWidget {
  const XitemCalendar(this._calendar, this._userController, this._holidayController, this._birthdayController, {super.key, required this.onDayLongTap, required this.onShareEvent, required this.onDeleteEvent, required this.onEditEvent});

  static const _preventiveCheckRange = 2;

  final Calendar _calendar;
  final UserController _userController;
  final HolidayController _holidayController;
  final BirthdayController _birthdayController;

  final void Function(UiEvent) onEditEvent;
  final void Function(UiEvent) onShareEvent;
  final void Function(UiEvent) onDeleteEvent;
  final void Function(DateTime) onDayLongTap;

  @override
  State<StatefulWidget> createState() => _XitemCalendarState();
}

class _XitemCalendarState extends State<XitemCalendar> {
  late final ValueNotifier<_CalendarEventLists> _selectedLists;

  late final ValueNotifier<_LoadingProgressState> _loadingProgressState = ValueNotifier(_LoadingProgressState.idel);

  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());
  DateTime? _selectedDay;

  late PageController _pageController;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  late final String _currentHolidayStateName;
  final Map<DateTime, List<PublicHoliday>> _holidays = <DateTime, List<PublicHoliday>>{};
  final List<Birthday> _birthdays = [];
  
  @override
  void initState() {
    super.initState();

    DateTime now = DateTime.now();

    _preventiveCheckUpcomingMonths(now);

    _selectedDay = _focusedDay.value;
    _selectedLists = ValueNotifier(_getEventsForDay(_focusedDay.value));

    _currentHolidayStateName = StateCodeConverter.getStateName(widget._holidayController.currentLoadedState());
    for(PublicHoliday holiday in widget._holidayController.holidays()) {
      DateTime dateOnly = DateTime(holiday.date.year, holiday.date.month, holiday.date.day);
      if(!_holidays.containsKey(dateOnly)) {
        _holidays[dateOnly] = [];
      }
      _holidays[dateOnly]!.add(holiday);
    }

    _birthdays.addAll(widget._birthdayController.birthdays());
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    _selectedLists.dispose();
    _loadingProgressState.dispose();
    super.dispose();
  }

  _CalendarEventLists _getEventsForDay(DateTime day) {
    DateTime dayOnly = DateTime(day.year, day.month, day.day);

    List<UiEvent> events = widget._calendar.eventController.getUiEventsForDay(dayOnly);
    List<PublicHoliday> holidays = _holidays[dayOnly] ?? [];

    List<Birthday> birthdays = [];
    for (var birthday in _birthdays) {
      if(day.month == birthday.birthday.month && day.day == birthday.birthday.day && birthday.getAgeInYear(day.year) >= 0) {
        birthdays.add(birthday);
      }
    }

    return _CalendarEventLists(events, holidays, birthdays);
  }

  void _preventiveCheckUpcomingMonths(DateTime currentMonth) async {
    for(int month = -XitemCalendar._preventiveCheckRange; month <= XitemCalendar._preventiveCheckRange; month++) {
      DateTime monthToCheck = DateTime(currentMonth.year, currentMonth.month + month);

      ResponseCode loadedAllMissingMonth = ResponseCode.success;

      if(!widget._calendar.eventController.isEventMonthLoaded(monthToCheck)) {
        _loadingProgressState.value = _LoadingProgressState.loading;
        ResponseCode loadMonth = await widget._calendar.eventController.loadEventsInMonth(monthToCheck);
        if(loadMonth != ResponseCode.success) {
          loadedAllMissingMonth = loadMonth;
          return;
        }
      }

      if(loadedAllMissingMonth != ResponseCode.success) {
        _loadingProgressState.value = _LoadingProgressState.failed;
      } else {
        _loadingProgressState.value = _LoadingProgressState.idel;
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay.value = focusedDay;
    });

    _selectedLists.value = _getEventsForDay(selectedDay);
  }

  void _onDayLongPressed(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay.value = focusedDay;
    });

    _selectedLists.value = _getEventsForDay(selectedDay);
  }

  void _onPageChanged(DateTime month) {
    _preventiveCheckUpcomingMonths(month);

    if(widget._calendar.eventController.isEventMonthLoaded(month)) {
      _focusedDay.value = month;
    }
  }

  bool _isHoliday(DateTime day) {
    if(_holidays.containsKey(DateTime(day.year,day.month,day.day))) {
      return true;
    }

    for (var birthday in _birthdays) {
      if(day.month == birthday.birthday.month && day.day == birthday.birthday.day && birthday.getAgeInYear(day.year) >= 0) {
        return true;
      }
    }

    return false;
  }
  
  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    return Column(
        children: [
          ValueListenableBuilder<DateTime>(
            valueListenable: _focusedDay,
            builder: (context, value, _) {
              return _CalendarHeader(
                focusedDay: value,
                onTodayButtonTap: () {
                  setState(() => _focusedDay.value = DateTime.now());
                },
                onLeftArrowTap: () {
                  DateTime monthToLoad = DateTime(_focusedDay.value.year, _focusedDay.value.month - 1);

                  if(widget._calendar.eventController.isEventMonthLoaded(monthToLoad)) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  }
                },
                onRightArrowTap: () {
                  DateTime monthToLoad = DateTime(_focusedDay.value.year, _focusedDay.value.month + 1);

                  if(widget._calendar.eventController.isEventMonthLoaded(monthToLoad)) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  }
                },
                loadingProgressState: _loadingProgressState,
              );
            },
          ),
          TableCalendar<UiEvent>(
            locale: 'de_DE',
            firstDay: DateTime.fromMicrosecondsSinceEpoch(0),
            lastDay: now.add(const Duration(days: 365 * 100)),
            focusedDay: _focusedDay.value,
            currentDay: DateTime.now(),
            headerVisible: false,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            pageJumpingEnabled: true,
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {CalendarFormat.month: "Monat", CalendarFormat.week: "Woche"},
            startingDayOfWeek: StartingDayOfWeek.monday,
            eventLoader: (day) => widget._calendar.eventController.getUiEventsForDay(day),
            holidayPredicate: _isHoliday,
            onDaySelected: _onDaySelected,
            onDayLongPressed: _onDayLongPressed,
            onCalendarCreated: (controller) => _pageController = controller,
            onPageChanged: _onPageChanged,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
              }
            },
            calendarStyle: const CalendarStyle(
              holidayDecoration: BoxDecoration(shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.amberAccent, shape: BoxShape.circle),
              weekendTextStyle: TextStyle(color: Colors.amber),
              markersMaxCount: 5,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: const TextStyle().copyWith(color: ThemeController.activeTheme().textColor),
              weekendStyle: const TextStyle().copyWith(color: ThemeController.activeTheme().textColor),
            ),
            calendarBuilders: CalendarBuilders(
              singleMarkerBuilder: (context, date, uiEvent) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 0.3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ThemeController.getEventColor(uiEvent.event.color),
                  ),
                );
              },
              outsideBuilder: (context, day, focusDay) {
                Color outsideColor = const Color(0xFFAEAEAE);
                if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
                  outsideColor = Colors.amberAccent;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(6.0),
                  padding: const EdgeInsets.all(0),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text("${day.day}", style: TextStyle(color: outsideColor)),
                );
              },
              holidayBuilder: (context, day, focusedDay) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(6.0),
                  padding: const EdgeInsets.all(0),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text("${day.day}", style: const TextStyle(color: Colors.red)),
                );
              }
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Divider(
            color: ThemeController.activeTheme().dividerColor,
            thickness: 2,
            height: 2,
          ),
          Expanded(
            child: ValueListenableBuilder<_CalendarEventLists>(
              valueListenable: _selectedLists,
              builder: (context, eventList, _) {
                if(eventList.selectedEvents.isEmpty && eventList.selectedHolidays.isEmpty && eventList.selectedBirthdays.isEmpty) {
                  return const Center(
                    child: Text("Keine Events. Zum Erstellen + tippen"),
                  );
                }

                return ScrollConfiguration(
                  behavior: const CustomScrollBehavior(false, true),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _buildEventTileList(eventList.selectedEvents)..addAll(_buildHolidayTileList(eventList.selectedHolidays))..addAll(_buildBirthdayTileList(eventList.selectedBirthdays)),
                  ),
                );
              },
            ),
          ),
        ],
    );
  }

  List<Widget> _buildEventTileList(List<UiEvent> uiEvents) {
    return uiEvents.map((uiEvent) {
      bool canEditThisEvent = widget._calendar.calendarMemberController.getAppUserEditPermission();
      User? creator = widget._userController.getLoadedUser(uiEvent.event.userID);

      if (!canEditThisEvent) {
        if (uiEvent.event.userID == widget._userController
            .getAuthenticatedUser()
            .id) {
          canEditThisEvent = true;
        }
      }

      bool onlyTitle = (uiEvent.firstLine == "" && uiEvent.secondLine == "");
      Widget tile;

      if (onlyTitle) {
        tile = ListTile(
          visualDensity: VisualDensity.compact,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(uiEvent.headline),
          onTap: () {
            EventDialog.showEventInformation(uiEvent.event, uiEvent.calendar, creator);
          },
        );
      } else {
        String subTitle = "";

        if (uiEvent.firstLine == "") {
          subTitle = uiEvent.secondLine;
        } else if (uiEvent.secondLine == "") {
          subTitle = uiEvent.firstLine;
        } else {
          subTitle = "${uiEvent.firstLine}\n${uiEvent.secondLine}";
        }

        tile = ListTile(
          visualDensity: VisualDensity.compact,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(uiEvent.headline),
          subtitle: Text(subTitle),
          isThreeLine: (uiEvent.firstLine == "" || uiEvent.secondLine == "") ? false : true,
          onTap: () {
            EventDialog.showEventInformation(uiEvent.event, uiEvent.calendar, creator);
          },
        );
      }

      return Container(
        alignment: Alignment.center,
        child: SlidableEventCard(
          color: ThemeController.getEventColor(uiEvent.event.color),
          editable: canEditThisEvent,
          content: tile,
          onEventShareTapped: () => widget.onShareEvent(uiEvent),
          onEventEditTapped: () => widget.onEditEvent(uiEvent),
          onEventDeleteTapped: () => widget.onDeleteEvent(uiEvent),
        ),
      );
    }).toList();
  }

  List<Widget> _buildHolidayTileList(List<PublicHoliday> holidays) {
    return holidays.map((holiday) {
      Widget tile = ListTile(
        visualDensity: VisualDensity.compact,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(holiday.name),
        subtitle: Text("Feiertag in $_currentHolidayStateName"),
      );

      return Container(
        alignment: Alignment.center,
        child: Card(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 3,
          color: ThemeController.activeTheme().cardColor,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.red,
                  width: 3,
                ),
              ),
            ),
            child: tile,
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildBirthdayTileList(List<Birthday> birthdays) {
    return birthdays.map((birthday) {
      String title = birthday.name;
      if(title.endsWith('s')) {
        title += "` Geburtstag";
      } else {
        title += "`s Geburtstag";
      }

      Widget leading;
      if(birthday.avatar == null) {
        leading = Icon(
          Icons.cake,
          color: ThemeController.activeTheme().iconColor,
          size: 32,
        );
      } else {
        leading = CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          backgroundImage: AvatarImageProvider.get(birthday.avatar),
          child: GestureDetector(
            onTap: () async {
              UserDialog.profilePictureDialog(birthday.avatar);
            },
          ),
        );
      }
      
      Widget tile = ListTile(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        leading: leading,
        title: Text(title),
        trailing: Text(
          birthday.getAgeInYear(_selectedDay?.year ?? DateTime.now().year).toString(),
          style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

      return Container(
        alignment: Alignment.center,
        child: Card(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 3,
          color: ThemeController.activeTheme().cardColor,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.amber,
                  width: 3,
                ),
              ),
            ),
            child: tile,
          ),
        ),
      );
    }).toList();
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final VoidCallback onTodayButtonTap;
  final ValueNotifier<_LoadingProgressState> loadingProgressState;

  const _CalendarHeader({
    Key? key,
    required this.focusedDay,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onTodayButtonTap,
    required this.loadingProgressState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final headerText = DateFormat.yMMMM("de_DE").format(focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onLeftArrowTap,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today, size: 17.0),
                visualDensity: VisualDensity.compact,
                onPressed: onTodayButtonTap,
              ),
              Text(
                headerText,
                style: const TextStyle(fontSize: 17.0),
              ),
              ValueListenableBuilder(
                  valueListenable: loadingProgressState,
                  builder: (context, loadingProgressState, _) {

                    if(loadingProgressState == _LoadingProgressState.failed) {
                      return Row(
                          children: const [
                            SizedBox(width: 10),
                            Icon(
                              Icons.error_outline,
                              size: 17,
                              color: Colors.red,
                            ),
                          ]
                      );
                    }

                    return const SizedBox.shrink();
                  }
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onRightArrowTap,
          ),
        ],
      ),
    );
  }
}

class _CalendarEventLists {
  final List<UiEvent> selectedEvents;
  final List<PublicHoliday> selectedHolidays;
  final List<Birthday> selectedBirthdays;

  _CalendarEventLists(this.selectedEvents, this.selectedHolidays, this.selectedBirthdays);
}

enum _LoadingProgressState {
  idel,
  loading,
  failed
}
