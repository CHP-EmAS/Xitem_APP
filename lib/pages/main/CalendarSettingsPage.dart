import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xitem/controllers/CalendarController.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/controllers/UserController.dart';
import 'package:xitem/models/Calendar.dart';
import 'package:xitem/models/CalendarMember.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/AvatarImageProvider.dart';
import 'package:xitem/utils/CustomScrollBehavior.dart';
import 'package:xitem/widgets/EventColorsNamesAssigner.dart';
import 'package:xitem/widgets/IconPicker.dart';
import 'package:xitem/widgets/buttons/LoadingButton.dart';
import 'package:xitem/widgets/dialogs/CalendarDialog.dart';
import 'package:xitem/widgets/dialogs/PickerDialog.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';
import 'package:xitem/widgets/dialogs/UserDialog.dart';

class CalendarSettingsPage extends StatefulWidget {
  const CalendarSettingsPage(this._linkedCalendarID, this._calendarController, this._userController, {super.key});

  final String _linkedCalendarID;
  final CalendarController _calendarController;
  final UserController _userController;

  @override
  State<StatefulWidget> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> with SingleTickerProviderStateMixin {
  static const TextStyle _textStyle = TextStyle(color: Colors.black, fontFamily: 'Montserrat', fontSize: 20.0);

  Calendar? _linkedCalendar;

  final List<_CombinedMemberData> _memberList = [];
  bool _memberListLoaded = false;

  final _name = TextEditingController();
  final _calendarPassword = TextEditingController();

  bool _canJoin = true;
  bool _alert = true;
  int _currentColor = 0;
  IconData _currentIcon = IconPicker.defaultIcons[0];

  final Map<int, String> _colorLegend = <int, String>{
    13: "TEST",
    2: "TEST 2",
  };
  bool _colorLegendIsOpen = false;

  @override
  void initState() {
    super.initState();

    if (!_getLinkedCalendar()) {
      StateController.navigatorKey.currentState?.pop();
      return;
    }

    _loadMemberList();
  }

  bool _getLinkedCalendar() {
    _linkedCalendar = widget._calendarController.getCalendar(widget._linkedCalendarID);

    _currentColor = _linkedCalendar?.color ?? 0;
    _currentIcon = _linkedCalendar?.icon ?? Icons.error_outline_outlined;

    _name.text = _linkedCalendar?.name ?? "Error";
    _canJoin = _linkedCalendar?.canJoin ?? false;

    return true;
  }

  Future<void> _loadMemberList() async {
    Calendar? linkedCalendar = _linkedCalendar;
    if (linkedCalendar == null) {
      return;
    }

    setState(() {
      _memberListLoaded = false;
      _memberList.clear();
    });

    for (CalendarMember memberData in linkedCalendar.calendarMemberController.getMemberList()) {
      ApiResponse<User> getUser = await widget._userController.getUser(memberData.userID);
      User? userData = getUser.value;

      if (userData == null) {
        continue;
      }

      _memberList.add(_CombinedMemberData(userData, memberData));
    }

    setState(() {
      _memberListLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Calendar? displayedCalendar = _linkedCalendar;
    if (displayedCalendar == null) {
      return const Scaffold();
    }

    bool isOwner = displayedCalendar.calendarMemberController.getCalendarMember(widget._userController.getAuthenticatedUser().id)?.isOwner ?? false;

    final saveLayoutButton = LoadingButton("Layout speichern", "Gespeichert", Colors.amber, _saveLayout);
    final leaveCalendarButton = LoadingButton("Kalender verlassen", "Verlassen", Colors.red, _leaveCalendar);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            StateController.navigatorKey.currentState?.pop();
          },
        ),
        title: Text(
          "'${displayedCalendar.name}' bearbeiten",
          style: TextStyle(
            color: ThemeController.activeTheme().textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        elevation: 3,
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: ScrollConfiguration(
        behavior: const CustomScrollBehavior(false, true),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 15, 30, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            "ID:",
                            style: TextStyle(
                              color: ThemeController.activeTheme().headlineColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                displayedCalendar.name,
                                style: TextStyle(
                                  color: ThemeController.activeTheme().textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                "#${displayedCalendar.hash}",
                                style: TextStyle(
                                  color: ThemeController.activeTheme().globalAccentColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: "ID kopieren",
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: "${displayedCalendar.name}#${displayedCalendar.hash}"));
                              StandardDialog.okDialog("Kalender ID wurde in die Zwischenablage kopiert! ♥", "Mit dieser ID und dem Kalender Passwort können anderen Personen dem Kalender beitreten.");
                            },
                            icon: Icon(
                              Icons.content_copy,
                              color: ThemeController.activeTheme().headlineColor,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Divider(
                      height: 20,
                      color: ThemeController.activeTheme().dividerColor,
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        "Kalender Layout",
                        style: TextStyle(
                          fontSize: 18,
                          color: ThemeController.activeTheme().textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: MaterialButton(
                            onPressed: () {
                              PickerDialog.eventColorPickerDialog(_currentColor).then((selectedColor) {
                                if (selectedColor != null) {
                                  setState(() {
                                    _currentColor = selectedColor;
                                  });
                                }
                              });
                            },
                            color: ThemeController.getEventColor(_currentColor),
                            textColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            shape: const CircleBorder(),
                          ),
                        ),
                        Expanded(
                          flex: 8,
                          child: Text(
                            "Kalender Farbe",
                            style: TextStyle(
                              color: ThemeController.activeTheme().headlineColor,
                              letterSpacing: 2,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: IconButton(
                            icon: Icon(_currentIcon),
                            color: Colors.white70,
                            iconSize: 40,
                            onPressed: () {
                              PickerDialog.iconPickerDialog(_currentIcon).then((selectedIcon) {
                                if (selectedIcon != null) {
                                  setState(() {
                                    _currentIcon = selectedIcon;
                                  });
                                }
                              });
                            },
                          ),
                        ),
                        Expanded(
                          flex: 8,
                          child: Text(
                            "Kalender Icon",
                            style: TextStyle(
                              color: ThemeController.activeTheme().headlineColor,
                              letterSpacing: 2,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: Switch(
                            value: _alert,
                            onChanged: (value) {
                              setState(() {
                                _alert = value;
                              });
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: 8,
                          child: Text(
                            "Benachrichtigungen",
                            style: TextStyle(
                              color: ThemeController.activeTheme().headlineColor,
                              letterSpacing: 2,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    saveLayoutButton,
                    const SizedBox(height: 10),
                    Divider(
                      height: 20,
                      color: ThemeController.activeTheme().dividerColor,
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        "Mitglieder",
                        style: TextStyle(
                          fontSize: 18,
                          color: ThemeController.activeTheme().textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildAssocUserListView(isOwner),
                    const SizedBox(height: 20),
                    leaveCalendarButton,
                    const SizedBox(height: 10),
                    _buildAdminPanel(isOwner),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssocUserListView(bool isOwner) {
    if (!_memberListLoaded) {
      return const Center();
    }

    return SizedBox(
        height: (_memberList.length.toDouble() * 72),
        child: Column(
          children: _memberList.map((member) => _buildAssocUserCard(member, isOwner)).toList(),
        ));
  }

  Widget _buildAssocUserCard(_CombinedMemberData member, bool isOwner) {
    return SizedBox(
      child: Card(
        elevation: 3,
        color: ThemeController.activeTheme().cardColor,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            UserDialog.userInformationPopup(member.userData);
          },
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 21,
              backgroundColor: Colors.transparent,
              backgroundImage: AvatarImageProvider.get(member.userData.avatar),
              child: GestureDetector(
                onTap: () async {
                  UserDialog.profilePictureDialog(member.userData.avatar);
                },
              ),
            ),
            title: Text(
              member.userData.id == widget._userController.getAuthenticatedUser().id ? "Du" : member.userData.name,
              style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 16),
            ),
            subtitle: Text(_getMemberStatusText(member.memberData), style: TextStyle(color: ThemeController.activeTheme().cardSmallInfoColor, fontSize: 14)),
            trailing: _buildAssocUserAdminSettings(member, isOwner),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminPanel(bool isOwner) {
    if (!isOwner) {
      return const Center();
    }

    final nameField = TextField(
      obscureText: false,
      style: _textStyle,
      controller: _name,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Name",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final passwordField = TextField(
      obscureText: false,
      style: _textStyle,
      controller: _calendarPassword,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Passwort",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(
          height: 20,
          color: ThemeController.activeTheme().dividerColor,
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            "Admin Einstellungen",
            style: TextStyle(
              fontSize: 18,
              color: ThemeController.activeTheme().textColor,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "Termin Farben",
          style: TextStyle(
            color: ThemeController.activeTheme().headlineColor,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        ExpansionPanelList(
          expansionCallback: (_, __) {
            setState(() {
              _colorLegendIsOpen = !_colorLegendIsOpen;
            });
          },
          expandedHeaderPadding: EdgeInsets.zero,
          children: [
            ExpansionPanel(
              canTapOnHeader: true,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  leading: Icon(
                    Icons.color_lens_outlined,
                    size: 35,
                    color: ThemeController.activeTheme().iconColor,
                  ),
                  title: const Text(
                    "Farblegende",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                );
              },
              isExpanded: _colorLegendIsOpen,
              body: Column(
                children: [
                  EventColorsNamesAssigner(
                    colorTexts: _colorLegend,
                    onColorTextChange: (colorIndex, text) {
                      setState(() {
                        _colorLegend[colorIndex] = text;
                      });
                    },
                    onColorTextDelete: (colorIndex) {
                      setState(() {
                        _colorLegend.remove(colorIndex);
                      });
                    },
                  ),
                  if(_colorLegend.isNotEmpty)
                    Divider(thickness: 2, color: ThemeController.activeTheme().headlineColor),
                  ListTile(
                    onTap: () async {
                      int? color = await PickerDialog.eventColorPickerDialog(ThemeController.defaultEventColorIndex);
                      if(color == null) {
                        return;
                      }
                      String? text = await StandardDialog.textDialog("Gebe eine Beschreibung für die gewählte Farbe ein", "Beschreibung", null);
                      if(text != null) {
                        setState(() {
                          _colorLegend[color] = text;
                        });
                      }
                    },
                    dense: true,
                    title: const Text("Beschreibung hinzufügen", style: TextStyle(fontSize: 16),),
                    trailing: const Icon(Icons.add, color: Colors.amber),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          "Kalender Name",
          style: TextStyle(
            color: ThemeController.activeTheme().headlineColor,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        nameField,
        const SizedBox(height: 20),
        Text(
          "Neues Passwort",
          style: TextStyle(
            color: ThemeController.activeTheme().headlineColor,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        passwordField,
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Switch(
                value: _canJoin,
                onChanged: (value) {
                  setState(() {
                    _canJoin = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ),
            Expanded(
              flex: 8,
              child: Text(
                "Andere Nutzer können beitreten",
                style: TextStyle(
                  color: ThemeController.activeTheme().headlineColor,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LoadingButton("Einstellungen speichern", "Gespeichert", Colors.amber, _saveInformation),
        const SizedBox(height: 20),
        LoadingButton("Kalender löschen", "Gelöscht", Colors.red, _deleteCalendar),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAssocUserAdminSettings(_CombinedMemberData member, bool isOwner) {
    if (!isOwner) {
      return const Center();
    }

    return SizedBox(
      width: 96,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(0),
            tooltip: "Berechtigungen",
            iconSize: 30,
            icon: Icon(
              Icons.tune,
              color: ThemeController.activeTheme().headlineColor,
            ),
            onPressed: () => _changePermissions(member.memberData),
          ),
          member.userData.id == widget._userController.getAuthenticatedUser().id
              ? const Center()
              : IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(0),
                  tooltip: "Nutzer entfernen",
                  iconSize: 30,
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () => _removeMember(member.userData),
                ),
        ],
      ),
    );
  }

  String _getMemberStatusText(CalendarMember member) {
    if (member.isOwner) return "Kalenderadmin";
    if (member.canEditEvents) return "Moderator";
    if (member.canCreateEvents) return "Mitglied";
    return "Zuschauer";
  }

  Future<void> _changePermissions(CalendarMember memberData) async {
    Calendar? linkedCalendar = _linkedCalendar;
    if (linkedCalendar == null) {
      return;
    }

    List<bool>? changeList = await CalendarDialog.editMemberPopup(memberData);

    if (changeList == null) {
      return;
    }

    StandardDialog.loadingDialog("Speichere Berechtigungen...");

    ResponseCode changePermissions = await linkedCalendar.calendarMemberController.changePermissions(memberData.userID, changeList[0], changeList[1], changeList[2]);

    if (changePermissions != ResponseCode.success) {
      String errorMessage;

      switch (changePermissions) {
        case ResponseCode.insufficientPermissions:
        case ResponseCode.accessForbidden:
          errorMessage = "Du kannst diese Berechtigungen nicht ändern.";
          break;
        case ResponseCode.memberNotFound:
          errorMessage = "Der ausgewählte Nutzer ist nicht Mitglied in diesem Kalender.";
          break;
        case ResponseCode.lastOwner:
          errorMessage = "Du kannst dir nicht die Administrationsrechte nehmen, da du der einzige Administrator bist. Ernenne zuerst einen anderen Administrator.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
      }

      StateController.navigatorKey.currentState?.pop();
      StandardDialog.okDialog("Berechtigungen konnten nicht geändert werden!", errorMessage);
      return;
    }

    setState(() {
      _getLinkedCalendar();
      _loadMemberList();
    });

    StateController.navigatorKey.currentState?.pop();
  }

  Future<void> _removeMember(User userData) async {
    Calendar? linkedCalendar = _linkedCalendar;
    if (linkedCalendar == null) {
      return;
    }

    ConfirmAction? answer = await StandardDialog.confirmDialog("${userData.name} aus diesem Kalender entfernen?",
        "Nach dem Entfernen hat dieser Nutzer keinen Zugriff auf den Kalender mehr. Die Events welche von diesem Nutzer erstellt wurden bleiben jedoch erhalten.");
    if (answer != ConfirmAction.ok) {
      return;
    }

    final String? password = await StandardDialog.passwordDialog();
    if (password == "" || password == null) {
      return;
    }

    StandardDialog.loadingDialog("Entferne Nutzer...");

    ResponseCode removeMember = await linkedCalendar.calendarMemberController.removeAssociatedUsers(userData.id, password);

    if (removeMember != ResponseCode.success) {
      String errorMessage;

      switch (removeMember) {
        case ResponseCode.wrongPassword:
          errorMessage = "Passwort falsch.";
          break;
        case ResponseCode.insufficientPermissions:
        case ResponseCode.accessForbidden:
          errorMessage = "Du bist kein Mitglied in diesem Kalender. ";
          break;
        case ResponseCode.missingArgument:
          errorMessage = "Es wurde kein Passwort angegeben.";
          break;
        case ResponseCode.lastMember:
          errorMessage = "Du kannst diesen Kalender nicht verlassen da du das einzige Mitglied bist. Lösche den Kalender stattdessen.";
          break;
        case ResponseCode.lastOwner:
          errorMessage = "Du kannst diesen Kalender nicht verlassen da du der einzige Administrator bist. Ernenne einen anderen Administrator um den Kalender zu verlassen.";
          break;
        default:
          errorMessage = "Beim Entfernen des Nutzers ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      }

      StateController.navigatorKey.currentState?.pop();
      StandardDialog.okDialog("Nutzer konnte nicht entfernt werden!", errorMessage);
      return;
    }

    setState(() {
      _getLinkedCalendar();
    });

    StateController.navigatorKey.currentState?.pop();
  }

  Future<bool> _saveLayout() async {
    ResponseCode changeLayout = await widget._calendarController.changeCalendarLayout(widget._linkedCalendarID, _currentColor, _currentIcon);

    if (changeLayout != ResponseCode.success) {
      String errorMessage;
      switch (changeLayout) {
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du kannst diese Einstellungen nicht ändern.";
          break;
        case ResponseCode.missingArgument:
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
      }

      StandardDialog.okDialog("Layout konnte nicht gespeichert werden", errorMessage);
      return false;
    }

    setState(() => {_getLinkedCalendar()});
    return true;
  }

  Future<bool> _saveInformation() async {
    ResponseCode changeInfo = await widget._calendarController.changeCalendarInformation(widget._linkedCalendarID, _name.text, _canJoin, _calendarPassword.text);

    if (changeInfo != ResponseCode.success) {
      String errorMessage;

      switch (changeInfo) {
        case ResponseCode.insufficientPermissions:
          errorMessage = "Du kannst diese Einstellungen nicht ändern.";
          break;
        case ResponseCode.invalidTitle:
          errorMessage = "Unzulässiger Name. Zulässige Zeichen: a-z, A-Z, 0-9, Leerzeichen, _, -";
          break;
        case ResponseCode.shortPassword:
          errorMessage = "Das Passwort muss mindestens 6 Zeichen lang sein.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
      }

      StandardDialog.okDialog("Einstellungen konnten nicht gespeichert werden", errorMessage);
      return false;
    }

    setState(() => {_getLinkedCalendar()});
    return true;
  }

  Future<bool> _deleteCalendar() async {
    final answer = await StandardDialog.confirmDialog(
        "Kalender löschen?", "Wenn du diesen Kalender löscht, kann er nicht wieder hergestellt werden! Alle Events werden unwiederruflich gelöscht. Willst du fortfahren?");
    if (answer != ConfirmAction.ok) {
      return false;
    }

    final password = await StandardDialog.passwordDialog();
    if (password == "" || password == null) {
      return false;
    }

    ResponseCode deleteCalendar = await widget._calendarController.deleteCalendar(widget._linkedCalendarID, password);

    if (deleteCalendar != ResponseCode.success) {
      String errorMessage;

      switch (deleteCalendar) {
        case ResponseCode.insufficientPermissions:
        case ResponseCode.accessForbidden:
          errorMessage = "Du kannst diesem Kalender nicht löschen.";
          break;
        case ResponseCode.missingArgument:
          errorMessage = "Es wurde kein Passwort angegeben.";
          break;
        case ResponseCode.wrongPassword:
          errorMessage = "Passwort falsch.";
          break;
        default:
          errorMessage = "Beim Löschen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      }

      StandardDialog.okDialog("Kalendar konnte nicht gelöscht werden!", errorMessage);
      return false;
    }

    StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/home/calendar', (route) => false);
    return true;
  }

  Future<bool> _leaveCalendar() async {
    final answer = await StandardDialog.confirmDialog(
        "Kalender verlassen?", "Wenn du diesen Kalender verlässt, bleiben deine erstellten Events bestehen. Du wirst keinen Zugriff mehr auf den Kalender haben. Willst du fortfahren?");
    if (answer != ConfirmAction.ok) {
      return false;
    }

    final password = await StandardDialog.passwordDialog();
    if (password == "" || password == null) {
      return false;
    }

    ResponseCode leaveCalendar = await widget._calendarController.leaveCalendar(widget._linkedCalendarID, password);

    if (leaveCalendar != ResponseCode.success) {
      String errorMessage;

      switch (leaveCalendar) {
        case ResponseCode.insufficientPermissions:
        case ResponseCode.accessForbidden:
          errorMessage = "Du bist kein Mitglied in diesem Kalender.";
          break;
        case ResponseCode.missingArgument:
          errorMessage = "Es wurde kein Passwort angegeben.";
          break;
        case ResponseCode.wrongPassword:
          errorMessage = "Passwort falsch.";
          break;
        case ResponseCode.lastMember:
          errorMessage = "Du kannst diesen Kalender nicht verlassen da du das einzige Mitglied bist. Lösche den Kalender stattdessen.";
          break;
        case ResponseCode.lastOwner:
          errorMessage = "Du kannst diesen Kalender nicht verlassen da du der einzige Administrator bist. Ernenne einen anderen Administrator um den Kalender zu verlassen.";
          break;
        default:
          errorMessage = "Beim Verlassen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      }

      StandardDialog.okDialog("Kalendar konnte nicht verlassen werden!", errorMessage);
      return false;
    }

    StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/home/calendar', (route) => false);
    return true;
  }
}

class _CombinedMemberData {
  _CombinedMemberData(this.userData, this.memberData);

  final User userData;
  final CalendarMember memberData;
}
