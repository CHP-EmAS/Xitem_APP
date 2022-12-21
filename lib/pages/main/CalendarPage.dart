import 'package:xitem/controllers/BirthdayController.dart';
import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/HolidayController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/controllers/UserController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/widgets/XitemCalendar.dart';
import 'package:xitem/widgets/dialogs/CalendarDialog.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';
import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage(this._linkedCalendarID,  this._calendarController, this._userController, this._holidayController, this._birthdayController, {super.key});

  final String _linkedCalendarID;
  final CalendarController _calendarController;
  final UserController _userController;
  final HolidayController _holidayController;
  final BirthdayController _birthdayController;

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

  late List<_CalendarMenuChoice> _calendarMenuChoices;

  Calendar? _linkedCalendar;

  @override
  void initState() {
    super.initState();

    Calendar? loadedCalendar = widget._calendarController.getCalendar(widget._linkedCalendarID);

    if(loadedCalendar != null) {
      _linkedCalendar = loadedCalendar;
      _calendarMenuChoices = loadedCalendar.calendarMemberController.getAppUserOwnerPermission() ? _calendarMenuChoicesAdmin : _calendarMenuChoicesMember;
    }
  }


  Future<void> _selectMenuChoice(_CalendarMenuChoice choice) async {
    Calendar? currentCalendar = _linkedCalendar;

    if(currentCalendar == null) {
      return;
    }

    if (choice.menuStatus == _CalendarMenuStatus.settings) {
      StateController.navigatorKey.currentState?.pushNamed('/calendar/settings', arguments: widget._linkedCalendarID).then((_) {
        Calendar? reloadedCalendar = widget._calendarController.getCalendar(widget._linkedCalendarID);

        if(reloadedCalendar == null) {
          Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
          return;
        }
        debugPrint("reload calendar");

        setState(() {
          _linkedCalendar = reloadedCalendar;
        });
      });
    } else if (choice.menuStatus == _CalendarMenuStatus.notes) {
      StateController.navigatorKey.currentState?.pushNamed('/calendar/notes', arguments: widget._linkedCalendarID);
    } else if (choice.menuStatus == _CalendarMenuStatus.qrInvitation) {
      await createQRCode();
    }
  }

  Future<bool> createQRCode() async {
    InvitationRequest? invitationData = await CalendarDialog.createQRCodePopup(widget._linkedCalendarID);
    if (invitationData == null) return false;

    ApiResponse<String> getInvitationToken = await  widget._calendarController.getInvitationToken(widget._linkedCalendarID,invitationData.canCreateEvents, invitationData.canEditEvents, invitationData.duration);
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

  // void _addEvent(EventData newEvent) async {
  //   Calendar selectedCalendar = UserController.calendarList[newEvent.selectedCalendar];
  //
  //   if (selectedCalendar == null) {
  //     DialogPopup.okDialog("Event konnten nicht erstellt werden!", "Der Ausgewählte Kalender konnte nicht gefunden werden!");
  //     return;
  //   }
  //
  //   DialogPopup.asyncLoadingDialog(_keyLoader, "Erstelle Event...");
  //
  //   bool success = await selectedCalendar.createEvent(newEvent).catchError((e) {
  //     Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  //     return false;
  //   });
  //
  //   await Future.delayed(const Duration(seconds: 1));
  //
  //   if (!success) {
  //     Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  //     DialogPopup.okDialog("Event konnten nicht erstellt werden!", ApiGateway.errorMessage);
  //   } else {
  //     if (selectedCalendar.id == widget.linkedCalendar.id) {
  //       await _rebuildOnSpecificDate(newEvent.startDate);
  //     }
  //
  //     Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  //   }
  // }
  //
  // void _editEvent(BigInt eventID) async {
  //   EventData editedEvent = await EventPopup.showEventSettingDialog(widget.linkedCalendar.id, eventID: eventID);
  //
  //   if (editedEvent != null) {
  //     DialogPopup.asyncLoadingDialog(_keyLoader, "Speichere Änderungen...");
  //
  //     bool success = await widget.linkedCalendar.editEvent(eventID, editedEvent.startDate, editedEvent.endDate, editedEvent.title, editedEvent.description, editedEvent.daylong, editedEvent.color).catchError((e) {
  //       Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  //       return false;
  //     });
  //
  //     await Future.delayed(const Duration(seconds: 1));
  //
  //     if (!success) {
  //       Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  //       DialogPopup.okDialog("Änderungen konnten nicht gespeichert werden!", ApiGateway.errorMessage);
  //     } else {
  //       await _rebuildOnSpecificDate(editedEvent.startDate);
  //       Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  //     }
  //   }
  // }
  //
  // void _deleteEvent(BigInt eventID) async {
  //   if (await DialogPopup.confirmDialog("Event löschen?", "Willst du das Event wirklich löschen? Das Event wird endgültig gelöscht und kann nicht wiederhergestellt werden!") ==
  //       ConfirmAction.OK) {
  //     DialogPopup.asyncLoadingDialog(_keyLoader, "Lösche Event...");
  //
  //     bool success = await widget.linkedCalendar.removeEvent(eventID).catchError((e) {
  //       Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  //       return false;
  //     });
  //
  //     await Future.delayed(const Duration(seconds: 1));
  //
  //     if (!success) {
  //       Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  //       DialogPopup.okDialog("Event konnten nicht gelöscht werden!", ApiGateway.errorMessage);
  //     } else {
  //       await _rebuildOnSpecificDate(_calendarController.selectedDay);
  //       Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    Calendar? displayedCalendar = _linkedCalendar;

    if(displayedCalendar == null) {
      return const Scaffold();
    }

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
              displayedCalendar.icon,
              color: ThemeController.getEventColor(displayedCalendar.color),
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
      body: XitemCalendar(
        displayedCalendar,
        widget._userController,
        widget._holidayController,
        widget._birthdayController,
        onDayLongTap: (day) {  },
        onShareEvent: (uiEvent) {  },
        onDeleteEvent: (uiEvent) {  },
        onEditEvent: (uiEvent) {  },
      ),
      floatingActionButton: (displayedCalendar.calendarMemberController.getAppUserCreatePermission())
          ? FloatingActionButton(
              onPressed: () async {
                //EventData newEvent = await EventDialog.showEventSettingDialog(widget.linkedCalendar.id, initTime: _calendarController.selectedDay, calendarChangeable: true);
                //if (newEvent != null) {
                //  _addEvent(newEvent);
                //}
              },
              backgroundColor: ThemeController.activeTheme().actionButtonColor,
              tooltip: "Event erstellen",
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
