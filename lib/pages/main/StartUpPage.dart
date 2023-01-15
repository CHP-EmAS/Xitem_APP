import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class StartUpPage extends StatefulWidget {
  const StartUpPage({super.key});
  
  @override
  State<StatefulWidget> createState() => _StartUpPageState();
}

class _StartUpPageState extends State<StartUpPage> with SingleTickerProviderStateMixin, AppStateListener {

  late final AnimationController _progressAnimationController;
  String _errorMessage = "";
  String _progressMessage = "";

  @override
  void initState() {
    super.initState();

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      setState(() {});
    });

    StateController.registerListener(this);

    initializeAppState();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    StateController.removeListener(this);
    super.dispose();
  }

  @override
  void onAppStateChanged(AppState oldState, AppState newState) {
    switch(newState) {
      case AppState.uninitialized:
        _progressMessage = "Starte Xitem...";
        setProgress(0);
        break;
      case AppState.connecting:
        _progressMessage = "Verbinden...";
        setProgress(10);
        break;
      case AppState.authenticating:
        _progressMessage = "Authentifizieren...";
        setProgress(20);
        break;
      case AppState.authenticated:
        _progressMessage = "♥";
        setProgress(40);
        break;
      case AppState.initialisingUserController:
        _progressMessage = "Empfange Nutzerdaten...";
        setProgress(55);
        break;
      case AppState.initialisingCalendarController:
        _progressMessage = "Befülle Kalender...";
        setProgress(85);
        break;
      case AppState.initialisingHolidayController:
        _progressMessage = "Berechne Feiertage...";
        setProgress(95);
        break;
      case AppState.initialisingBirthdayController:
        _progressMessage = "Lade Geburtstage...";
        setProgress(98);
        break;
      case AppState.initialized:
        _progressMessage = "Alles Tip Top 😍";
        setProgress(100);
        break;
    }
  }

  void initializeAppState() async {
    StartupResponse startUpCode = await StateController.initializeAppState();

    switch(startUpCode) {
      case StartupResponse.success:
      case StartupResponse.alreadyStarted:
        await Future.delayed(const Duration(seconds: 1));
        StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
        break;
      case StartupResponse.connectionFailed:
        setState(() {
          _errorMessage = "Bei der Verbindung zu Xitem ist ein Fehler aufgetreten! Bitte versuche es später noch einmal. ♥";
        });
        break;
      case StartupResponse.authenticationFailed:
        StateController.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        break;
      case StartupResponse.controllerInitializationFailed:
      default:
        setState(() {
          _errorMessage = "Während des Startvorgangs ist ein Fehler aufgetreten! Bitte versuche es später noch einmal. Wenn diese Fehlermeldung anhält wende dich umgehend an eine Administrator! ♥";
        });
        break;
    }
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
            _errorMessage.isEmpty
                ? _buildProgressIndicator()
                : _buildErrorLayout()
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {

    Widget progressBar = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100.0),
          child: LinearProgressIndicator(
            value: _progressAnimationController.value,
            backgroundColor: Colors.black,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(_progressMessage, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Montserrat', color: ThemeController.activeTheme().textColor, fontSize: 16)),
        ),
      ],
    );

    return Column(
      children: [
        const SpinKitFoldingCube(
          color: Colors.amberAccent,
          size: 30,
        ),
        const SizedBox(height: 40),
        if(_progressAnimationController.value > 0)
          progressBar,
      ],
    );
  }

  Widget _buildErrorLayout() {
    return Column(
      children: [
        const Icon(
          Icons.clear,
          color: Colors.red,
          size: 30,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 20.0).copyWith(color: ThemeController.activeTheme().textColor, fontSize: 18)),
        ),
      ],
    );
  }

  void setProgress(double progress) {
    _progressAnimationController.animateTo(progress/100, curve: Curves.linear, duration: const Duration(seconds: 1));
  }
}
