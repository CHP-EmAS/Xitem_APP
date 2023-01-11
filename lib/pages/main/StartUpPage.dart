import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class StartUpPage extends StatefulWidget {
  const StartUpPage({super.key});
  
  @override
  State<StatefulWidget> createState() => _StartUpPageState();
}

class _StartUpPageState extends State<StartUpPage> with SingleTickerProviderStateMixin {

  late final AnimationController _progressAnimationController;
  final ValueNotifier<int> _progress = ValueNotifier<int>(0);
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      setState(() {});
    });

    _progress.addListener(_onProgressValueChanges);

    initializeAppState();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _progress.dispose();
    super.dispose();
  }

  void initializeAppState() async {
    StartupResponse startUpCode = await StateController.initializeAppState(progress: _progress);

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
    return Column(
      children: [
        const SpinKitFoldingCube(
          color: Colors.amberAccent,
          size: 30,
        ),
        const SizedBox(height: 40),
        if(_progressAnimationController.value > 0.05)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: LinearProgressIndicator(
              value: _progressAnimationController.value,
              backgroundColor: Colors.black,
              color: Colors.amber,
            ),
          )
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

  void _onProgressValueChanges() {
    int progress = _progress.value;
    _progressAnimationController.animateTo(progress.toDouble()/100, curve: Curves.linear, duration: const Duration(seconds: 1));
  }
}
