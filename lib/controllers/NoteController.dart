import 'dart:ui';

import 'package:xitem/api/NoteApi.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/Note.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class NoteController {
  NoteController(this._noteApi);

  final NoteApi _noteApi;

  late final String _relatedCalendarID;
  bool _isInitialized = false;

  final Map<BigInt, Note> _noteMap = <BigInt, Note>{};

  Future<ResponseCode> initialize(String relatedCalendarID) async {
    if(_isInitialized) {
      return ResponseCode.invalidAction;
    }

    _relatedCalendarID = relatedCalendarID;

    ResponseCode initialLoad = await _loadAllNotes();

    if(initialLoad != ResponseCode.success) {
      _resetControllerState();
      return initialLoad;
    }

    _isInitialized = true;
    return ResponseCode.success;
  }

  Future<ResponseCode> _loadAllNotes() async {
    ApiResponse<List<Note>> loadNotes = await _noteApi.loadAllNotes(_relatedCalendarID);
    List<Note>? noteList = loadNotes.value;

    if (loadNotes.code != ResponseCode.success) {
      return loadNotes.code;
    } else if (noteList == null) {
      return ResponseCode.unknown;
    }

    _noteMap.clear();

    for (var note in noteList) {
      _noteMap[note.noteID] = note;
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> loadNote(BigInt noteID) async {
    if(!_isInitialized) {
      throw AssertionError("NoteController must be initialized before it can be accessed!");
    }

    ApiResponse<Note> loadNote = await _noteApi.loadSingleNote(_relatedCalendarID, noteID);
    Note? note = loadNote.value;

    if (loadNote.code != ResponseCode.success) {
      return loadNote.code;
    } else if (note == null) {
      return ResponseCode.unknown;
    }

    _noteMap[note.noteID] = note;

    return ResponseCode.success;
  }

  List<Note> getNoteList() {
    if(!_isInitialized) {
      throw AssertionError("NoteController must be initialized before it can be accessed!");
    }

    return _noteMap.values.toList();
  }

  Future<ResponseCode> createNote(String title, String content, bool pinned, int color) async {
    if(!_isInitialized) {
      throw AssertionError("NoteController must be initialized before it can be accessed!");
    }

    ApiResponse<BigInt> createNote = await _noteApi.createNote(_relatedCalendarID, CreateNoteRequest(title, content, pinned, color));
    BigInt? newNoteID = createNote.value;

    if (createNote.code != ResponseCode.success) {
      return createNote.code;
    } else if (newNoteID == null) {
      return ResponseCode.unknown;
    }

    return await loadNote(newNoteID);
  }

  Future<ResponseCode> changeNote(BigInt noteID, String title, String content, bool pinned, int color) async {
    if(!_isInitialized) {
      throw AssertionError("NoteController must be initialized before it can be accessed!");
    }

    ResponseCode patchNote = await _noteApi.patchNote(_relatedCalendarID, noteID, PatchNoteRequest(title, content, pinned, color));

    if (patchNote != ResponseCode.success) {
      return patchNote;
    }

    return await loadNote(noteID);
  }

  Future<ResponseCode> removeNote(BigInt noteID) async {
    if(!_isInitialized) {
      throw AssertionError("NoteController must be initialized before it can be accessed!");
    }

    ResponseCode deleteNote = await _noteApi.deleteNote(_relatedCalendarID, noteID);

    if (deleteNote != ResponseCode.success) {
      return deleteNote;
    }

    _noteMap.remove(noteID);

    return ResponseCode.success;
  }

  void _resetControllerState() {
    _noteMap.clear();
    _isInitialized = false;
  }
}