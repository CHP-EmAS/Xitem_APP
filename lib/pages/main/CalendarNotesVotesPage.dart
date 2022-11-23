import 'package:de/controllers/ApiController.dart';
import 'package:de/controllers/ThemeController.dart';
import 'package:de/controllers/UserController.dart';
import 'package:de/models/Calendar.dart';
import 'package:de/models/Note.dart';
import 'package:de/models/Voting.dart';
import 'package:de/utils/custom_scroll_behavior.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/Dialogs/note_popups.dart';
import 'package:de/Widgets/Dialogs/voting_popups.dart';
import 'package:de/Widgets/note_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CalendarNotesVotesPage extends StatefulWidget {
  const CalendarNotesVotesPage({Key key, @required this.linkedCalendar});

  final Calendar linkedCalendar;

  @override
  State<StatefulWidget> createState() => _CalendarNotesVotesPageState();

}

class _CalendarNotesVotesPageState extends State<CalendarNotesVotesPage> with SingleTickerProviderStateMixin {
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  List<Voting> _polls = [];
  List<Note> _pinnedNotes = [];
  List<Note> _unpinnedNotes = [];

  TabController _tabController;
  final List<Container> myTabs = <Container>[
    Container(height: 54, child: Tab(child: Text("Notizen", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16)))),
    Container(height: 54, child: Tab(child: Text("Abstimmungen", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16)))),
  ];

  @override
  void initState() {
    _polls = widget.linkedCalendar.votingMap.values.toList(growable: false);
    loadNotes();

    _tabController = TabController(vsync: this, length: myTabs.length, initialIndex: 0);
    _tabController.addListener(_handleTabIndex);

    super.initState();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabIndex() {
    setState(() {});
  }

  void loadNotes() {
    _pinnedNotes.clear();
    _unpinnedNotes.clear();

    widget.linkedCalendar.noteMap.forEach((noteID, note) {
      if (note.pinned)
        _pinnedNotes.add(note);
      else
        _unpinnedNotes.add(note);
    });
  }

  void _onRefresh() async {
    bool reloadCompleted = await widget.linkedCalendar.reload();

    if (reloadCompleted) {
      setState(() {
        loadNotes();
        _polls = widget.linkedCalendar.votingMap.values.toList(growable: false);
      });
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }
  }

  void _showVoting(Voting voting) async {
    List<int> votes = await VotingPopup.showVotingInformationPopup(voting);

    if (votes != null) {
      if (votes.length > 0) {
        DialogPopup.asyncLoadingDialog(_keyLoader, "Übermittle Abstimmung...");

        bool success = await widget.linkedCalendar.vote(voting.votingID, votes).catchError((e) {
          Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
          return false;
        });

        await Future.delayed(const Duration(seconds: 1));

        if (!success) {
          Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
          DialogPopup.asyncOkDialog("Abstimmung konnten nicht übermittelt werden!", Api.errorMessage);
        } else {
          setState(() {
            widget.linkedCalendar.reload();
            _polls = widget.linkedCalendar.votingMap.values.toList(growable: false);
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
          _polls = _calendar.votingMap.values.toList(growable: false);
        });
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      }
    }
  }

  void _createVoting() async {
    NewVotingRequest votingData = await VotingPopup.createVotingPopup();
    if (votingData == null) return;

    DialogPopup.asyncLoadingDialog(_keyLoader, "Starte Abstimmung...");

    bool success = await widget.linkedCalendar.createVoting(votingData.title, votingData.multipleChoice, votingData.abstentionAllowed, votingData.choices).catchError((e) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      return false;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!success) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      await DialogPopup.asyncOkDialog("Abstimmung konnte nicht gestartet werden!", Api.errorMessage);
      return;
    }

    setState(() {
      _polls = widget.linkedCalendar.votingMap.values.toList(growable: false);
    });

    Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  }

  void _createNote() async {
    NoteData noteData = await NotePopup.notePopup(widget.linkedCalendar.id, null, true);
    if (noteData == null) return;

    DialogPopup.asyncLoadingDialog(_keyLoader, "Erstelle Notiz...");

    bool success = await widget.linkedCalendar.createNote(noteData.title, noteData.content, noteData.pinned, noteData.color).catchError((e) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      return false;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!success) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      await DialogPopup.asyncOkDialog("Notiz konnte nicht erstellt werden!", Api.errorMessage);
      return;
    }

    setState(() {
      loadNotes();
    });

    Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = _pinnedNotes.isNotEmpty || _unpinnedNotes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        elevation: 3,
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: TabBarView(controller: _tabController, children: [
        //Notizen
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 720),
            child: ScrollConfiguration(
              behavior: CustomScrollBehavior(false, true),
              child: SmartRefresher(
                header: WaterDropMaterialHeader(
                  color: ThemeController.activeTheme().actionButtonColor,
                  backgroundColor: ThemeController.activeTheme().foregroundColor,
                ),
                controller: _refreshController,
                onRefresh: _onRefresh,
                child: hasNotes
                    ? CustomScrollView(
                        slivers: <Widget>[
                          SliverToBoxAdapter(
                            child: SizedBox(height: 24),
                          ),
                          ..._buildItemsForNotesView(
                            context,
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: 10.0),
                          ),
                        ],
                      )
                    : Center(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child: Text(
                            widget.linkedCalendar.canCreateEvents
                                ? "Keine gespeicherten Notizen in diesem Kalender, tippe auf das Notizsymbol um eine neue Notiz zu erstellen."
                                : "Keine gespeicherten Notizen in diesem Kalender.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        //Abstimmungen
        ScrollConfiguration(
          behavior: CustomScrollBehavior(false, true),
          child: SmartRefresher(
            header: WaterDropMaterialHeader(
              color: ThemeController.activeTheme().actionButtonColor,
              backgroundColor: ThemeController.activeTheme().foregroundColor,
            ),
            controller: _refreshController,
            onRefresh: _onRefresh,
            child: _polls.length <= 0
                ? Center(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Text(
                        widget.linkedCalendar.isOwner
                            ? "Keine gespeicherten Abstimmungen in diesem Kalender, tippe auf das Abstimmungssymbol um eine neue Abstimmung zu starten."
                            : "Keine gespeicherten Abstimmungen in diesem Kalender.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _polls.length,
                    itemBuilder: _buildItemsForVotingListView,
                  ),
          ),
        )
      ]),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildItemsForVotingListView(BuildContext context, int index) {
    Voting currentVoting = _polls[index];

    //Proof if Calendar exists, if not return free space
    if (!UserController.calendarList.containsKey(currentVoting.calendarID)) return Center();

    Widget tile;

    tile = ListTile(
      focusColor: Colors.red,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text(currentVoting.title),
      subtitle: Text(currentVoting.numberUsersWhoHaveVoted.toString() + "/" + widget.linkedCalendar.assocUserList.length.toString() + " Mitglieder haben bereits abgestimmt"),
      trailing: currentVoting.userHasVoted
          ? Icon(
              Icons.check,
              color: Colors.green,
              size: 30,
              semanticLabel: "Bereits abgestimmt",
            )
          : Icon(
              Icons.how_to_vote,
              color: Colors.red,
              size: 30,
              semanticLabel: "Abstimmung ausstehend",
            ),
      onTap: () async {
        _showVoting(currentVoting);
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
      secondaryActions: (currentVoting.ownerID == UserController.user.userID)
          ? <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: IconSlideAction(
                  caption: 'Löschen',
                  color: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  onTap: () => _deleteVoting(currentVoting),
                ),
              ),
            ]
          : [],
    );
  }

  List<Widget> _buildItemsForNotesView(BuildContext context) {
    if (_pinnedNotes.isEmpty && _unpinnedNotes.isEmpty) {
      return [];
    }

    final factory = NotesGrid.create;

    final hasPinned = _pinnedNotes.isNotEmpty;
    final hasUnpinned = _unpinnedNotes.isNotEmpty;

    final _buildLabel = (String label, [double top = 20]) => SliverToBoxAdapter(
          child: Center(
            child: Container(
              padding: EdgeInsetsDirectional.only(start: 20, bottom: 15, top: top),
              child: Text(
                label,
                style: TextStyle(color: ThemeController.activeTheme().headlineColor, fontWeight: FontWeight.w500, fontSize: 20),
              ),
            ),
          ),
        );

    return [
      if (hasPinned) _buildLabel('Angepinnte Notizen', 0),
      if (hasPinned) factory(notes: _pinnedNotes, onTap: _onNoteTap, onLongPress: _onNoteLongPress),
      if (hasPinned && hasUnpinned) _buildLabel('Weitere Notizen'),
      factory(notes: _unpinnedNotes, onTap: _onNoteTap, onLongPress: _onNoteLongPress),
    ];
  }

  void _onNoteTap(Note note) async {
    bool canEdit = widget.linkedCalendar.canEditEvents || note.ownerID == UserController.user.userID;

    NoteData noteData = await NotePopup.notePopup(widget.linkedCalendar.id, note.noteID, canEdit);
    if (noteData == null) return;

    DialogPopup.asyncLoadingDialog(_keyLoader, "Änderungen werden übernommen...");

    bool success = await widget.linkedCalendar.changeNote(note.noteID, noteData.title, noteData.content, noteData.pinned, noteData.color).catchError((e) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      return false;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!success) {
      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
      await DialogPopup.asyncOkDialog("Änderungen konnte nicht übernommen werden!", Api.errorMessage);
      return;
    }

    setState(() {
      loadNotes();
    });

    Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
  }

  void _onNoteLongPress(Note note) async {
    bool canDelete = widget.linkedCalendar.canEditEvents || note.ownerID == UserController.user.userID;

    if (!canDelete) return;

    if (await DialogPopup.asyncConfirmDialog("Notiz löschen?", "Möchtest du die Notiz unwiederuflich löschen?.") == ConfirmAction.OK) {
      DialogPopup.asyncLoadingDialog(_keyLoader, "Notiz wird gelöscht...");

      bool success = await widget.linkedCalendar.removeNote(note.noteID).catchError((e) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        return false;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!success) {
        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
        await DialogPopup.asyncOkDialog("Notiz konnte nicht gelöscht werden!", Api.errorMessage);
        return;
      }

      setState(() {
        loadNotes();
      });

      Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
    }
  }

  Widget _buildFloatingActionButton() {
    return _tabController.index == 0

        //Notiz Action Button
        ? (widget.linkedCalendar.canCreateEvents ? FloatingActionButton(
            tooltip: "Notiz erstellen",
            child: Icon(
              Icons.sticky_note_2_rounded,
              color: ThemeController.activeTheme().textColor,
              size: 30,
            ),
            backgroundColor: ThemeController.activeTheme().actionButtonColor,
            onPressed: () {
              _createNote();
            },
          ) : Center())

        //Abstimmung Action Button
        : (widget.linkedCalendar.isOwner
            ? FloatingActionButton(
                tooltip: "Abstimmung starten",
                child: Icon(
                  Icons.how_to_vote,
                  color: ThemeController.activeTheme().textColor,
                  size: 30,
                ),
                backgroundColor: ThemeController.activeTheme().actionButtonColor,
                onPressed: () {
                  _createVoting();
                },
              )
            : Center());
  }
}
