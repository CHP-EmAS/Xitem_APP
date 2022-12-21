import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart';
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/Note.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class NoteApi extends ApiGateway {

  Future<ApiResponse<List<Note>>> loadAllNotes(String calendarID) async {
    List<Note> noteList = <Note>[];

    Response response = await sendRequest("/calendar/$calendarID/note", RequestType.get, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Notes")) {
        for (final note in data["Notes"]) {
          final BigInt noteID = BigInt.parse(note["note_id"]);

          final String title = note["title"];
          final String content = note["content"];

          final int color = int.parse(note["color"]);
          final bool pinned = note["pinned"];

          final String ownerID = note["owner_id"];

          final DateTime creationDate = DateTime.parse(note["creation_date"]);
          final DateTime modificationDate = DateTime.parse(note["modification_date"]);

          Note loadedNote = Note(noteID, title, content, color, pinned, calendarID, ownerID, creationDate, modificationDate);

          noteList.add(loadedNote);
        }

        return ApiResponse(ResponseCode.success, noteList);
      }
    }

    return ApiResponse(extractResponseCode(response));
  }

  Future<ApiResponse<Note>> loadSingleNote(String calendarID, BigInt noteID) async {
    Response response = await sendRequest("/calendar/$calendarID/note/${noteID.toString()}", RequestType.get, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Note")) {
        Map<String, dynamic> note = data["Event"];

        final BigInt noteID = BigInt.parse(note["note_id"]);
        final String title = note["title"];
        final String content = note["content"];

        final String ownerID = note["owner_id"];

        final int color = int.parse(note["color"]);
        final bool pinned = note["pinned"];

        final DateTime creationDate = DateTime.parse(note["creation_date"]);
        final DateTime modificationDate = DateTime.parse(note["modification_date"]);

        Note loadedNote = Note(noteID, title, content, color, pinned, calendarID, ownerID, creationDate, modificationDate);

        return ApiResponse(ResponseCode.success, loadedNote);
      }
    }

    return ApiResponse(extractResponseCode(response));
  }

  Future<ApiResponse<BigInt>> createNote(String calendarID, CreateNoteRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/note", RequestType.post, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("note_id")) {
          return ApiResponse(ResponseCode.success, BigInt.parse(responseData["note_id"]));
        }
      }

      // switch (_errorCode) {
      //   case "missing_argument":
      //     errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
      //     break;
      //   case "invalid_title":
      //     errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
      //     break;
      //   case "access_forbidden":
      //   case "insufficient_permissions":
      //     errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
      //     break;
      //   default:
      //     errorMessage = "Beim Erstellen der Notiz ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      //     break;
      // }

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      print(error);
      //errorMessage = "Beim Erstellen der Notiz ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ResponseCode> patchNote(String calendarID, BigInt noteID, PatchNoteRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/note/${noteID.toString()}", RequestType.patch, requestData, null, true);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }

      return extractResponseCode(response);
    } catch (error) {
      print(error);
      return ResponseCode.unknown;
    }
  }

  Future<ResponseCode> deleteNote(String calendarID, BigInt noteID) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/note/${noteID.toString()}", RequestType.delete, null, null, true);

      if (response.statusCode == 200 || response.statusCode == 404) {
        return ResponseCode.success;
      }

      return extractResponseCode(response);
    } catch (error) {
      print(error);
      return ResponseCode.unknown;
    }
  }
}