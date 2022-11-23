import 'dart:async';

import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Models/Member.dart';
import 'package:de/Models/User.dart';
import 'package:de/Utils/custom_scroll_behavior.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/Dialogs/picker_popups.dart';
import 'package:de/Widgets/buttons/loading_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../Widgets/icon_picker_widget.dart';

class CalendarSettingsScreen extends StatefulWidget {
  const CalendarSettingsScreen({Key key, @required this.linkedCalendar});

  final Calendar linkedCalendar;

  @override
  State<StatefulWidget> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends State<CalendarSettingsScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _canJoin = true;

  bool _alert = true;

  Color _currentColor = Colors.amber;
  IconData _currentIcon = default_icons[0];

  void changeIcon(IconData icon) => setState(() => _currentIcon = icon);

  @override
  void initState() {
    super.initState();

    _currentColor = widget.linkedCalendar.color;
    _currentIcon = widget.linkedCalendar.icon;

    _name.text = widget.linkedCalendar.name;
    _canJoin = widget.linkedCalendar.canJoin;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onRefresh() async {
    bool reloadCompleted = await widget.linkedCalendar.reload();

    if (reloadCompleted) {
      setState(() {});
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = TextStyle(color: Colors.black, fontFamily: 'Montserrat', fontSize: 20.0);

    final saveLayoutButton = LoadingButton("Layout speichern", "Gespeichert", Colors.amber, () async {
      if (await widget.linkedCalendar.changeCalendarLayout(_currentColor, _currentIcon)) {
        setState(() => {});
        return true;
      } else {
        DialogPopup.asyncOkDialog("Layout konnte nicht gespeichert werden", Api.errorMessage);
        return false;
      }
    });

    final saveInformationButton = LoadingButton("Einstellungen speichern", "Gespeichert", Colors.amber, () async {
      if (await widget.linkedCalendar.changeCalendarInformation(_name.text, _canJoin, _password.text)) {
        setState(() {
          widget.linkedCalendar.name = _name.text;
        });
        return true;
      } else {
        DialogPopup.asyncOkDialog("Einstellungen konnten nicht gespeichert werden", Api.errorMessage);
        return false;
      }
    });

    final deleteCalendarButton = LoadingButton("Kalender löschen", "Gelöscht", Colors.red, () async {
      final answer = await DialogPopup.asyncConfirmDialog(
          "Kalender löschen?", "Wenn du diesen Kalender löscht, kann er nicht wieder hergestellt werden! Alle Events werden unwiederruflich gelöscht. Willst du fortfahren?");

      if (answer == ConfirmAction.OK) {
        final password = await DialogPopup.asyncPasswordDialog();

        if (password != "" && password != null) {
          if (await UserController.deleteCalendar(widget.linkedCalendar.id, password)) {
            Navigator.pushNamedAndRemoveUntil(context, '/home/calendar', (route) => false);
            return false;
          } else {
            DialogPopup.asyncOkDialog("Kalendar konnte nicht gelöscht werden!", Api.errorMessage);
          }
        }
      }

      return false;
    });

    final leaveCalendarButton = LoadingButton("Kalender verlassen", "Verlassen", Colors.red, () async {
      final answer = await DialogPopup.asyncConfirmDialog(
          "Kalender verlassen?", "Wenn du diesen Kalender verlässt, bleiben deine erstellten Events bestehen. Du wirst keinen Zugriff mehr auf den Kalender haben. Willst du fortfahren?");

      if (answer == ConfirmAction.OK) {
        final password = await DialogPopup.asyncPasswordDialog();

        if (password != "" && password != null) {
          if (await UserController.leaveCalendar(widget.linkedCalendar.id, password)) {
            Navigator.pushNamedAndRemoveUntil(context, '/home/calendar', (route) => false);
            return false;
          } else {
            DialogPopup.asyncOkDialog("Kalendar konnte nicht verlassen werden!", Api.errorMessage);
          }
        }
      }
      return false;
    });

    final nameField = TextField(
      obscureText: false,
      style: style,
      controller: _name,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Name",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final passwordField = TextField(
      obscureText: false,
      style: style,
      controller: _password,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Passwort",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    Widget buildAdminPanel() {
      if (widget.linkedCalendar.isOwner) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Divider(
              height: 20,
              color: ThemeController.activeTheme().dividerColor,
            ),
            SizedBox(height: 5),
            Center(
              child: Text(
                "Admin Einstellungen",
                style: TextStyle(
                  fontSize: 18,
                  color: ThemeController.activeTheme().textColor,
                ),
              ),
            ),
            SizedBox(height: 15),
            Text(
              "Kalender Name",
              style: TextStyle(
                color: ThemeController.activeTheme().headlineColor,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 10),
            nameField,
            SizedBox(height: 20),
            Text(
              "Neues Passwort",
              style: TextStyle(
                color: ThemeController.activeTheme().headlineColor,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 10),
            passwordField,
            SizedBox(height: 20),
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
            SizedBox(height: 10),
            saveInformationButton,
            SizedBox(height: 20),
            deleteCalendarButton,
            SizedBox(height: 10),
          ],
        );
      }

      return Center();
    }

    String _getMemberStatusText(AssociatedUser member) {
      if (member.isOwner) return "Kalenderadmin";
      if (member.canEditEvents) return "Moderator";
      if (member.canCreateEvents) return "Mitglied";
      return "Zuschauer";
    }

    Widget _buildAssocUserAdminSettings(AssociatedUser member) {
      if (!widget.linkedCalendar.isOwner)
        return SizedBox(
          height: 0,
          width: 0,
        );

      PublicUser memberData = UserController.getPublicUserInformation(member.userID);
      if (memberData == null) {
        memberData = UserController.unknownUser;
      }

      return Container(
        width: 96,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.all(0),
              tooltip: "Berechtigungen",
              iconSize: 30,
              icon: Icon(
                Icons.tune,
                color: ThemeController.activeTheme().headlineColor,
              ),
              onPressed: () {
                DialogPopup.asyncEditMemberPopup(widget.linkedCalendar.id, member).then((List<bool> changeList) {
                  if (changeList != null) {
                    DialogPopup.asyncLoadingDialog(_keyLoader, "Speichere Berechtigungen...");
                    member.changePermissions(changeList[0], changeList[1], changeList[2]).then((success) {
                      Future.delayed(const Duration(seconds: 1)).then((value) {
                        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
                        if (!success) {
                          DialogPopup.asyncOkDialog("Berechtigungen konnten nicht geändert werden!", Api.errorMessage);
                        } else {
                          widget.linkedCalendar.sortAssociatedUsers();
                          setState(() {});
                        }
                      });
                    });
                  }
                });
              },
            ),
            member.userID == UserController.user.userID
                ? Center()
                : IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.all(0),
                    tooltip: "Nutzer entfernen",
                    iconSize: 30,
                    icon: Icon(Icons.clear, color: Colors.red),
                    onPressed: () async {
                      ConfirmAction answer = await DialogPopup.asyncConfirmDialog(memberData.name + " aus Kalender entfernen?",
                          "Nach dem Entfernen hat dieser Nutzer keinen Zugriff auf den Kalender mehr. Die Events welche von diesem Nutzer erstellt wurden bleiben jedoch erhalten.");
                      if (answer == ConfirmAction.OK) {
                        final password = await DialogPopup.asyncPasswordDialog();

                        if (password != "") {
                          DialogPopup.asyncLoadingDialog(_keyLoader, "Entferne Nutzer...");
                          bool removed = await widget.linkedCalendar.removeAssociatedUsers(member.userID, password);
                          await Future.delayed(const Duration(seconds: 1));
                          Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
                          if (removed) {
                            widget.linkedCalendar.sortAssociatedUsers();
                            setState(() {});
                          } else {
                            DialogPopup.asyncOkDialog("Nutzer konnte nicht entfernt werden!", Api.errorMessage);
                          }
                        }
                      }
                    },
                  ),
          ],
        ),
      );
    }

    Widget _buildAssocUserCard(AssociatedUser member) {
      PublicUser memberData = UserController.getPublicUserInformation(member.userID);
      if (memberData == null) {
        memberData = UserController.unknownUser;
      }

      return SizedBox(
        child: Card(
          elevation: 3,
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              DialogPopup.asyncUserInformationPopup(member.userID);
            },
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 21,
                backgroundColor: Colors.transparent,
                backgroundImage: memberData.avatar != null ? FileImage(memberData.avatar) : AssetImage("images/avatar.png"),
                child: GestureDetector(
                  onTap: () async {
                    DialogPopup.asyncProfilePictureDialog(member.userID);
                  },
                ),
              ),
              title: Text(
                member.userID == UserController.user.userID ? "Du" : memberData.name,
                style: TextStyle(color: ThemeController.activeTheme().cardInfoColor, fontSize: 16),
              ),
              subtitle: Text(_getMemberStatusText(member), style: TextStyle(color: ThemeController.activeTheme().cardSmallInfoColor, fontSize: 14)),
              trailing: _buildAssocUserAdminSettings(member),
            ),
          ),
          color: ThemeController.activeTheme().cardColor,
        ),
      );
    }

    Widget _buildAssocUserListView() {
      return Column(
        children: widget.linkedCalendar.assocUserList.map((member) => _buildAssocUserCard(member)).toList(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "'" + widget.linkedCalendar.name + "' bearbeiten",
          style: TextStyle(
            color: ThemeController.activeTheme().textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        elevation: 3,
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: Center(
          child: Container(
        child: ScrollConfiguration(
          behavior: CustomScrollBehavior(false, true),
          child: SmartRefresher(
            header: WaterDropMaterialHeader(
              color: ThemeController.activeTheme().actionButtonColor,
              backgroundColor: ThemeController.activeTheme().foregroundColor,
            ),
            controller: _refreshController,
            onRefresh: _onRefresh,
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 15, 30, 0),
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
                                  widget.linkedCalendar.name,
                                  style: TextStyle(
                                    color: ThemeController.activeTheme().textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  "#" + widget.linkedCalendar.hash,
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
                                Clipboard.setData(ClipboardData(text: widget.linkedCalendar.name + "#" + widget.linkedCalendar.hash));
                                DialogPopup.asyncOkDialog(
                                    "Kalender ID wurde in die Zwischenablage kopiert! ♥", "Mit dieser ID und dem Kalender Passwort können anderen Personen dem Kalender beitreten.");
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
                      SizedBox(height: 5),
                      Divider(
                        height: 20,
                        color: ThemeController.activeTheme().dividerColor,
                      ),
                      SizedBox(height: 5),
                      Center(
                        child: Text(
                          "Kalender Layout",
                          style: TextStyle(
                            fontSize: 18,
                            color: ThemeController.activeTheme().textColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: MaterialButton(
                              onPressed: () {
                                PickerPopup.showColorPickerDialog(_currentColor).then((selectedColor) {
                                  if (selectedColor != null) {
                                    setState(() {
                                      _currentColor = selectedColor;
                                    });
                                  }
                                });
                              },
                              color: _currentColor,
                              textColor: Colors.white,
                              padding: EdgeInsets.all(16),
                              shape: CircleBorder(),
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
                      SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: IconButton(
                              icon: Icon(_currentIcon),
                              color: Colors.white70,
                              iconSize: 40,
                              onPressed: () {
                                PickerPopup.showIconPickerDialog(_currentIcon).then((selectedIcon) {
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
                      SizedBox(height: 10),
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
                      SizedBox(height: 10),
                      saveLayoutButton,
                      SizedBox(height: 10),
                      Divider(
                        height: 20,
                        color: ThemeController.activeTheme().dividerColor,
                      ),
                      SizedBox(height: 5),
                      Center(
                        child: Text(
                          "Mitglieder",
                          style: TextStyle(
                            fontSize: 18,
                            color: ThemeController.activeTheme().textColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(height: (widget.linkedCalendar.assocUserList.length.toDouble() * 72), child: _buildAssocUserListView()),
                      SizedBox(height: 20),
                      leaveCalendarButton,
                      SizedBox(height: 10),
                      buildAdminPanel(),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
