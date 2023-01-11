import 'package:xitem/api/AuthenticationApi.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/widgets/buttons/LoadingButton.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authenticationApi});

  final AuthenticationApi authenticationApi;

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _wrongLogin = false;
  String _lastTryEmail = "";

  String _errorMessage = "";

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.black);

    final emailField = TextField(
      obscureText: false,
      style: style,
      controller: _email,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "E-Mail",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final passwordField = TextField(
      obscureText: true,
      style: style,
      controller: _password,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Passwort",
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    Widget forgetPasswordText() {
      if (_wrongLogin) {
        return TextButton(
          onPressed: () => _forgotPasswordClick,
          child: const Text(
            'Passwort vergessen?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueAccent,
            ),
          ),
        );
      } else {
        return const SizedBox(height: 10);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Anmelden",
          style: TextStyle(
            color: ThemeController.activeTheme().textColor,
          ),
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
            const SizedBox(height: 25.0),
            passwordField,
            forgetPasswordText(),
            const SizedBox(height: 25.0),
            LoadingButton(buttonText: "Anmelden", successText: "Anmelden", buttonColor: Colors.amber, callBack: _loginClick),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
            Text(
              "Noch kein Account?",
              textAlign: TextAlign.center,
              style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16),
            ),
            TextButton(
              child: const Text(
                'Registrieren',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              onPressed: () {
                StateController.navigatorKey.currentState?.pushNamed('/register');
              },
            )
              ],
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

  Future<bool> _loginClick() async {
    if (_email.text == "" || _password.text == "") return false;

    return await StateController.remoteLogin(_email.text, _password.text).then((loginResponse) {
      if(loginResponse != ResponseCode.success) {
        setState(() {
          _errorMessage = "Authentifizierung fehlgeschlagen";
          _lastTryEmail = _email.text;
          _wrongLogin = true;
        });

        return false;
      }

      StateController.navigatorKey.currentState?.popAndPushNamed('/startup');
      return true;
    });
  }

  void _forgotPasswordClick() async {
    if (_lastTryEmail != "") {
      ConfirmAction? answer = await StandardDialog.confirmDialog("Passwort zurücksetzen", "Möchtest du einen Wiederherstellungscode an\n$_lastTryEmail\nsenden?");

      if (answer == ConfirmAction.ok) {
        ResponseCode sendPassEmail = await widget.authenticationApi.sendPasswordEmail(_lastTryEmail);

        if (sendPassEmail == ResponseCode.success) {
          await StandardDialog.okDialog("E-Mail gesendet", "Wenn diese E-Mail in unserem System gespeichert ist, wurde ein Wiederherstellungscode gesendet.");
        } else {
          await StandardDialog.okDialog("E-Mail nicht gesendet", "Es ist ein Fehler aufgetreten, versuch es später noch einmal.");
        }
      }
    }
  }
}
