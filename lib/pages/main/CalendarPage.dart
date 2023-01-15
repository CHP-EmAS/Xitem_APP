import 'package:xitem/controllers/BirthdayController.dart';
import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/EventController.dart';
import 'package:xitem/controllers/HolidayController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/controllers/UserController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/pages/main/EventPage.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/widgets/XitemCalendar.dart';
import 'package:xitem/widgets/dialogs/CalendarDialog.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';
import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.linkedCalendarID, required this.calendarController, required this.userController, required this.holidayController, required this.birthdayController});

  final String linkedCalendarID;
  final CalendarController calendarController;
  final UserController userController;
  final HolidayController holidayController;
  final BirthdayController birthdayController;

  @override
  State<StatefulWidget> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with TickerProviderStateMixin {
  static const List<_CalendarMenuChoice> _calendarMenuChoicesMember = <_CalendarMenuChoice>[
    _CalendarMenuChoice(menuStatus: _CalendarMenuStatus.notes, title: 'Notizen', icon: Icons.sticky_note_2_outlined),
    _CalendarMenuChoice(menuStatus: _CalendarMenuStatus.settings, title: 'Anpassen', icon: Icons.edit_calendar),
  ];

  static const List<_CalendarMenuChoice> _calendarMenuChoicesAdmin = <_CalendarMenuChoice>[
    _CalendarMenuChoice(menuStatus: _CalendarMenuStatus.notes, title: 'Notizen', icon: Icons.sticky_note_2_outlined),
    _CalendarMenuChoice(menuStatus: _CalendarMenuStatus.qrInvitation, title: 'QR Einladung', icon: Icons.qr_code),
    _CalendarMenuChoice(menuStatus: _CalendarMenuStatus.settings, title: 'Anpassen', icon: Icons.edit_calendar),
  ];

  late final List<_CalendarMenuChoice> _calendarMenuChoices;

  Calendar? _linkedCalendar;
  XitemCalendarController xitemCalendarController = XitemCalendarController();

  @override
  void initState() {
    super.initState();

    Calendar? loadedCalendar = widget.calendarController.getCalendar(widget.linkedCalendarID);

    if(loadedCalendar != null) {
      _linkedCalendar = loadedCalendar;
      _calendarMenuChoices = loadedCalendar.calendarMemberController.getAppUserOwnerPermission() ? _calendarMenuChoicesAdmin : _calendarMenuChoicesMember;
    }
  }


  Future<void> _selectMenuChoice(_CalendarMenuChoice choice) async {
    if (choice.menuStatus == _CalendarMenuStatus.settings) {
      StateController.navigatorKey.currentState?.pushNamed('/calendar/settings', arguments: widget.linkedCalendarID).then((_) {
        Calendar? reloadedCalendar = widget.calendarController.getCalendar(widget.linkedCalendarID);

        if(reloadedCalendar == null) {
          Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
          return;
        }

        setState(() {
          _linkedCalendar = reloadedCalendar;
        });
      });
    } else if (choice.menuStatus == _CalendarMenuStatus.notes) {
      StateController.navigatorKey.currentState?.pushNamed('/calendar/notes', arguments: widget.linkedCalendarID);
    } else if (choice.menuStatus == _CalendarMenuStatus.qrInvitation) {
      await createQRCode();
    }
  }

  Future<bool> createQRCode() async {
    InvitationRequest? invitationData = await CalendarDialog.createQRCodePopup(widget.linkedCalendarID);
    if (invitationData == null) return false;

    ApiResponse<String> getInvitationToken = await  widget.calendarController.getInvitationToken(widget.linkedCalendarID,invitationData.canCreateEvents, invitationData.canEditEvents, invitationData.duration);
    String? strInvitationToken = getInvitationToken.value;
    if (getInvitationToken.code != ResponseCode.success || strInvitationToken == null) {
      String errorMessage;

      switch(getInvitationToken.code) {
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du musst Kalenderadministrator sein um eine QR-Code Einladung erstellen zu können.";
          break;
        case ResponseCode.accessForbidden:
          errorMessage = "Du musst Mitglied in diesem Kalender sein um eine QR-Code Einladung erstellen zu können.";
          break;
        case ResponseCode.missingArgument:
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case ResponseCode.invalidNumber:
          errorMessage = "Die Gültigkeitsdauer muss zwischen 5min und 7Tagen liegen.";
          break;
        default:
          errorMessage = "Beim Erstellen der QR Einladung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      }

      await StandardDialog.okDialog("QR-Code konnte nicht erstellt werden!", errorMessage);
      return false;
    }

    String calendarName = _linkedCalendar?.name ?? "";
    String invitationToken =  '{"n":"$calendarName","k":"$strInvitationToken"}';

    await CalendarDialog.showQrCodePopup(invitationToken);
    return true;
  }

  Future<void> _onCreateEvent(DateTime initialDay) async {
    Calendar? currentCalendar = _linkedCalendar;

    if(currentCalendar == null) {
      return;
    }

    await StateController.navigatorKey.currentState?.pushNamed(
        "/event",
        arguments: EventPageArguments(initialCalendar: currentCalendar, calendarList: [], calendarChangeable: false, initialStartDate: initialDay)
    );
  }

  Future<void> _onEditEvent(UiEvent eventToEdit) async {
    Calendar? currentCalendar = _linkedCalendar;
    if(currentCalendar == null) {
      return;
    }

    await StateController.navigatorKey.currentState?.pushNamed(
        "/event",
        arguments: EventPageArguments(initialCalendar: currentCalendar, calendarList: [], calendarChangeable: false, eventToEdit: eventToEdit.event)
    );
  }

  Future<void> _onDeleteEvent(UiEvent eventToDelete) async {
    EventController? eventController = widget.calendarController.getCalendar(eventToDelete.calendar.id)?.eventController;
    if (eventController == null) {
      return;
    }

    ConfirmAction? confirm = await StandardDialog.confirmDialog("Event löschen?", "Willst du das Event wirklich löschen? Das Event wird endgültig gelöscht und kann nicht wiederhergestellt werden!");
    if (confirm != ConfirmAction.ok) {
      return;
    }

    StandardDialog.loadingDialog("Lösche Event...");

    ResponseCode deleteEvent = await eventController.removeEvent(eventToDelete.event.eventID).catchError((e) {
      StateController.navigatorKey.currentState?.pop();
      return ResponseCode.unknown;
    });

    if (deleteEvent != ResponseCode.success) {
      String errorMessage;

      switch (deleteEvent) {
        case ResponseCode.accessForbidden:
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu löschen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Löschen des Events ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      }

      StateController.navigatorKey.currentState?.pop();
      StandardDialog.okDialog("Event konnte nicht gelöscht werden!", errorMessage);
      return;
    }

    StateController.navigatorKey.currentState?.pop();
  }

  @override
  Widget build(BuildContext context) {
    Calendar? displayedCalendar = _linkedCalendar;

    if(displayedCalendar == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            color: ThemeController.activeTheme().iconColor,
            onPressed: () {
              StateController.navigatorKey.currentState?.pop(context);
            },
          ),
        )
      );
    }

    Widget xitemCalendar = XitemCalendar(
      calendar: displayedCalendar,
      userController: widget.userController,
      holidayController: widget.holidayController,
      birthdayController: widget.birthdayController,
      xitemCalendarController: xitemCalendarController,
      initialDate: DateTime.now(),
      onDayLongTap: _onCreateEvent,
      onShareEvent: (uiEvent) async { },
      onDeleteEvent: _onDeleteEvent,
      onEditEvent: _onEditEvent,
    );

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: ThemeController.activeTheme().iconColor, size: 25.0),
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            StateController.navigatorKey.currentState?.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              ThemeController.getCalendarIcon(displayedCalendar.iconIndex),
              color: ThemeController.getEventColor(displayedCalendar.colorIndex),
              size: 32,
            ),
            const SizedBox(
              width: 15,
            ),
            Text(
              displayedCalendar.name,
              style: TextStyle(color: ThemeController.activeTheme().textColor),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        elevation: 3,
        actions: <Widget>[
          PopupMenuButton<_CalendarMenuChoice>(
            onSelected: _selectMenuChoice,
            color: ThemeController.activeTheme().menuPopupBackgroundColor,
            itemBuilder: (BuildContext context) {
              return _calendarMenuChoices.map((choice) {
                return PopupMenuItem<_CalendarMenuChoice>(
                  value: choice,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Icon(
                        choice.icon,
                        color: ThemeController.activeTheme().menuPopupIconColor,
                        size: 25,
                      ),
                      Text(
                        choice.title,
                        style: TextStyle(color: ThemeController.activeTheme().menuPopupTextColor),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: xitemCalendar,
      floatingActionButton: (displayedCalendar.calendarMemberController.getAppUserCreatePermission())
          ? FloatingActionButton(
              onPressed: () => _onCreateEvent(xitemCalendarController.selectedDay()).then((value) => setState(() {
                xitemCalendarController.rebuildSelectedEventsListOnDay(xitemCalendarController.selectedDay());
              })),
              backgroundColor: ThemeController.activeTheme().actionButtonColor,
              tooltip: "Termin erstellen",
              child: Icon(
                Icons.add,
                color: ThemeController.activeTheme().textColor,
                size: 30,
              ),
            )
          : const Center(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

enum _CalendarMenuStatus { settings, notes, qrInvitation }

class _CalendarMenuChoice {
  const _CalendarMenuChoice({required this.menuStatus, required this.title, required this.icon});

  final _CalendarMenuStatus menuStatus;
  final String title;
  final IconData icon;
}
