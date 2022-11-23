import 'package:de/controllers/ApiController.dart';

class Voting {
  Voting(this.votingID, this.calendarID, this.ownerID, this.title, this.multipleChoice, this.abstentionAllowed, this.userHasVoted, this.numberUsersWhoHaveVoted, this.choices, this.creationDate);

  final int votingID;
  String title;

  bool abstentionAllowed;
  bool multipleChoice;

  bool userHasVoted;
  int numberUsersWhoHaveVoted;

  final String calendarID;
  final String ownerID;

  final DateTime creationDate;

  Map<int, Choice> choices = new Map<int, Choice>();

  Future<void> reload() async {
    Voting reloadedVoting = await Api.loadSingleVoting(calendarID, votingID);

    if (reloadedVoting == null) return;

    if (this.votingID != reloadedVoting.votingID) {
      print("Unexpected Error when reloading Voting, IDs not equal!");
      return;
    }

    this.title = reloadedVoting.title;

    this.abstentionAllowed = reloadedVoting.abstentionAllowed;
    this.multipleChoice = reloadedVoting.multipleChoice;

    this.userHasVoted = reloadedVoting.userHasVoted;
    this.numberUsersWhoHaveVoted = reloadedVoting.numberUsersWhoHaveVoted;
  }
}

class Choice {
  Choice(this.choiceID, this.votingID, this.date, this.comment, this.amountVotes);

  final int choiceID;
  final int votingID;

  DateTime date;
  String comment;
  int amountVotes;
}

class NewVotingRequest {
  NewVotingRequest(this.title, this.multipleChoice, this.abstentionAllowed, this.expiresOn, this.choices);

  final String title;

  final bool multipleChoice;
  final bool abstentionAllowed;

  final DateTime expiresOn;

  final List<NewChoice> choices;
}

class NewChoice {
  NewChoice(this.date, this.comment);

  final DateTime date;
  final String comment;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'comment': comment,
      };
}
