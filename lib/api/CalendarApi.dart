import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/interfaces/CalendarApiInterfaces.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class CalendarApi extends ApiGateway {
  Future<ApiResponse<List<LoadedCalendarData>>> loadAllCalendars(final String userID) async {
    try {
      List<LoadedCalendarData> assocCalendars = [];

      Response response = await sendRequest("/user/$userID/calendars", RequestType.get, null, null, true);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("associated_calendars")) {
          for (final calendar in data["associated_calendars"]) {
            final String id = calendar["calendarObject"]["calendar_id"];
            final String fullName = calendar["calendarObject"]["calendar_name"];
            final canJoin = calendar["calendarObject"]["can_join"];
            final String creationDate = calendar["calendarObject"]["creation_date"];
            //final bool isOwner = calendar["is_owner"];
            //final bool canCreateEvents = calendar["can_create_events"];
            //final bool canEditEvents = calendar["can_edit_events"];
            final int color = calendar["color"];
            final int iconPoint = calendar["icon"];
            final String rawColorLegend = calendar["calendarObject"]["raw_color_legend"];

            LoadedCalendarData newCalendar = LoadedCalendarData(id, fullName, canJoin, creationDate, color, IconData(iconPoint, fontFamily: 'MaterialIcons'), rawColorLegend);

            assocCalendars.add(newCalendar);
          }

          return ApiResponse(ResponseCode.success, assocCalendars);
        }
      }

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ApiResponse<String>> createCalendar(CreateCalendarRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar", RequestType.post, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("calendar_id")) {
          return ApiResponse(ResponseCode.success, responseData["calendar_id"].toString());
        }
      }

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ApiResponse<String>> joinCalendar(String hashName, JoinCalendarRequest requestData) async {
    try {
      hashName = hashName.replaceAll(RegExp(r'#'), "%23");

      Response response = await sendRequest("/calendar/$hashName/user", RequestType.post, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("calendar_id")) {
          return ApiResponse(ResponseCode.success, responseData["calendar_id"].toString());
        }
      }

      // switch (_errorCode) {
      //   case "missing_argument":
      //     errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
      //     break;
      //   case "already_exists":
      //     errorMessage = "Du bist bereits Mitglied in diesem Kalender.";
      //     break;
      //   default:
      //     errorMessage = "Beim Beitreten des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      //     break;
      // }

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ResponseCode> deleteCalendar(String calendarID) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID", RequestType.delete, null, null, true, true);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }

      // else if (response.statusCode == 401) {
      //   //errorMessage = "Passwort falsch.";
      // } else if (response.statusCode == 403) {
      //   //errorMessage = "Du kannst diesem Kalender nicht löschen."; accessForbidden insufficientPermissions
      //   case "missing_argument":
      //     errorMessage = "Es wurde kein Passwort angegeben.";
      //   default:
      //     errorMessage = "Beim Löschen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      return ResponseCode.unknown;
    }
  }

  Future<ResponseCode> leaveCalendar(String calendarID, String userID) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/user/$userID", RequestType.delete, null, null, true, true);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }

      // else if (response.statusCode == 401) {
      //   errorMessage = "Passwort falsch.";
      // } else if (response.statusCode == 403) {
      //   errorMessage = "Du bist kein Mitglied in diesem Kalender. ";
      //   case "missing_argument":
      //     errorMessage = "Es wurde kein Passwort angegeben.";
      //   case "last_member":
      //     errorMessage = "Du kannst diesen Kalender nicht verlassen da du das einzige Mitglied bist. Lösche den Kalender stattdessen.";
      //   case "last_owner":
      //     errorMessage = "Du kannst diesen Kalender nicht verlassen da du der einzige Administrator bist. Ernenne einen anderen Administrator um den Kalender zu verlassen.";
      //   default:
      //     errorMessage = "Beim Verlassen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      return ResponseCode.unknown;
    }
  }

  Future<ApiResponse<LoadedCalendarData>> loadSingleCalendar(String calendarID) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID", RequestType.get, null, null, true);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("Calendar")) {
          Map<String, dynamic> calendar = data["Calendar"];

          final String id = calendar["calendarObject"]["calendar_id"];
          final String fullName = calendar["calendarObject"]["calendar_name"];
          final canJoin = calendar["calendarObject"]["can_join"];
          final String creationDate = calendar["calendarObject"]["creation_date"];
          //final bool isOwner = calendar["is_owner"];
          //final bool canCreateEvents = calendar["can_create_events"];
          //final bool canEditEvents = calendar["can_edit_events"];
          final int color = calendar["color"];
          final int iconPoint = calendar["icon"];
          final String rawColorLegend = calendar["calendarObject"]["raw_color_legend"];

          LoadedCalendarData newCalendar = LoadedCalendarData(id, fullName, canJoin, creationDate, color, IconData(iconPoint, fontFamily: 'MaterialIcons'), rawColorLegend);

          return ApiResponse(ResponseCode.success, newCalendar);
        }
      }

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ResponseCode> patchCalendar(String calendarID, PatchCalendarRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID", RequestType.patch, requestData, null, true);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }
      // } else if (response.statusCode == 403) {
      //   errorMessage = "Du kannst diese Einstellungen nicht ändern."

      /* case "short_password":
          errorMessage = "Das Passwort muss mindestens 6 Zeichen lang sein."
        case "invalid_title":
          errorMessage = "Unzulässiger Name. Zulässige Zeichen: a-z, A-Z, 0-9, Leerzeichen, _, -"
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut."
      }*/

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      return ResponseCode.unknown;
    }
  }

  Future<ResponseCode> patchCalendarLayout(String calendarID, PatchCalendarLayoutRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/layout", RequestType.patch, requestData, null, true);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }
      // } else if (response.statusCode == 403) {
      //    errorMessage = "Du kannst diese Einstellungen nicht ändern.";
      //   case "missing_argument":
      //     errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
      //   default:
      //     errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      return ResponseCode.unknown;
    }
  }

  Future<ApiResponse<String>> getCalendarInvitationToken(String calendarID, CalendarInvitationTokenRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/invitation", RequestType.post, requestData, null, true, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData.containsKey("Token")) {
          return ApiResponse(ResponseCode.success, responseData["Token"].toString());
        }
      }

      //   case "insufficient_permissions":
      //     errorMessage = "Du musst Kalenderadministrator sein um eine QR-Code Einladung erstellen zu können.";
      //   case "access_forbidden":
      //     errorMessage = "Du musst Mitglied in diesem Kalender sein um eine QR-Code Einladung erstellen zu können.";
      //   case "missing_argument":
      //     errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
      //   case "invalid_number":
      //     errorMessage = "Die Gültigkeitsdauer muss zwischen 5min und 7Tagen liegen.";
      //   default:
      //     errorMessage = "Beim Erstellen der QR Einladung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ApiResponse<String>> acceptCalendarInvitationToken(AcceptCalendarInvitationRequest requestData) async {
    try {
      Response response = await sendRequest("/invitation", RequestType.post, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("calendar_id")) {
          return ApiResponse(ResponseCode.success, responseData["calendar_id"]);
        }
      }

      //   case "invalid_token":
      //   case "expired_token":
      //     errorMessage = "Diese Einladung ist ungültig oder abgelaufen.";
      //   case "calendar_not_found":
      //     errorMessage = "Der Kalender den du betreten möchtest existiert nicht mehr.";
      //   case "calendar_not_joinable":
      //     errorMessage = "Diesem Kalender kann nicht beigetreten werden.";
      //   case "already_exists":
      //     errorMessage = "Du bist bereits Mitglied in diesem Kalender.";
      //   case "missing_argument":
      //     errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
      //   case "invalid_color":
      //     errorMessage = "Unzulässige Farbe.";
      //   default:
      //     errorMessage = "Beim Beitreten des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.unknown);
    }
  }
}
