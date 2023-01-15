import 'dart:io';
import 'package:xitem/api/AuthenticationApi.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/controllers/UserController.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/AvatarImageProvider.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';
import 'package:xitem/widgets/buttons/LoadingButton.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.userController, required this.authenticationApi});

  final UserController userController;
  final AuthenticationApi authenticationApi;

  @override
  State<StatefulWidget> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController();

  final _birthdayText = TextEditingController();
  final birthdayFormat = DateFormat.yMMMMd('de_DE');
  DateTime? _birthday;

  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _repeatPassword = TextEditingController();

  final ImagePicker picker = ImagePicker();
  final ImageCropper cropper = ImageCropper();
  File? _croppedProfilePicture;

  @override
  void initState() {
    _name.text = widget.userController.getAuthenticatedUser().name;
    _birthday = widget.userController.getAuthenticatedUser().birthday;

    if (_birthday != null) {
      _birthdayText.text = birthdayFormat.format(_birthday!);
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.black);

    final nameField = TextField(
      obscureText: false,
      style: style,
      controller: _name,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Name",
          hintStyle: const TextStyle(color: Colors.grey),
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
            contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
            hintText: "Geburtstag",
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
            suffixIcon: Icon(
              Icons.calendar_today,
              color: Colors.grey[800],
            ),
          ),
        ),
      ),
    );

    final saveProfileButton = LoadingButton(buttonText: "Speichern", successText: "Gespeichert", buttonColor: Colors.amber, callBack: _saveProfile);

    final oldPasswordField = TextField(
      obscureText: true,
      style: style,
      controller: _oldPassword,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Altes Passwort",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final newPasswordField = TextField(
      obscureText: true,
      style: style,
      controller: _newPassword,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Neues Passwort",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final repeatPasswordField = TextField(
      obscureText: true,
      style: style,
      controller: _repeatPassword,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Neues Passwort wiederholen",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final changePasswordButton = LoadingButton(buttonText: "Passwort ändern", successText: "Passwort gespeichert", buttonColor: Colors.amber, callBack: _changePassword);

    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            color: ThemeController.activeTheme().iconColor,
            onPressed: () {
              StateController.navigatorKey.currentState?.pop();
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
            child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: GestureDetector(
                      onTap: _changeProfilePicture,
                      child: CircleAvatar(
                        backgroundImage: _croppedProfilePicture != null ? FileImage(_croppedProfilePicture!) : AvatarImageProvider.get(widget.userController.getAuthenticatedUser().avatar),
                        radius: 80,
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
                  const SizedBox(height: 10),
                  nameField,
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(flex: 9, child: birthdayField),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: const Icon(
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
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 10),
                  oldPasswordField,
                  const SizedBox(height: 20),
                  newPasswordField,
                  const SizedBox(height: 20),
                  repeatPasswordField,
                  const SizedBox(height: 20),
                  changePasswordButton,
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        )));
  }

  Future<bool> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if(_croppedProfilePicture != null) {
      ResponseCode changeAvatar = await widget.userController.changeAvatar(_croppedProfilePicture!);
      if (changeAvatar != ResponseCode.success) {
        String errorMessage;
        switch (changeAvatar) {
          case ResponseCode.payloadTooLarge:
            errorMessage = "Das angegebene Profilbild ist zu groß!";
            break;
          default:
            errorMessage = "Es ist ein Fehler während der Übertragung des Profilbildes aufgetreten, bitte versuch es später erneut.";
        }

        StandardDialog.okDialog("Profilbild konnte nicht geändert werden!", errorMessage);
        return false;
      }
    }

    ResponseCode changeUser = await widget.userController.changeUserInformation(_name.text, _birthday);

    if (changeUser != ResponseCode.success) {
      String errorMessage;

      switch (changeUser) {
        case ResponseCode.shortName:
          errorMessage = "Der Name muss mindestens 3 Zeichen lang sein.";
          break;
        case ResponseCode.invalidDate:
          errorMessage = "Der angegebene Geburtstag ist nicht gültig.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden, versuch es später erneut.";
          break;
      }

      await StandardDialog.okDialog("Änderungen konnten nicht gespeichert werden!", errorMessage);
      return false;
    }

    return true;
  }

  Future<bool> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (_oldPassword.text == "" || _newPassword.text == "" || _repeatPassword.text == "") return false;

    return await widget.authenticationApi.changePassword(ChangePasswordRequest(_oldPassword.text, _newPassword.text, _repeatPassword.text)).then((changePassword) async {
      if (changePassword != ResponseCode.success) {
        String errorMessage;

        switch (changePassword) {
          case ResponseCode.missingArgument:
            errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
            break;
          case ResponseCode.shortPassword:
            errorMessage = "Dein Passwort muss mindestens 8 Zeichen lang sein.";
            break;
          case ResponseCode.repeatNotMatch:
            errorMessage = "Die Passwörter stimmen nicht überein.";
            break;
          case ResponseCode.wrongPassword:
            errorMessage = "Passwort falsch.";
            break;
          default:
            errorMessage = "Das Passwort konnte nicht geändert werden, versuch es später erneut.";
        }

        await StandardDialog.okDialog("Passwort konnten nicht gespeichert werden!", errorMessage);
        return false;
      }

      await StandardDialog.okDialog("Passwort geändert", "Die Änderungen wurden erfolgreich an Xitem übermittelt. Bitte melde dich erneut an.");
      StateController.logOut();
      StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/startup', (Route<dynamic> route) => false);
      return true;
    });
  }

  void _changeProfilePicture() async {
    XFile? pickedImage = await _pickImage();
    if (pickedImage == null) {
      return;
    }

    File? croppedImage = await _cropImage(pickedImage);
    if (croppedImage != null) {
      setState(() {
        _croppedProfilePicture = croppedImage;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        errorFormatText: "Ungültiges Format",
        helpText: "Geburtstag auswählen",
        initialDatePickerMode: DatePickerMode.year,
        useRootNavigator: false,
        initialDate: DateTime.now(),
        firstDate: DateTime(1901, 1),
        lastDate: DateTime.now(),
        locale: const Locale('de', 'DE'));

    if (picked != null && picked != _birthday) {
      _birthday = picked;
      setState(() {
        _birthdayText.text = birthdayFormat.format(picked);
      });
    }
  }

  Future<XFile?> _pickImage() async {
    return await picker.pickImage(source: ImageSource.gallery);
  }

  Future<File?> _cropImage(XFile imageToCrop) async {
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageToCrop.path,
      compressFormat: ImageCompressFormat.png,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Profilbild anpassen', toolbarColor: Colors.amber, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
        IOSUiSettings(
          title: 'Profilbild anpassen',
        ),
      ],
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
    );

    if (croppedFile == null) {
      return null;
    }

    return File(croppedFile.path);
  }
}
