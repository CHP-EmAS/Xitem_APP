import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/NoteController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/controllers/UserController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/Note.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/CustomScrollBehavior.dart';
import 'package:xitem/widgets/NotesGrid.dart';
import 'package:xitem/widgets/dialogs/NoteDialog.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.linkedCalendarID, required this.calendarController, required this.userController});

  final String linkedCalendarID;
  final CalendarController calendarController;
  final UserController userController;

  @override
  State<StatefulWidget> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with SingleTickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  late Calendar? _linkedCalendar;
  late bool _canCreateEvents = false;

  final List<Note> _pinnedNotes = [];
  final List<Note> _unpinnedNotes = [];

  @override
  void initState() {
    super.initState();

    _linkedCalendar = widget.calendarController.getCalendar(widget.linkedCalendarID);
    _canCreateEvents = _linkedCalendar?.calendarMemberController.getCalendarMember(widget.userController.getAuthenticatedUser().id)?.canCreateEvents ?? false;

    _loadNotes();
  }

  void _loadNotes() {
    _pinnedNotes.clear();
    _unpinnedNotes.clear();

    if (_linkedCalendar == null) {
      return;
    }

    _linkedCalendar!.noteController.getNoteList().forEach((note) {
      if (note.pinned) {
        _pinnedNotes.add(note);
      } else {
        _unpinnedNotes.add(note);
      }
    });
  }

  void _onRefresh() async {
    ResponseCode reloadCompleted = await widget.calendarController.reloadCalendar(widget.linkedCalendarID);

    if (reloadCompleted != ResponseCode.success) {
      _refreshController.refreshFailed();
      return;
    }

    _linkedCalendar = widget.calendarController.getCalendar(widget.linkedCalendarID);
    setState(() {
      _loadNotes();
    });
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNotes = _pinnedNotes.isNotEmpty || _unpinnedNotes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            StateController.navigatorKey.currentState?.pop();
          },
        ),
        titleSpacing: 0,
        title: SizedBox(height: 54, child: Tab(child: Text("Notizen", style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16)))),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        elevation: 3,
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: _linkedCalendar == null
          ? const Center(
              child: Text(
              "Fehler beim Laden der Notizen :(",
              textAlign: TextAlign.center,
            ))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 720),
                child: ScrollConfiguration(
                  behavior: const CustomScrollBehavior(false, true),
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
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 24),
                              ),
                              ..._buildItemsForNotesView(
                                context,
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 10.0),
                              ),
                            ],
                          )
                        : Center(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Text(
                                _canCreateEvents
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  List<Widget> _buildItemsForNotesView(BuildContext context) {
    if (_pinnedNotes.isEmpty && _unpinnedNotes.isEmpty) {
      return [];
    }

    const factory = NotesGrid.create;

    final hasPinned = _pinnedNotes.isNotEmpty;
    final hasUnpinned = _unpinnedNotes.isNotEmpty;

    buildLabel(String label, [double top = 20]) => SliverToBoxAdapter(
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
      if (hasPinned) buildLabel('Angepinnte Notizen', 0),
      if (hasPinned) factory(notes: _pinnedNotes, onTap: _onNoteTap, onLongPress: _onNoteLongPress),
      if (hasPinned && hasUnpinned) buildLabel('Weitere Notizen'),
      factory(notes: _unpinnedNotes, onTap: _onNoteTap, onLongPress: _onNoteLongPress),
    ];
  }

  void _onNoteTap(Note note) async {
    if (_linkedCalendar == null) {
      return;
    }

    bool canEdit = _canCreateEvents || note.ownerID == widget.userController.getAuthenticatedUser().id;

    NoteData? noteData = await NoteDialog.notePopup(note, canEdit);
    if (noteData == null) return;

    StandardDialog.loadingDialog("Änderungen werden übernommen...");

    ResponseCode changeNote = await _linkedCalendar!.noteController.changeNote(note.noteID, noteData.title, noteData.content, noteData.pinned, noteData.color).catchError((e) {
      return ResponseCode.unknown;
    });

    if (changeNote != ResponseCode.success) {
      String errorMessage;

      switch (changeNote) {
        case ResponseCode.accessForbidden:
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Termin in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
          break;
        case ResponseCode.noteNotFound:
          errorMessage = "Notiz konnte nicht gefunden werden.";
          break;
        case ResponseCode.invalidTitle:
          errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
      }

      StateController.navigatorKey.currentState?.pop();
      await StandardDialog.okDialog("Änderungen konnte nicht übernommen werden!", errorMessage);
      return;
    }

    setState(() {
      _loadNotes();
    });

    StateController.navigatorKey.currentState?.pop();
  }

  void _onNoteLongPress(Note note) async {
    if (_linkedCalendar == null) {
      return;
    }

    bool canDelete = _canCreateEvents || note.ownerID == widget.userController.getAuthenticatedUser().id;
    if (!canDelete) {
      return;
    }

    if (await StandardDialog.confirmDialog("Notiz löschen?", "Möchtest du die Notiz unwiederuflich löschen?.") != ConfirmAction.ok) {
      return;
    }

    StandardDialog.loadingDialog("Notiz wird gelöscht...");

    ResponseCode deleteNote = await _linkedCalendar!.noteController.removeNote(note.noteID).catchError((e) {
      return ResponseCode.unknown;
    });

    if (deleteNote != ResponseCode.success) {
      String errorMessage;

      switch (deleteNote) {
        case ResponseCode.accessForbidden:
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du hast nicht die nötigen Berechtigungen um eine Notiz in diesem Kalender zu löschen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Löschen der Notiz ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      }

      StateController.navigatorKey.currentState?.pop();
      await StandardDialog.okDialog("Notiz konnte nicht gelöscht werden!", errorMessage);
      return;
    }

    setState(() {
      _loadNotes();
    });

    StateController.navigatorKey.currentState?.pop();
  }

  void _createNote() async {
    NoteController? noteController = _linkedCalendar?.noteController;
    if (noteController == null) {
      return;
    }

    NoteData? noteData = await NoteDialog.notePopup(null, true);
    if (noteData == null) return;

    StandardDialog.loadingDialog("Erstelle Notiz...");

    ResponseCode createNote = await noteController.createNote(noteData.title, noteData.content, noteData.pinned,  noteData.color).catchError((e) {
      StateController.navigatorKey.currentState?.pop();
      return ResponseCode.internalError;
    });

    if (createNote != ResponseCode.success) {
      String errorMessage;

      switch (createNote) {
        case ResponseCode.missingArgument:
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case ResponseCode.invalidTitle:
          errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
          break;
        case ResponseCode.accessForbidden:
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Erstellen der Notiz ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      StateController.navigatorKey.currentState?.pop();
      await StandardDialog.okDialog("Notiz konnte nicht erstellt werden!", errorMessage);
      return;
    }

    setState(() {
      _loadNotes();
    });

    StateController.navigatorKey.currentState?.pop();
  }

  Widget _buildFloatingActionButton() {
    return _canCreateEvents
        ? FloatingActionButton(
            tooltip: "Notiz erstellen",
            backgroundColor: ThemeController.activeTheme().actionButtonColor,
            onPressed: () {
              _createNote();
            },
            child: Icon(
              Icons.sticky_note_2_rounded,
              color: ThemeController.activeTheme().textColor,
              size: 30,
            ),
          )
        : const Center();
  }
}
