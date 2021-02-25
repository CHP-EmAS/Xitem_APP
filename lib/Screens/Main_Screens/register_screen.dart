import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Interfaces/api_interfaces.dart';
import 'package:de/Settings/locator.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:de/Widgets/buttons/loading_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final NavigationService _navigationService = locator<NavigationService>();

  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.black);

  final _email = TextEditingController();
  final _name = TextEditingController();

  final _birthdayText = TextEditingController();
  final birthdayFormat = new DateFormat.yMMMMd('de_DE');
  DateTime _birthday;

  String _errorMessage = "";

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

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _birthdayText.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailField = TextField(
      obscureText: false,
      style: style,
      controller: _email,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "E-Mail*",
          hintStyle: TextStyle(color: Colors.grey),
          //errorText: _validEmail ? null : "Email adress is invalid!",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final nameField = TextField(
      obscureText: false,
      style: style,
      controller: _name,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Name*",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final birthdayField = GestureDetector(
      onTap: () => _selectDate(context),
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

    final registerButton = LoadingButton("Registrieren", "Registriert", Colors.amber, () async {
      if (_email.text == "" || _name.text == "") return false;

      return await Api.register(UserRegistrationRequest(_email.text, _name.text, _birthday)).then((registerSuccess) async {
        if (registerSuccess) {
          await DialogPopup.asyncOkDialog("Bestätigungs E-Mail gesendet", "Bitte bestätigen sie ihre E-Mail Adresse, danach können sie sich anmelden.");

          _navigationService.pop();

          return true;
        } else {
          setState(() {
            _errorMessage = Api.errorMessage;
          });
          return false;
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: ThemeController.activeTheme().iconColor,
        ),
        title: Text(
          "Registrieren",
          style: TextStyle(color: ThemeController.activeTheme().textColor),
        ),
        centerTitle: true,
        backgroundColor: ThemeController.activeTheme().foregroundColor,
        elevation: 0,
      ),
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: Center(
        child: Container(
          child: ListView(
            padding: const EdgeInsets.all(36),
            children: <Widget>[
              SizedBox(
                height: 160.0,
                child: Image.asset(
                  "images/logo_hell.png",
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 30.0),
              emailField,
              SizedBox(height: 20.0),
              nameField,
              SizedBox(height: 20.0),
              birthdayField,
              SizedBox(height: 5.0),
              Text(
                '* Pflichtfelder',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              SizedBox(height: 20.0),
              registerButton,
              SizedBox(
                height: 5,
              ),
              Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
