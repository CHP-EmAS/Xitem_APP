import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class StartUpPage extends StatefulWidget {
  const StartUpPage({super.key});
  
  @override
  State<StatefulWidget> createState() => _StartUpPageState();
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
    debugPrint("Starting up....");

    for(int i = 0; i < ThemeController.eventColors.length; i++) {
      debugPrint("$i : ${ThemeController.eventColors[i].value}");
    }

    await StateController.getApiInfo().timeout(const Duration(seconds: 30), onTimeout: () {
      return ApiResponse(ResponseCode.timeout);
    }).then((apiInfoRequest) {

      if(apiInfoRequest.code != ResponseCode.success) {
        setState(() {
          _failedToStartUp = true;
          _message = "Xitem ist derzeit nicht erreichbar! Bitte versuche es später noch einmal. ♥";
        });
        return;
      }


      StateController.localLogin().then((responseCode) {
        if (responseCode == ResponseCode.success) {
          StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });

    }).catchError((error) {
      debugPrint("Error while connecting to API: $error");
      setState(() {
        _failedToStartUp = true;
        _message = "Bei der Verbindung zu Xitem ist ein Fehler aufgetreten! Bitte versuche es später noch einmal.";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeController.activeTheme().backgroundColor,
      body: Center(
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
            const SizedBox(height: 20),
            _failedToStartUp
                ? const Icon(
                    Icons.clear,
                    color: Colors.red,
                    size: 30,
                  )
                : const SpinKitFoldingCube(
                    color: Colors.amber,
                    size: 30,
                  ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 20.0).copyWith(color: ThemeController.activeTheme().textColor, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
