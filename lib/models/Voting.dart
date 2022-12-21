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

  Map<int, Choice> choices = <int, Choice>{};
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
