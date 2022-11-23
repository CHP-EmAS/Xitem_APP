import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Models/Note.dart';
import 'package:de/Settings/custom_scroll_behavior.dart';
import 'file:///C:/Users/Clemens/Documents/AndroidStudioProjects/live_list/lib/Controller/locator.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const List<Color> noteColors = [
  Color(0xFFFFF476),
  Color(0xFFCDFF90),
  Color(0xFFA7FEEB),
  Color(0xFFCBF0F8),
  Color(0xFFAFCBFA),
  Color(0xFFD7AEFC),
  Color(0xFFFDCFE9),
  Color(0xFFE6C9A9),
  Color(0xFFF28C82),
  Color(0xFFE9EAEE),
];

final defaultNoteColor = noteColors.first;

class NotePopup {
  static final NavigationService _navigationService = locator<NavigationService>();

  static Future<NoteData> notePopup(String calendarID, BigInt noteID, bool canEditNote) {
    if (!UserController.calendarList.containsKey(calendarID)) {
      DialogPopup.asyncOkDialog("Unerwarteter Fehler", "Zugehöriger Kalender konnte nicht gefunden werden!");
      _navigationService.pop(null);
    }

    Calendar _calendar = UserController.calendarList[calendarID];

    final TextEditingController _titleTextController = TextEditingController();
    final TextEditingController _contentTextController = TextEditingController();

    Color _currentColor = defaultNoteColor;
    bool _pinned = false;

    bool newNote = true;

    if (noteID != null) {
      if (!_calendar.noteMap.containsKey(noteID)) {
        DialogPopup.asyncOkDialog("Unerwarteter Fehler", "Notiz konnte nicht gefunden werden!");
        _navigationService.pop(null);
      }

      Note loadedNote = _calendar.noteMap[noteID];

      _titleTextController.text = loadedNote.title;
      _contentTextController.text = loadedNote.content;

      _pinned = loadedNote.pinned;
      _currentColor = loadedNote.color;

      newNote = false;
    }

    return showDialog(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          return ScrollConfiguration(
            behavior: CustomScrollBehavior(false, false),
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                contentPadding: EdgeInsets.fromLTRB(24, 5, 24, 0),
                actionsPadding: EdgeInsets.fromLTRB(15, 5, 15, 0),
                backgroundColor: _currentColor,
                scrollable: true,
                content: Column(
                  children: [
                    TextField(
                      controller: _titleTextController,
                      style: TextStyle(
                        color: Color(0xFF202124),
                        fontSize: 21,
                        height: 19 / 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Titel',
                        hintStyle: TextStyle(
                          color: Color(0xFF61656A),
                        ),
                        border: InputBorder.none,
                        counter: const SizedBox(),
                      ),
                      maxLines: null,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      readOnly: !canEditNote,
                    ),
                    TextField(
                      controller: _contentTextController,
                      style: TextStyle(
                        color: Color(0x99000000),
                        fontSize: 16,
                        height: 1.3125,
                      ),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Notiz',
                        hintStyle: TextStyle(
                          color: Color(0xFF61656A),
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      readOnly: !canEditNote,
                    ),
                  ],
                ),
                elevation: 3,
                actions: canEditNote
                    ? <Widget>[
                        Divider(
                          height: 20,
                          thickness: 1,
                          color: Color(0x99000000),
                        ),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: noteColors
                                  .map((color) => (InkWell(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Color(0xFF202124)),
                                              ),
                                              child: color == _currentColor ? const Icon(Icons.check, color: Color(0xFF202124)) : null,
                                            ),
                                            SizedBox(
                                              width: 5,
                                            )
                                          ],
                                        ),
                                        onTap: () {
                                          if (color != _currentColor) {
                                            setState(() {
                                              _currentColor = color;
                                            });
                                          }
                                        },
                                      )))
                                  .toList(),
                            )),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                                size: 28,
                                color: _pinned ? Color(0xFF202124) : Color(0xFF61656A),
                              ),
                              tooltip: _pinned ? "Notiz abpinnen" : "Notiz anpinnen",
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.zero,
                              splashRadius: 0.001,
                              onPressed: () {
                                setState(() {
                                  _pinned = !_pinned;
                                });
                              },
                            ),
                            FlatButton(
                              child: Text(newNote ? 'Erstellen' : "Änderung speichern", style: TextStyle(color: Color(0xFF202124), fontSize: 18)),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (_titleTextController.text.isNotEmpty && _contentTextController.text.isNotEmpty) {
                                  _navigationService.pop(NoteData(_titleTextController.text, _contentTextController.text, _currentColor, _pinned));
                                }
                              },
                            ),
                          ],
                        )
                      ]
                    : <Widget>[],
              );
            }),
          );
        });
  }
}

class NoteData {
  NoteData(this.title, this.content, this.color, this.pinned);

  final String title;
  final String content;

  final Color color;
  final bool pinned;
}
