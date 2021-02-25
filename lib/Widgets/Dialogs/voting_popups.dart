import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Models/User.dart';
import 'package:de/Models/Voting.dart';
import 'package:de/Settings/custom_scroll_behavior.dart';
import 'package:de/Settings/locator.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VotingPopup {
  static final NavigationService _navigationService = locator<NavigationService>();

  static Future<NewVotingRequest> createVotingPopup() {
    return showDialog(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          final TextEditingController _title = TextEditingController();

          bool _abstentionAllowed = false;
          bool _multipleChoice = false;

          DateTime _expiresOn;

          DynamicChoiceList choiceListWidget = DynamicChoiceList();

          return ScrollConfiguration(
            behavior: CustomScrollBehavior(false, false),
            child: AlertDialog(
              contentPadding: EdgeInsets.fromLTRB(24, 5, 24, 0),
              backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
              scrollable: true,
              title: Center(child: Text("Abstimmung starten")),
              content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return Container(
                  height: 528,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: _title,
                        decoration: InputDecoration(hintText: "Abstimmungstitel"),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Wahlmöglichkeiten",
                        style: TextStyle(fontSize: 15),
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      Container(
                        height: 327,
                        width: 300,
                        child: choiceListWidget,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Divider(
                        height: 15,
                        thickness: 2,
                        color: ThemeController.activeTheme().dividerColor,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: Switch(
                              value: _multipleChoice,
                              onChanged: (value) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _multipleChoice = value;
                                });
                              },
                              activeTrackColor: Colors.lightGreenAccent,
                              activeColor: Colors.green,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Mehrfachauswahl zulassen",
                              style: TextStyle(color: ThemeController.activeTheme().headlineColor, letterSpacing: 2),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: Switch(
                              value: _abstentionAllowed,
                              onChanged: (value) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _abstentionAllowed = value;
                                });
                              },
                              activeTrackColor: Colors.lightGreenAccent,
                              activeColor: Colors.green,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Enthaltung zulassen",
                              style: TextStyle(color: ThemeController.activeTheme().headlineColor, letterSpacing: 2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              elevation: 3,
              actions: <Widget>[
                new FlatButton(
                  child: new Text('Starten', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                  onPressed: () {
                    NewVotingRequest votingRequest = new NewVotingRequest(_title.text, _multipleChoice, _abstentionAllowed, _expiresOn, choiceListWidget.getChoices());

                    _navigationService.pop(votingRequest);
                  },
                ),
                new FlatButton(
                  child: new Text('Abbrechen', style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                  onPressed: () {
                    _navigationService.pop(null);
                  },
                ),
              ],
            ),
          );
        });
  }

  static Future<List<int>> showVotingInformationPopup(Voting voting) async {
    return showDialog(
        context: _navigationService.navigatorKey.currentContext,
        builder: (BuildContext context) {
          if (!UserController.calendarList.containsKey(voting.calendarID)) {
            DialogPopup.asyncOkDialog("Unerwarteter Fehler", "Zugehöriger Kalender konnte nicht gefunden werden!");
            _navigationService.pop(null);
          }

          Calendar _calendar = UserController.calendarList[voting.calendarID];

          final String _title = voting.title;

          final bool _canVote = !voting.userHasVoted;
          final bool _abstentionAllowed = voting.abstentionAllowed;
          final bool _multipleChoice = voting.multipleChoice;

          final String _ownerID = voting.ownerID;
          PublicUser creatorData = UserController.getPublicUserInformation(_ownerID);
          if (creatorData == null) {
            creatorData = UserController.unknownUser;
          }

          final creationDateFormat = new DateFormat.yMMMMd("de_DE");

          final ChoiceContainerList choiceContainerList = new ChoiceContainerList(voting.choices.values.toList(), _multipleChoice, _abstentionAllowed, _canVote);

          return ScrollConfiguration(
            behavior: CustomScrollBehavior(false, false),
            child: AlertDialog(
              elevation: 5,
              titlePadding: EdgeInsets.fromLTRB(0, 15, 0, 0),
              title: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 17,
                  ),
                  Divider(
                    color: Colors.white,
                    height: 0,
                    thickness: 3,
                  ),
                ],
              ),
              scrollable: true,
              backgroundColor: ThemeController.activeTheme().infoDialogBackgroundColor,
              content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Container(
                  width: 300,
                  child: choiceContainerList,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 30,
                      color: ThemeController.activeTheme().iconColor,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          _calendar.icon,
                          color: _calendar.color,
                          size: 30,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          _calendar.name,
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Icon(
                    Icons.person,
                    size: 30,
                    color: ThemeController.activeTheme().iconColor,
                  ),
                  GestureDetector(
                    onTap: () async {
                      DialogPopup.asyncUserInformationPopup(creatorData.userID);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          creatorData.name,
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          backgroundImage: creatorData.avatar != null ? FileImage(creatorData.avatar) : AssetImage("images/avatar.png"),
                        ),
                      ],
                    ),
                  ),
                ]),
                SizedBox(
                  height: 5,
                ),
                Divider(
                  color: ThemeController.activeTheme().dividerColor,
                  height: 10,
                  thickness: 2,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Gestartet am: " + creationDateFormat.format(voting.creationDate),
                      style: TextStyle(
                        color: ThemeController.activeTheme().textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ]),
              contentPadding: EdgeInsets.fromLTRB(25, 25, 25, 5),
              actionsPadding: EdgeInsets.zero,
              actions: <Widget>[
                _canVote
                    ? new FlatButton(
                        child: new Text("Abstimmen", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                        onPressed: () {
                          List<int> votes = choiceContainerList.getVotes();

                          if (votes.isEmpty) {
                            DialogPopup.asyncOkDialog("Kein Termin ausgewählt", "Bei dieser Abstimmung muss mindestens ein Termin ausgewählt werden.");
                          } else {
                            _navigationService.pop(votes);
                          }
                        },
                      )
                    : Center(),
                new FlatButton(
                  child: new Text("Schließen", style: TextStyle(color: ThemeController.activeTheme().globalAccentColor, fontSize: 18)),
                  onPressed: () {
                    _navigationService.pop();
                  },
                ),
              ],
            ),
          );
        });
  }
}

class DynamicChoiceList extends StatefulWidget {
  final DynamicChoiceListState _dcls = new DynamicChoiceListState();

  @override
  DynamicChoiceListState createState() {
    return _dcls;
  }

  List<NewChoice> getChoices() {
    if (_dcls != null)
      return _dcls._choices;
    else
      return null;
  }
}

class DynamicChoiceListState extends State<DynamicChoiceList> {
  // The GlobalKey keeps track of the visible state of the list items
  // while they are being animated.
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  // backing data
  List<NewChoice> _choices = [];

  final dateFormat = new DateFormat("E d. MMMM y", "de_DE");
  final timeFormat = new DateFormat.Hm('de_DE');

  DateTime _selectedDate = DateTime.now();
  final TextEditingController _selectedComment = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Divider(
          height: 2,
          thickness: 2,
        ),
        Container(
          height: 170,
          color: Color.fromRGBO(50, 50, 50, 0.5),
          child: ScrollConfiguration(
            behavior: CustomScrollBehavior(true, true),
            child: Stack(
              children: [
                (_choices.length > 0)
                    ? Center()
                    : Center(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Text(
                            "Füge eine neue Wahlmöglichkeit mit '+' hinzu.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                AnimatedList(
                  // Give the Animated list the global key
                  key: _listKey,
                  initialItemCount: _choices.length,
                  // Similar to ListView itemBuilder, but AnimatedList has
                  // an additional animation parameter.
                  itemBuilder: (context, index, animation) {
                    // Breaking the row widget out as a method so that we can
                    // share it with the _removeSingleItem() method.
                    return _buildItem(_choices[index], index, animation);
                  },
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 2,
          thickness: 2,
        ),
        SizedBox(
          height: 15,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                    child: Row(
                      children: [
                        Icon(Icons.event),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          dateFormat.format(_selectedDate),
                          style: TextStyle(
                            color: ThemeController.activeTheme().textColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    FocusScope.of(context).unfocus();

                    showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(1900, 1, 1), lastDate: DateTime(2200, 12, 31)).then((selectedDate) {
                      if (selectedDate == null) return;

                      setState(() {
                        _selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, _selectedDate.hour, _selectedDate.minute);
                      });
                    });
                  },
                ),
                InkWell(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(0, 5, 2, 5),
                      child: Row(
                        children: [
                          Icon(Icons.access_time),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            timeFormat.format(_selectedDate),
                            style: TextStyle(
                              color: ThemeController.activeTheme().textColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();

                      DialogPopup.asyncTimeSliderDialog(TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute)).then((selectedTime) {
                        if (selectedTime != null) {
                          setState(() {
                            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, selectedTime.hour, selectedTime.minute);
                          });
                        }
                      });
                    }),
              ],
            ),
          ),
          Container(
            height: 65,
            width: 65,
            child: IconButton(
              icon: Icon(
                Icons.add,
                size: 50,
                color: Colors.amber,
              ),
              tooltip: "Wahlmöglichkeit hinzufügen",
              onPressed: () {
                FocusScope.of(context).unfocus();

                _insertSingleItem(_selectedDate, _selectedComment.text);
                _selectedComment.clear();
              },
            ),
          ),
        ]),
        TextField(
          maxLength: 30,
          controller: _selectedComment,
          decoration: InputDecoration(hintText: "Kommentar", helperText: "Kommentar für Wahlmöglichkeit"),
        ),
      ],
    );
  }

  // This is the animated row with the Card.
  Widget _buildItem(NewChoice choice, int index, Animation animation) {
    return SizeTransition(sizeFactor: animation, child: _buildCard(choice, index));
  }

  Widget _buildCard(NewChoice choice, int index) {
    if (choice.comment == "" || choice.comment == null)
      return Card(
        child: ListTile(
          dense: true,
          title: Text(
            dateFormat.format(choice.date) + "\n" + timeFormat.format(choice.date) + " Uhr",
            style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 14),
          ),
          trailing: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.all(0),
              tooltip: "Auswahl entfernen",
              iconSize: 30,
              icon: Icon(Icons.clear, color: Colors.red),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                _removeSingleItem(index);
              }),
        ),
      );

    return Card(
      child: ListTile(
        isThreeLine: (choice.comment == "") ? false : true,
        dense: true,
        title: Text(
          dateFormat.format(choice.date) + "\n" + timeFormat.format(choice.date) + " Uhr",
          style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 14),
        ),
        subtitle: Text(
          choice.comment,
          style: TextStyle(color: ThemeController.activeTheme().cardSmallInfoColor, fontSize: 12),
        ),
        trailing: IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.all(0),
            tooltip: "Auswahl entfernen",
            iconSize: 30,
            icon: Icon(Icons.clear, color: Colors.red),
            onPressed: () async {
              _removeSingleItem(index);
            }),
      ),
    );
  }

  void _insertSingleItem(DateTime date, String comment) {
    setState(() {
      _choices.insert(0, new NewChoice(date, comment));
      _listKey.currentState.insertItem(0);
    });
  }

  void _removeSingleItem(int index) {
    setState(() {
      NewChoice removedItem = _choices.removeAt(index);
      AnimatedListRemovedItemBuilder builder = (context, animation) {
        return _buildItem(removedItem, index, animation);
      };
      _listKey.currentState.removeItem(index, builder);
    });
  }
}

class ChoiceContainerList extends StatefulWidget {
  ChoiceContainerList(List<Choice> selectableChoices, bool multipleChoice, bool abstentionAllowed, bool canVote)
      : this._ccls = new ChoiceContainerListState(selectableChoices, multipleChoice, abstentionAllowed, canVote);

  final ChoiceContainerListState _ccls;

  @override
  ChoiceContainerListState createState() {
    return _ccls;
  }

  List<int> getVotes() {
    if (_ccls != null)
      return _ccls.getVotes();
    else
      return null;
  }
}

class ChoiceContainerListState extends State<ChoiceContainerList> {
  ChoiceContainerListState(this._selectableChoices, this._multipleChoice, this._abstentionAllowed, this._canVote) : _selectedChoiceID = _selectableChoices[0].choiceID;

  // backing data
  final List<Choice> _selectableChoices;

  final bool _multipleChoice;
  final bool _abstentionAllowed;

  final bool _canVote;

  //for multiple choice
  List<int> _selectedChoices = new List<int>();

  //for single choice
  int _selectedChoiceID;

  //abstention choice id
  int abstentionChoiceID;

  final _dateFormat = new DateFormat("E d. MMMM y", "de_DE");
  final _timeFormat = new DateFormat.Hm('de_DE');

  @override
  void initState() {
    //remove abstention when abstention allowed and multipleChoice is active || dont remove if _canVote is false
    //none selected date is counting as abstention
    if (_abstentionAllowed && _multipleChoice && _canVote) {
      for (final choice in _selectableChoices) {
        if (choice.date == null) {
          abstentionChoiceID = choice.choiceID;
          _selectableChoices.remove(choice);
          break;
        }
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(_canVote ? (_multipleChoice ? "Stimme für mehrere Termine ab" : "Stimme für ein Termin ab") : "Übersicht der Stimmenverteilung"),
        SizedBox(
          height: 5,
        ),
        Divider(
          height: 2,
          thickness: 2,
        ),
        Container(
          height: 220,
          color: Color.fromRGBO(50, 50, 50, 0.5),
          child: ScrollConfiguration(
              behavior: CustomScrollBehavior(true, true),
              child: ListView.builder(
                itemCount: _selectableChoices.length,
                itemBuilder: _buildItemsForListView,
              )),
        ),
        Divider(
          height: 2,
          thickness: 2,
        ),
        SizedBox(
          height: 3,
        ),
        (_multipleChoice && _abstentionAllowed)
            ? Text(
                "Enthaltung möglich",
                style: TextStyle(fontSize: 13),
              )
            : Center(),
      ],
    );
  }

  //calculate the selected votes
  //if multiple choice and abstention is enable proof if any choice is selected, if not add the id of the abstention choice
  //if multiple choice is not enabled return the selected choice <-- the abstention choice is selectable if enabled
  //if can vote is disabled return empty list / returns empty list if nothing is selected (only possible in multiple choice)
  List<int> getVotes() {
    List<int> votesList = new List<int>();

    if (_canVote) {
      if (_multipleChoice) {
        if (_selectedChoices.isEmpty) {
          if (_abstentionAllowed) {
            print("# " + abstentionChoiceID.toString());
            votesList.add(abstentionChoiceID);
          }
        } else {
          return _selectedChoices;
        }
      } else {
        votesList.add(_selectedChoiceID);
      }
    }

    return votesList;
  }

  Widget _buildItemsForListView(BuildContext context, int index) {
    return _buildCard(_selectableChoices[index], index);
  }

  Widget _buildCard(Choice choice, int index) {
    String dateText = "";
    String commentText = "";

    if (choice.date != null) {
      dateText = _dateFormat.format(choice.date) + "\n" + _timeFormat.format(choice.date) + " Uhr";
      commentText = choice.comment;
    } else {
      if (_canVote)
        dateText = "Enthalten";
      else
        dateText = "Enthaltungen";
    }

    if (commentText == "" || commentText == null)
      return Card(
        child: ListTile(
          dense: true,
          title: Text(
            dateText,
            style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 14),
          ),
          trailing: _buildTrailingWidget(index),
          onTap: () {
            setState(() {
              if (_canVote) {
                if (_multipleChoice) {
                  setSelection(choice.choiceID);
                } else {
                  switchSelection(choice.choiceID);
                }
              }
            });
          },
        ),
      );

    return Card(
      child: ListTile(
        isThreeLine: true,
        dense: true,
        title: Text(
          dateText,
          style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 14),
        ),
        subtitle: Text(
          choice.comment,
          style: TextStyle(color: ThemeController.activeTheme().cardSmallInfoColor, fontSize: 12),
        ),
        trailing: _buildTrailingWidget(index),
        onTap: () {
          setState(() {
            if (_canVote) {
              if (_multipleChoice) {
                setSelection(choice.choiceID);
              } else {
                switchSelection(choice.choiceID);
              }
            }
          });
        },
      ),
    );
  }

  Widget _buildTrailingWidget(int index) {
    if (!_canVote) {
      return Text(_selectableChoices[index].amountVotes.toString() + " Stimmen");
    } else if (_multipleChoice) {
      return Checkbox(
          activeColor: ThemeController.activeTheme().globalAccentColor,
          value: _selectedChoices.contains(_selectableChoices[index].choiceID),
          onChanged: (bool _value) {
            setState(() {
              setSelection(_selectableChoices[index].choiceID);
            });
          });
    } else {
      return Radio(
          activeColor: ThemeController.activeTheme().globalAccentColor,
          value: _selectableChoices[index].choiceID,
          groupValue: _selectedChoiceID,
          onChanged: (int _value) {
            setState(() {
              switchSelection(_value);
            });
          });
    }
  }

  void switchSelection(int choiceID) {
    _selectedChoiceID = choiceID;
  }

  void setSelection(int choiceID) {
    if (_selectedChoices.contains(choiceID))
      _selectedChoices.remove(choiceID);
    else
      _selectedChoices.add(choiceID);
  }
}
