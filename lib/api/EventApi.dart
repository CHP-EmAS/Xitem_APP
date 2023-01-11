import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/main.dart';
import 'package:xitem/models/Event.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:timezone/timezone.dart' as tz;

class EventApi extends ApiGateway {

  EventApi();

  Future<ApiResponse<List<Event>>> loadEvents(String calendarID, DateTime beginPeriod, DateTime endPeriod) async {
    List<Event> eventList = <Event>[];

    try {
      Response response =
      await sendRequest("/filter/calendar/$calendarID/period?begin_date=${beginPeriod.toIso8601String()}&end_date=${endPeriod.toIso8601String()}", RequestType.get, null, null, true);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("Events")) {
          for (final event in data["Events"]) {
            final BigInt eventID = BigInt.parse(event["event_id"]);

            final String title = event["title"];
            final String description = event["description"];

            DateTime startDate = DateTime.parse(event["begin_date"]);
            DateTime endDate = DateTime.parse(event["end_date"]);

            final DateTime creationDate = DateTime.parse(event["creation_date"]);

            final int color = event["color"];

            final String createdByUser = event["created_by_user"];
            final bool daylong = event["daylong"];

            final tzConvertedStartDate = tz.TZDateTime.from(startDate, Xitem.settingController.getTimeZone());
            startDate = DateTime(tzConvertedStartDate.year, tzConvertedStartDate.month, tzConvertedStartDate.day, tzConvertedStartDate.hour, tzConvertedStartDate.minute);

            final tzConvertedEndDate = tz.TZDateTime.from(endDate, Xitem.settingController.getTimeZone());
            endDate = DateTime(tzConvertedEndDate.year, tzConvertedEndDate.month, tzConvertedEndDate.day, tzConvertedEndDate.hour, tzConvertedEndDate.minute);

            Event newEvent = Event(
                eventID,
                startDate,
                endDate,
                title,
                description,
                color,
                calendarID,
                createdByUser,
                daylong,
                creationDate);

            eventList.add(newEvent);
          }

          return ApiResponse(ResponseCode.success, eventList);
        }
      }

      return ApiResponse(extractResponseCode(response));
    } catch(error) {
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ApiResponse<Event>> loadSingleEvent(String calendarID, BigInt eventID) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/event/${eventID.toString()}", RequestType.get, null, null, true);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("Event")) {
          Map<String, dynamic> event = data["Event"];

          final BigInt eventID = BigInt.parse(event["event_id"]);
          final String title = event["title"];
          final String description = event["description"];

          DateTime startDate = DateTime.parse(event["begin_date"]);
          DateTime endDate = DateTime.parse(event["end_date"]);

          final DateTime creationDate = DateTime.parse(event["creation_date"]);
          final int color = event["color"];
          final String createdByUser = event["created_by_user"];
          final bool daylong = event["daylong"];

          final tzConvertedStartDate = tz.TZDateTime.from(startDate, Xitem.settingController.getTimeZone());
          startDate = DateTime(tzConvertedStartDate.year, tzConvertedStartDate.month, tzConvertedStartDate.day, tzConvertedStartDate.hour, tzConvertedStartDate.minute);

          final tzConvertedEndDate = tz.TZDateTime.from(endDate, Xitem.settingController.getTimeZone());
          endDate = DateTime(tzConvertedEndDate.year, tzConvertedEndDate.month, tzConvertedEndDate.day, tzConvertedEndDate.hour, tzConvertedEndDate.minute);

          Event newEvent = Event(eventID, startDate, endDate, title, description, color, calendarID, createdByUser, daylong, creationDate);

          return ApiResponse(ResponseCode.success, newEvent);
        }
      }

      return ApiResponse(extractResponseCode(response));
    } catch(error) {
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ApiResponse<BigInt>> createEvent(String calendarID, CreateEventRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/event", RequestType.post, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("event_id")) {
          return ApiResponse(ResponseCode.success, BigInt.parse(responseData["event_id"]));
        }
      }

      //   case "missing_argument":
      //     errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
      //   case "invalid_title":
      //     errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
      //   case "end_before_start":
      //     errorMessage = "Das Enddatum muss nach dem Startdatum liegen.";
      //   case "start_after_1900":
      //     errorMessage = "Das Startdatum muss nach dem 01.01.1900 liegen.";
      //   case "access_forbidden":
      //   case "insufficient_permissions":
      //     errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
      //   case "invalid_color":
      //     errorMessage = "Unzulässige Farbe.";
      //   default:
      //     errorMessage = "Beim Erstellen des Events ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ResponseCode> patchEvent(String calendarID, BigInt eventID, PatchEventRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/event/${eventID.toString()}", RequestType.patch, requestData, null, true);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }

        // case "access_forbidden":
        // case "insufficient_permissions":
        //   errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
        // case "event_not_found":
        //   errorMessage = "Event konnte nicht gefunden werden.";
        // case "invalid_color":
        //   errorMessage = "Unzulässige Farbe.";
        // case "invalid_title":
        //   errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
        // case "start_after_1900":
        //   errorMessage = "Das Startdatum muss nach dem 01.01.1900 liegen.";
        // case "end_before_start":
        //   errorMessage = "Das Enddatum muss nach dem Startdatum liegen.";

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      //errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
      return ResponseCode.unknown;
    }
  }

  Future<ResponseCode> deleteEvent(String calendarID, BigInt eventID) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/event/${eventID.toString()}", RequestType.delete, null, null, true);

      if (response.statusCode == 200 || response.statusCode == 404) {
        return ResponseCode.success;
      }

      //   case "access_forbidden":
      //   case "insufficient_permissions":
      //     errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu löschen. Bitte wende dich an den Kalenderadministrator";

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      //errorMessage = "Beim Löschen des Events ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return ResponseCode.unknown;
    }
  }
}