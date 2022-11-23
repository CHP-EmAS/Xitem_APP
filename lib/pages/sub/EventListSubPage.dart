import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/EventListController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Models/Event.dart';
import 'package:de/Models/Voting.dart';
import 'package:de/Utils/custom_scroll_behavior.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/Dialogs/event_popups.dart';
import 'package:de/Widgets/Dialogs/voting_popups.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// ignore: must_be_immutable
class EventListSubPage extends StatefulWidget {
  EventListSubPageState cels;

  addEvent(EventData event) {
    cels.addEvent(event);
  }

  refreshState() {
    if(cels.mounted)
      cels.refreshState();
  }

  @override
  State<StatefulWidget> createState() {
    cels = EventListSubPageState();
    return cels;
  }
}

class EventListSubPageState extends State<EventListSubPage> {

  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();

  @override
  void initState() {
    EventListController.generateEventList();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void refreshState() {
    setState(() {
      EventListController.generateEventList();
    });
  }

  void _onRefresh() async {
    bool reloadCompleted = await UserController.loadAllCalendars();

    if (reloadCompleted) {
      if(super.mounted) {
        setState(() {
          EventListController.generateEventList();
        });
      }
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }
  }

  void addEvent(EventData newEvent) async {
    Calendar selectedCalendar = UserController.calendarList[newEvent.selectedCalendar];

    if (selectedCalendar == null) {
      DialogPopup.asyncOkDialog("Event konnten nicht erstellt werden!", "Der Ausgewählte Kalender konnte nicht gefunden werden!");
      return;
    }

    DialogPopup.asyncLoadingDialog(_keyLoader, "Erstelle Event...");

    bool success = await selectedCalendar.createEvent(newEvent).catchError((e) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      return false;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!success) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      DialogPopup.asyncOkDialog("Event konnten nicht erstellt werden!", Api.errorMessage);
    } else {
      setState(() {
        EventListController.generateEventList();
      });
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
    }
  }

  void _editEvent(CalendarEvent eventToEdit) async {
    EventData editedEvent = await EventPopup.showEventSettingDialog(eventToEdit.calendarID, eventID: eventToEdit.eventID);

    if (editedEvent != null) {
      if (!UserController.calendarList.containsKey(editedEvent.selectedCalendar)) return;

      Calendar _calendar = UserController.calendarList[editedEvent.selectedCalendar];

      DialogPopup.asyncLoadingDialog(_keyLoader, "Speichere Änderungen...");

      bool success = await _calendar
          .editEvent(eventToEdit.eventID, editedEvent.startDate, editedEvent.endDate, editedEvent.title, editedEvent.description, editedEvent.daylong, editedEvent.color)
          .catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return false;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!success) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        DialogPopup.asyncOkDialog("Änderungen konnten nicht gespeichert werden!", Api.errorMessage);
      } else {
        setState(() {
          EventListController.generateEventList();
        });
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      }
    }
  }

  void _deleteEvent(CalendarEvent eventToDelete) async {
    if (!UserController.calendarList.containsKey(eventToDelete.calendarID)) return;

    Calendar _calendar = UserController.calendarList[eventToDelete.calendarID];

    if (await DialogPopup.asyncConfirmDialog("Event löschen?", "Willst du das Event wirklich löschen? Das Event wird endgültig gelöscht und kann nicht wiederhergestellt werden!") ==
        ConfirmAction.OK) {
      DialogPopup.asyncLoadingDialog(_keyLoader, "Lösche Event...");

      bool success = await _calendar.removeEvent(eventToDelete.eventID).catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return false;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!success) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        DialogPopup.asyncOkDialog("Event konnte nicht gelöscht werden!", Api.errorMessage);
      } else {
        setState(() {
          EventListController.generateEventList();
        });
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      }
    }
  }

  void voteForVoting(Voting voting) async {
    List<int> votes = await VotingPopup.showVotingInformationPopup(voting);

    if (votes != null) {
      if (votes.length > 0) {
        //Get Calendar given in the requested Voting
        Calendar _calendar = UserController.calendarList[voting.calendarID];

        DialogPopup.asyncLoadingDialog(_keyLoader, "Übermittle Abstimmung...");

        bool success = await _calendar.vote(voting.votingID, votes).catchError((e) {
          Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
          return false;
        });

        await Future.delayed(const Duration(seconds: 1));

        if (!success) {
          Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
          DialogPopup.asyncOkDialog("Abstimmung konnten nicht übermittelt werden!", Api.errorMessage);
        } else {
          setState(() {
            EventListController.generateEventList();
          });
          Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        }
      }
    }
  }

  void _deleteVoting(Voting votingToDelete) async {
    if (!UserController.calendarList.containsKey(votingToDelete.calendarID)) return;

    Calendar _calendar = UserController.calendarList[votingToDelete.calendarID];

    if (await DialogPopup.asyncConfirmDialog("Abstimmung löschen?", "Willst du die Abstimmung wirklich löschen? Die Abstimmung wird endgültig gelöscht und kann nicht wiederhergestellt werden!") ==
        ConfirmAction.OK) {
      DialogPopup.asyncLoadingDialog(_keyLoader, "Lösche Abstimmung...");

      bool success = await _calendar.removeVoting(votingToDelete.votingID).catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return false;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!success) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        DialogPopup.asyncOkDialog("Abstimmung konnten nicht gelöscht werden!", Api.errorMessage);
      } else {
        setState(() {
          EventListController.generateEventList();
        });
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      }
    }
  }

  Widget _buildEvent(CalendarEvent event) {
    //Proof if Calendar exists, if not return free space
    if (!UserController.calendarList.containsKey(event.calendarID)) return Center();

    //Get Calendar given in the requested Event
    Calendar _calendar = UserController.calendarList[event.calendarID];

    //Check if user have overall edit permissions
    bool _canEditThisEvent = _calendar.canEditEvents;

    //If User have no overall edit permissions, check if user is creator of event and enable editing again
    if (!_canEditThisEvent) {
      if (_calendar.dynamicEventMap.containsKey(event.eventID)) {
        if (UserController.user.userID == _calendar.dynamicEventMap[event.eventID].userID) {
          _canEditThisEvent = true;
        }
      }
    }

    Widget tile;
    String subTitle = "";

    if (event.startTime == "")
      subTitle = event.endTime;
    else if (event.endTime == "")
      subTitle = event.startTime;
    else
      subTitle = event.startTime + "\n" + event.endTime;

    tile = ListTile(
      focusColor: Colors.red,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      trailing: IconButton(
          color: Colors.transparent,
          splashColor: Colors.transparent,
          icon: Icon(
            _calendar.icon,
            size: 35,
            color: _calendar.color,
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/calendar', arguments: _calendar.id).then((value) => {
                  setState(() {
                    EventListController.generateEventList();
                  })
                });
          }),
      title: Text(event.title),
      subtitle: Text(subTitle),
      isThreeLine: (event.startTime == "" || event.endTime == "") ? false : true,
      onTap: () {
        EventPopup.showEventInformation(_calendar.id, event.eventID);
      },
    );

    return Slidable(
      enabled: true,
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.20,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 3,
        color: ThemeController.activeTheme().cardColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: event.color,
                width: 3,
              ),
            ),
          ),
          child: tile,
        ),
      ),
      actions: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: IconSlideAction(
            caption: 'Teilen',
            color: Colors.indigo,
            icon: Icons.share,
            onTap: () => null,
          ),
        ),
      ],
      secondaryActions: _canEditThisEvent
          ? <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: IconSlideAction(
                  caption: 'Bearbeiten',
                  color: Colors.grey,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  onTap: () => _editEvent(event),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: IconSlideAction(
                  caption: 'Löschen',
                  color: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  onTap: () => _deleteEvent(event),
                ),
              ),
            ]
          : [],
    );
  }

  Widget _buildVoting(Voting voting) {
    //Proof if Calendar exists, if not return free space
    if (!UserController.calendarList.containsKey(voting.calendarID)) return Center();

    //Get Calendar given in the requested Voting
    Calendar _calendar = UserController.calendarList[voting.calendarID];

    Widget tile;

    tile = ListTile(
      focusColor: Colors.red,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      trailing: IconButton(
          color: Colors.transparent,
          splashColor: Colors.transparent,
          icon: Icon(
            _calendar.icon,
            size: 35,
            color: _calendar.color,
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/calendar', arguments: _calendar.id).then((value) => {
                  setState(() {
                    EventListController.generateEventList();
                  })
                });
          }),
      title: Text(voting.title),
      subtitle: Text(voting.numberUsersWhoHaveVoted.toString() + "/" + _calendar.assocUserList.length.toString() + " Mitglieder haben bereits abgestimmt"),
      onTap: () async {
        voteForVoting(voting);
      },
    );

    return Slidable(
      enabled: true,
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.20,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 3,
        color: ThemeController.activeTheme().cardColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white,
                width: 3,
              ),
            ),
          ),
          child: tile,
        ),
      ),
      actions: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: IconSlideAction(
            caption: 'Teilen',
            color: Colors.indigo,
            icon: Icons.share,
            onTap: () => null,
          ),
        ),
      ],
      secondaryActions: (voting.ownerID == UserController.user.userID)
          ? <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: IconSlideAction(
                  caption: 'Löschen',
                  color: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  onTap: () => _deleteVoting(voting),
                ),
              ),
            ]
          : [],
    );
  }

  Widget _buildItemsForListView(BuildContext context, int index) {
    EventListEntry currentEntry = EventListController.eventEntryList[index];

    if (currentEntry.entryType == EntryType.HEADLINE) {
      return Padding(
        padding: EdgeInsets.fromLTRB(5, 13, 5, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentEntry.headlineText, style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontSize: 20, fontWeight: FontWeight.w500)),
            Divider(
              color: ThemeController.activeTheme().headlineColor,
              height: 5,
              thickness: 2,
            )
          ],
        ),
      );
    } else if (currentEntry.entryType == EntryType.EVENT) {
      return _buildEvent(currentEntry.event);
    } else if (currentEntry.entryType == EntryType.VOTING) {
      return _buildVoting(currentEntry.voting);
    }

    return Center();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: CustomScrollBehavior(false, true),
      child: SmartRefresher(
        header: WaterDropMaterialHeader(
          color: ThemeController.activeTheme().actionButtonColor,
          backgroundColor: ThemeController.activeTheme().foregroundColor,
        ),
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: EventListController.eventEntryList.isNotEmpty
            ? ListView.builder(
                itemCount: EventListController.eventEntryList.length,
                itemBuilder: _buildItemsForListView,
              )
            : Center(
                child: Container(
                  margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Text(
                    UserController.calendarList.isEmpty
                        ? "Herzlich Willkommen bei Xitem! ♥\n\n Drücke '+' unten Links um deinen ersten Kalender zu erstellen oder einem bestehenden Kalender beizutreten."
                        : "Keine anstehenden Termine in den nächsten Monaten.\nDrücke '+' unten Links um ein neuen Termin zu erstellen.",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
      ),
    );
  }
}
