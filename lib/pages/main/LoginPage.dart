import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Widgets/Buttons/loading_button_widget.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
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
    final TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0, color: Colors.black);

    final emailField = TextField(
      obscureText: false,
      style: style,
      controller: _email,
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "E-Mail",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0))),
    );

    final passwordField = TextField(
      obscureText: true,
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

    Widget forgetPasswordText() {
      if (_wrongLogin) {
        return TextButton(
          onPressed: () => _forgotPasswordClick,
          child: Text(
            'Passwort vergessen?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueAccent,
            ),
          ),
        );
      } else {
        return SizedBox(height: 10);
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
              SizedBox(height: 25.0),
              passwordField,
              forgetPasswordText(),
              SizedBox(height: 25.0),
              Container(
                child: LoadingButton("Anmelden", "Anmelden", Colors.amber, _loginClick),
              ),
              Container(
                  child: Row(
                children: <Widget>[
                  Text(
                    "Noch kein Account?",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ThemeController.activeTheme().textColor, fontSize: 16),
                  ),
                  TextButton(
                    child: Text(
                      'Registrieren',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              )),
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

  Future<bool> _loginClick() async {
    if (_email.text == "" || _password.text == "") return false;

    return await UserController.login(_email.text, _password.text).then((loginSuccess) {
      if (loginSuccess) {
        Navigator.popAndPushNamed(context, '/startup');
        return true;
      } else {
        setState(() {
          _errorMessage = Api.errorMessage;
          _lastTryEmail = _email.text;
          _wrongLogin = true;
        });
        return false;
      }
    });
  }

  void _forgotPasswordClick() async {
    if (_lastTryEmail != "") {
      ConfirmAction answer = await DialogPopup.asyncConfirmDialog("Passwort zurücksetzen", "Möchtest du einen Wiederherstellungscode an\n" + _lastTryEmail + "\nsenden.");

      if (answer == ConfirmAction.OK) {
        if (await Api.sendPasswordEmail(_lastTryEmail)) {
          await DialogPopup.asyncOkDialog("E-Mail gesendet", "Wenn diese E-Mail in unserem System hinterlegt ist, wurde ein Wiederherstellungscode gesendet.");
        } else {
          await DialogPopup.asyncOkDialog("E-Mail nicht gesendet", "Es ist ein Fehler aufgetreten, versuch es später erneut.");
        }
      }
    }
  }
}
