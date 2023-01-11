import 'package:flutter/material.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/models/Note.dart';

class NotesGrid extends StatelessWidget {
  final List<Note> notes;
  final void Function(Note) onTap;
  final void Function(Note) onLongPress;

  const NotesGrid({
    super.key,
    required this.notes,
    required this.onTap,
    required this.onLongPress,
  });

  static NotesGrid create({
    required List<Note> notes,
    required void Function(Note) onTap,
    required void Function(Note) onLongPress,
  }) =>
      NotesGrid(
        notes: notes,
        onTap: onTap,
        onLongPress: onLongPress,
      );

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200.0,
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
            childAspectRatio: 1 / 1.2,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => _noteItem(context, notes[index]),
            childCount: notes.length,
          ),
        ),
      );

  Widget _noteItem(BuildContext context, Note note) => InkWell(
        onTap: () => onTap.call(note),
        onLongPress: () => onLongPress.call(note),
        child: NoteItem(note: note),
      );
}

class NoteItem extends StatelessWidget {
  const NoteItem({
    super.key,
    required this.note,
  });

  final Note note;

  @override
  Widget build(BuildContext context) => Hero(
        tag: 'NoteItem${note.noteID}',
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0x99000000),
            fontSize: 16,
            height: 1.3125,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ThemeController.getNoteColor(note.color),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (note.title.isNotEmpty == true)
                  Text(
                    note.title,
                    style: const TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 16,
                      height: 19 / 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                if (note.title.isNotEmpty == true) const SizedBox(height: 14),
                Flexible(
                  flex: 1,
                  child: Text(note.content), // wrapping using a Flexible to avoid overflow
                ),
              ],
            ),
          ),
        ),
      );
}
