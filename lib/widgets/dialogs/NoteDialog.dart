import 'package:flutter/material.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/models/Note.dart';
import 'package:xitem/utils/CustomScrollBehavior.dart';

class NoteDialog {
  static Future<NoteData?> notePopup(Note? note, bool canEditNote) async {
    BuildContext? currentContext = StateController.navigatorKey.currentContext;
    if (currentContext == null) {
      return null;
    }

    final TextEditingController titleTextController = TextEditingController();
    final TextEditingController contentTextController = TextEditingController();

    int currentColor = 0;
    bool pinned = false;

    bool newNote = true;

    if (note != null) {
      titleTextController.text = note.title;
      contentTextController.text = note.content;

      pinned = note.pinned;
      currentColor = note.color;

      newNote = false;
    }

    return showDialog(
        context: currentContext,
        builder: (BuildContext context) {
          return ScrollConfiguration(
            behavior: const CustomScrollBehavior(false, false),
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                contentPadding: const EdgeInsets.fromLTRB(24, 5, 24, 0),
                actionsPadding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                backgroundColor: ThemeController.getNoteColor(currentColor),
                scrollable: true,
                content: Column(
                  children: [
                    TextField(
                      controller: titleTextController,
                      style: const TextStyle(
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
                        counter: SizedBox(),
                      ),
                      maxLines: null,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      readOnly: !canEditNote,
                    ),
                    TextField(
                      controller: contentTextController,
                      style: const TextStyle(
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
                        const Divider(
                          height: 20,
                          thickness: 1,
                          color: Color(0x99000000),
                        ),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              for (int colorIndex = 0; colorIndex < ThemeController.noteColors.length; colorIndex++)
                                InkWell(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: ThemeController.getNoteColor(colorIndex),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF202124)),
                                        ),
                                        child: colorIndex == currentColor ? const Icon(Icons.check, color: Color(0xFF202124)) : null,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      )
                                    ],
                                  ),
                                  onTap: () {
                                    if (colorIndex != currentColor) {
                                      setState(() {
                                        currentColor = colorIndex;
                                      });
                                    }
                                  },
                                )
                            ])),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                pinned ? Icons.push_pin : Icons.push_pin_outlined,
                                size: 28,
                                color: pinned ? const Color(0xFF202124) : const Color(0xFF61656A),
                              ),
                              tooltip: pinned ? "Notiz abpinnen" : "Notiz anpinnen",
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.zero,
                              splashRadius: 0.001,
                              onPressed: () {
                                setState(() {
                                  pinned = !pinned;
                                });
                              },
                            ),
                            TextButton(
                              onPressed: () {
                                if (titleTextController.text.isNotEmpty && contentTextController.text.isNotEmpty) {
                                  Navigator.pop(context, NoteData(titleTextController.text, contentTextController.text, currentColor, pinned));
                                }
                              },
                              child: Text(newNote ? 'Erstellen' : "Änderung speichern", style: const TextStyle(color: Color(0xFF202124), fontSize: 18)),
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

  final int color;
  final bool pinned;
}
