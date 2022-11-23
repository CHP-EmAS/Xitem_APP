import 'dart:io';

import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Interfaces/api_interfaces.dart';
import 'file:///C:/Users/Clemens/Documents/AndroidStudioProjects/live_list/lib/Controller/locator.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/buttons/loading_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen();

  @override
  State<StatefulWidget> createState() {
    return _EditProfileScreenState();
  }
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final NavigationService _navigationService = locator<NavigationService>();
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();

  final _name = TextEditingController();

  final _birthdayText = TextEditingController();
  final birthdayFormat = new DateFormat.yMMMMd('de_DE');
  DateTime _birthday;

  void initState() {
    if (UserController.user.name != null) {
      _name.text = UserController.user.name;
    }

    if (UserController.user.birthday != null) {
      _birthdayText.text = birthdayFormat.format(UserController.user.birthday);
      _birthday = UserController.user.birthday;
    }

    super.initState();
  }

  File _newAvatarImage;
  File _pickedImage;
  ImagePicker picker = new ImagePicker();

  Future<bool> _pickImage() async {
    _pickedImage = null;
    final pickedImage = await picker.getImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      _pickedImage = File(pickedImage.path);
      return true;
    }

    return false;
  }

  Future<bool> _cropImage() async {
    final File croppedFile = await ImageCropper.cropImage(
      sourcePath: _pickedImage.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      androidUiSettings:
          AndroidUiSettings(toolbarTitle: 'Profilbild anpassen', toolbarColor: Colors.amber, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
      iosUiSettings: IOSUiSettings(
        title: 'Profilbild anpassen',
      ),
      compressFormat: ImageCompressFormat.png,
    );

    if (croppedFile != null) {
      _newAvatarImage = croppedFile;
      return true;
    }

    return false;
  }

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        errorFormatText: "Ungültiges Format",
        helpText: "Geburtstag auswählen",
        initialDatePickerMode: DatePickerMode.year,
        useRootNavigator: false,
        initialDate: DateTime.now(),
        firstDate: DateTime(1901, 1),
        lastDate: DateTime.now(),
        locale: Locale('de', 'DE'));
    if (picked != null && picked != _birthday) {
      _birthday = picked;
      setState(() {
        _birthdayText.text = birthdayFormat.format(picked);
      });
    }
  }

  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _repeatPassword = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.black);

    imageCache.clear();

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

    final birthdayField = GestureDetector(
      onTap: (() {
        FocusScope.of(context).unfocus();
        _selectDate(context);
      }),
      child: AbsorbPointer(
        child: TextField(
          obscureText: false,
          style: style,
          controller: _birthdayText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
            hintText: "Geburtstag",
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
            suffixIcon: Icon(
              Icons.calendar_today,
              color: Colors.grey[800],
            ),
          ),
        ),
      ),
    );

    final saveProfileButton = LoadingButton("Speichern", "Gespeichert", Colors.amber, () async {
      FocusScope.of(context).unfocus();

      return await UserController.changeUserInformation(_name.text, _birthday).then((registerSuccess) async {
        if (registerSuccess) {
          await DialogPopup.asyncOkDialog("Änderungen gespeichert", "Die Änderungen wurden erfolgreich an Xitem übermittlet");
          return true;
        } else {
          await DialogPopup.asyncOkDialog("Änderungen konnten nicht gespeichert werden!", Api.errorMessage);
          return false;
        }
      });
    });

    final oldPasswordField = TextField(
      obscureText: true,
      style: style,
      controller: _oldPassword,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Altes Passwort",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final newPasswordField = TextField(
      obscureText: true,
      style: style,
      controller: _newPassword,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Neues Passwort",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final repeatPasswordField = TextField(
      obscureText: true,
      style: style,
      controller: _repeatPassword,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Neues Passwort wiederholen",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final changePasswordButton = LoadingButton("Passwort ändern", "Passwort gespeichert", Colors.amber, () async {
      FocusScope.of(context).unfocus();

      if (_oldPassword.text == "" || _newPassword.text == "" || _repeatPassword.text == "") return false;

      return await Api.changePassword(ChangePasswordRequest(_oldPassword.text, _newPassword.text, _repeatPassword.text)).then((success) async {
        if (success) {
          await DialogPopup.asyncOkDialog("Passwort geändert", "Die Änderungen wurden erfolgreich an Xitem übermittelt. Bitte melde dich erneut an.");
          UserController.logout();
          return true;
        } else {
          await DialogPopup.asyncOkDialog("Passwort konnten nicht gespeichert werden!", Api.errorMessage);
          return false;
        }
      });
    });

    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            color: ThemeController.activeTheme().iconColor,
            onPressed: () {
              _navigationService.pop();
            },
          ),
          title: Text(
            "Account bearbeiten",
            style: TextStyle(color: ThemeController.activeTheme().textColor),
          ),
          centerTitle: true,
          backgroundColor: ThemeController.activeTheme().foregroundColor,
          elevation: 3,
        ),
        backgroundColor: ThemeController.activeTheme().backgroundColor,
        body: Center(
            child: Container(
          child: ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(30, 40, 30, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          bool imagePicked = await _pickImage();
                          if (imagePicked) {
                            bool imageCopped = await _cropImage();

                            if (!imageCopped) {
                              setState(() {
                                DialogPopup.asyncOkDialog("Profilbild konnte nicht geändert werden!", "Es ist ein Fehler während der Bildauswahl aufgetreten, bitte versuch es erneut.");
                                _newAvatarImage = null;
                              });
                            } else {
                              DialogPopup.asyncLoadingDialog(_keyLoader, "Speichere Profilbild...");

                              if (_newAvatarImage != null) {
                                bool success = await UserController.changeAvatar(_newAvatarImage).catchError((e) {
                                  Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
                                  return false;
                                });

                                await Future.delayed(const Duration(seconds: 1));
                                Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();

                                if (!success)
                                  DialogPopup.asyncOkDialog("Profilbild konnte nicht geändert werden!", Api.errorMessage);
                                else {
                                  setState(() {});
                                  DialogPopup.asyncOkDialog("Profilbild gespeichert", "Dein Profilbild wurde erfolgreich an Xitem übermittelt.");
                                }
                              }
                            }
                          }
                        },
                        child: CircleAvatar(
                          backgroundImage: (_newAvatarImage == null) ? FileImage(UserController.user.avatar) : FileImage(_newAvatarImage),
                          radius: 60,
                          child: Icon(Icons.add_a_photo, size: 50, color: ThemeController.activeTheme().iconColor),
                        ),
                      ),
                    ),
                    Divider(height: 40, color: ThemeController.activeTheme().dividerColor),
                    Text(
                      "Account Daten ändern",
                      style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    nameField,
                    SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(flex: 9, child: birthdayField),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            iconSize: 30,
                            onPressed: () {
                              _birthday = null;
                              _birthdayText.clear();
                            },
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 20),
                    saveProfileButton,
                    Divider(height: 40, color: ThemeController.activeTheme().dividerColor),
                    Text(
                      "Passwort ändern",
                      style: TextStyle(
                        color: ThemeController.activeTheme().headlineColor,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    oldPasswordField,
                    SizedBox(height: 20),
                    newPasswordField,
                    SizedBox(height: 20),
                    repeatPasswordField,
                    SizedBox(height: 20),
                    changePasswordButton,
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        )));
  }
}
