import 'package:de/Models/Note.dart';
import 'package:flutter/material.dart';

class NotesGrid extends StatelessWidget {
  final List<Note> notes;
  final void Function(Note) onTap;
  final void Function(Note) onLongPress;

  const NotesGrid({
    Key key,
    @required this.notes,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  static NotesGrid create({
    Key key,
    @required List<Note> notes,
    void Function(Note) onTap,
    void Function(Note) onLongPress,
  }) =>
      NotesGrid(
        key: key,
        notes: notes,
        onTap: onTap,
        onLongPress: onLongPress,
      );

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
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
        onTap: () => onTap?.call(note),
        onLongPress: () => onLongPress?.call(note),
        child: NoteItem(note: note),
      );
}

class NoteItem extends StatelessWidget {
  const NoteItem({
    Key key,
    this.note,
  }) : super(key: key);

  final Note note;

  @override
  Widget build(BuildContext context) => Hero(
        tag: 'NoteItem${note.noteID}',
        child: DefaultTextStyle(
          style: TextStyle(
            color: Color(0x99000000),
            fontSize: 16,
            height: 1.3125,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: note.color,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (note.title?.isNotEmpty == true)
                  Text(
                    note.title,
                    style: TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 16,
                      height: 19 / 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                if (note.title?.isNotEmpty == true) const SizedBox(height: 14),
                Flexible(
                  flex: 1,
                  child: Text(note.content ?? ''), // wrapping using a Flexible to avoid overflow
                ),
              ],
            ),
          ),
        ),
      );
}
