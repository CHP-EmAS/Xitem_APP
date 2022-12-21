import 'dart:convert';

import 'package:http/http.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/Voting.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

import '../controllers/SettingController.dart';

class VotingApi extends ApiGateway {

  VotingApi(this.setting);

  final SettingController setting;

  Future<ApiResponse<Voting>> loadSingleVoting(String calendarID, int votingID) async {
    Response response = await sendRequest("/calendar/$calendarID/voting/${votingID.toString()}", RequestType.get, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Voting")) {
        Map<String, dynamic> voting = data["Voting"];

        final int votingID = voting["voting_id"];
        final String ownerID = voting["owner_id"];

        final String title = voting["title"];

        final bool multipleChoice = voting["multiple_choice"];
        final bool abstentionAllowed = voting["abstention_allowed"];

        final bool userHasVoted = voting["userHasVoted"];
        final int numberUsersWhoHaveVoted = voting["numberUsersWhoHaveVoted"];

        final DateTime creationDate = DateTime.parse(voting["creation_date"]);

        Map<int, Choice> choices = <int, Choice>{};

        for (final choice in voting["choices"]) {
          final int choiceID = choice["choice_id"];

          final String comment = choice["comment"];
          final int amountVotes = choice["amountVotes"];

          DateTime date = DateTime.now();
          if (choice["date"] != null) {
            date = DateTime.parse(choice["date"]);

            final tzConvertedStartDate = tz.TZDateTime.from(date, setting.getTimeZone());
            date = DateTime(tzConvertedStartDate.year, tzConvertedStartDate.month, tzConvertedStartDate.day, tzConvertedStartDate.hour, tzConvertedStartDate.minute);
          }

          choices[choiceID] = Choice(choiceID, votingID, date, comment, amountVotes);
        }

        Voting newVoting = Voting(votingID, calendarID, ownerID, title, multipleChoice, abstentionAllowed, userHasVoted, numberUsersWhoHaveVoted, choices, creationDate);

        return ApiResponse(ResponseCode.success, newVoting);
      }
    }

    return ApiResponse(extractResponseCode(response));
  }

  Future<ApiResponse<List<Voting>>> loadAllVoting(String calendarID) async {
    Response response = await sendRequest("/calendar/$calendarID/voting", RequestType.get, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      List<Voting> votingList = <Voting>[];

      if (data.containsKey("Votings")) {
        for (final voting in data["Votings"]) {
          final int votingID = voting["voting_id"];
          final String ownerID = voting["owner_id"];

          final String title = voting["title"];

          final bool multipleChoice = voting["multiple_choice"];
          final bool abstentionAllowed = voting["abstention_allowed"];

          final bool userHasVoted = voting["userHasVoted"];
          final int numberUsersWhoHaveVoted = voting["numberUsersWhoHaveVoted"];

          final DateTime creationDate = DateTime.parse(voting["creation_date"]);

          Map<int, Choice> choices = <int, Choice>{};

          for (final choice in voting["choices"]) {
            final int choiceID = choice["choice_id"];

            final String comment = choice["comment"];
            final int amountVotes = choice["amountVotes"];

            DateTime date = DateTime.now();
            if (choice["date"] != null) {
              date = DateTime.parse(choice["date"]);

              final tzConvertedStartDate = tz.TZDateTime.from(date, setting.getTimeZone());
              date = DateTime(tzConvertedStartDate.year, tzConvertedStartDate.month, tzConvertedStartDate.day, tzConvertedStartDate.hour, tzConvertedStartDate.minute);
            }

            choices[choiceID] = Choice(choiceID, votingID, date, comment, amountVotes);
          }

          Voting newVoting = Voting(votingID, calendarID, ownerID, title, multipleChoice, abstentionAllowed, userHasVoted, numberUsersWhoHaveVoted, choices, creationDate);

          votingList.add(newVoting);
        }

        return ApiResponse(ResponseCode.success, votingList);
      }
    }

    return ApiResponse(extractResponseCode(response));
  }

  Future<ApiResponse<int>> createVoting(String calendarID, CreateVotingRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/voting", RequestType.post, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("voting_id")) {
          return ApiResponse(ResponseCode.success, int.parse(responseData["voting_id"]));
        }
      }

      //   case "missing_argument":
      //     errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
      //   case "invalid_title":
      //     errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
      //   case "start_after_1900":
      //     errorMessage = "Das Ablaufdatum muss nach dem 01.01.1900 liegen.";
      //   case "invalid_choice_amount":
      //     errorMessage = "Es müssen mindestens 2 Abstimmungsmöglichkeiten hinzugefügt werden.";
      //   case "access_forbidden":
      //   case "insufficient_permissions":
      //     errorMessage = "Du hast nicht die nötigen Berechtigungen um eine Abstimmung in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
      //   default:
      //     errorMessage = "Beim Erstellen der Abstimmung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      print(error);
      //errorMessage = "Beim Erstellen der Abstimmung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ResponseCode> deleteVoting(String calendarID, int votingID) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/voting/${votingID.toString()}", RequestType.delete, null, null, true);

      if (response.statusCode == 200 || response.statusCode == 404) {
        return ResponseCode.success;
      }

      //   case "access_forbidden":
      //   case "insufficient_permissions":
      //     errorMessage = "Du hast nicht die nötigen Berechtigungen um eine Abstimmung in diesem Kalender zu löschen. Bitte wende dich an den Kalenderadministrator";

      return extractResponseCode(response);
    } catch (error) {
      print(error);
      //errorMessage = "Beim Löschen der Abstimmung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return ResponseCode.unknown;
    }
  }

  Future<ResponseCode> vote(String calendarID, int votingID, VoteRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/voting/$votingID/vote", RequestType.post, requestData, null, true);

      if (response.statusCode == 201) {
        return ResponseCode.success;
      }

      //   case "missing_argument":
      //     errorMessage = "Bei der Abstimmung wurde kein ausgewählter Termin oder eine Enthaltung übermittelt.";
      //   case "already_voted":
      //     errorMessage = "Du hast bereits an der Abstimmung teilgenommen.";
      //   case "no_multiple_choice_enabled":
      //     errorMessage = "Eine Mehrfachauswahl ist bei dieser Abstimmung nicht möglich.";
      //   case "voting_not_found":
      //     errorMessage = "Die angefragte Abstimmung konnte nicht gefunden werden.";
      //   case "choice_not_found":
      //     errorMessage = "Mindestens einer der asugewählten Termine konnte nicht gefunden werden oder ist nicht Teil der Abstimmung.";
      //   case "access_forbidden":
      //   case "insufficient_permissions":
      //     errorMessage = "Du hast nicht die nötigen Berechtigungen um an der Abstimmung in diesem Kalender teilzunehmen. Bitte wende dich an den Kalenderadministrator";

      return extractResponseCode(response);
    } catch (error) {
      print(error);
      //errorMessage = "Beim Abstimmen ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return ResponseCode.unknown;
    }
  }
}