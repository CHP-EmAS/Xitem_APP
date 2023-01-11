import 'package:xitem/api/AuthenticationApi.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/widgets/buttons/LoadingButton.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.authenticationApi});

  final AuthenticationApi authenticationApi;

  @override
  State<StatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _email = TextEditingController();
  final _name = TextEditingController();

  static final _birthdayFormat = DateFormat.yMMMMd('de_DE');
  final _birthdayText = TextEditingController();
  DateTime? _birthday;

  String _errorMessage = "";

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _birthdayText.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = const TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.black);

    final emailField = TextField(
      obscureText: false,
      style: style,
      controller: _email,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "E-Mail*",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final nameField = TextField(
      obscureText: false,
      style: style,
      controller: _name,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Name*",
          hintStyle: const TextStyle(color: Colors.grey),
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

    final registerButton = LoadingButton(buttonText: "Registrieren", successText: "Registriert", buttonColor: Colors.amber, callBack: _registerClick);

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
            const SizedBox(height: 30.0),
            emailField,
            const SizedBox(height: 20.0),
            nameField,
            const SizedBox(height: 20.0),
            birthdayField,
            const SizedBox(height: 5.0),
            const Text(
              '* Pflichtfelder',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 20.0),
            registerButton,
            const SizedBox(
              height: 5,
            ),
            Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<bool> _registerClick() async {
    if (_email.text == "" || _name.text == "") return false;

    return await widget.authenticationApi.register(UserRegistrationRequest(_email.text, _name.text, _birthday)).then((registerEmail) async {
      if (registerEmail != ResponseCode.success) {
        switch(registerEmail) {
          case ResponseCode.emailExistsError:
            _errorMessage = "Ein Account mit dieser E-Mail existiert bereits";
            break;
          case ResponseCode.shortName:
            _errorMessage = "Der Name muss mindestens 3 Zeichen lang sein.";
            break;
          case ResponseCode.invalidEmail:
            _errorMessage = "Die angegebene E-Mail ist nicht gültig.";
            break;
          case ResponseCode.invalidDate:
            _errorMessage = "Der angegebene Geburtstag ist nicht gültig.";
            break;
          default:
            _errorMessage = "Bei der Registrierung ist ein Fehler aufgetreten. Versuche es später noch einmal.";
            break;
        }

        setState(() {});

        return false;
      }

      await StandardDialog.okDialog("Bestätigungs E-Mail gesendet", "Bitte bestätige deine E-Mail-Adresse, danach kannst du dich anmelden.");

      return true;
    });
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        errorFormatText: "Ungültiges Format",
        helpText: "Geburtstag auswählen",
        initialDatePickerMode: DatePickerMode.year,
        useRootNavigator: false,
        initialDate: DateTime.now(),
        firstDate: DateTime(1901, 1),
        lastDate: DateTime.now(),
        locale: const Locale('de', 'DE')
    );

    if (picked != null && picked != _birthday) {
      _birthday = picked;
      setState(() {
        _birthdayText.text = _birthdayFormat.format(picked);
      });
    }
  }
}
