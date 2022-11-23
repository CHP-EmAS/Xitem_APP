import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/ThemeController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class StartUpPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _StartUpPageState();
  }
}

class _StartUpPageState extends State<StartUpPage> {
  String _message = "";
  bool _failedToStartUp = false;

  @override
  void initState() {
    super.initState();
    connectWithApi();
  }

  void connectWithApi() async {
    print("Starting up....");

    await Api.checkStatus().timeout(new Duration(seconds: 60), onTimeout: () {
      return false;
    }).then((connected) {
      if (connected) {
        //Login via stored Tokens
        UserController.trySecureLogin().then((success) {
          if (success) {
            //loading User informations
            UserController.loadAllCalendars().then((success) {
              if (success) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            }).catchError((error) {
              setState(() {
                _failedToStartUp = true;
                _message = "Ein Fehler ist bei der Verbindung mit Xitem aufgetreten! Bitte versuch es später erneut.";
              });
            });
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        });
      } else {
        setState(() {
          _failedToStartUp = true;
          _message = "Xitem ist momentan nicht erreichbar! Bitte versuch es später erneut.";
        });
      }
    }).catchError((error) {
      print(error);
      setState(() {
        _failedToStartUp = true;
        _message = "Ein Fehler ist bei der Verbindung mit Xitem aufgetreten! Bitte versuch es später erneut.";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 160.0,
                child: Image.asset(
                  "images/logo_hell.png",
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 20),
              _failedToStartUp
                  ? Icon(
                      Icons.clear,
                      color: Colors.red,
                      size: 30,
                    )
                  : SpinKitFoldingCube(
                      color: Colors.amber,
                      size: 30,
                    ),
              SizedBox(height: 20),
              Text(_message, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Montserrat', fontSize: 20.0).copyWith(color: ThemeController.activeTheme().textColor, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
