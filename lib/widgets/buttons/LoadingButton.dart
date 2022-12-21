import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingButton extends StatefulWidget {
  LoadingButton(this.buttonText, this.successText, this.buttonColor, this.callBack);

  final String buttonText;
  final String successText;
  final Color buttonColor;
  final Function callBack;

  @override
  _LoadingButtonState createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> with SingleTickerProviderStateMixin {
  int buttonState = 0;

  late String _buttonText;
  late String _successText;
  late Color _buttonColor;
  late Function _callBack;

  @override
  void initState() {
    super.initState();

    _buttonText = widget.buttonText;
    _successText = widget.successText;
    _buttonColor = widget.buttonColor;
    _callBack = widget.callBack;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      color: getButtonColor(),
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
        child: buildButtonChild(),
        onPressed: () {
          FocusScopeNode currentFocus = FocusScope.of(context);

          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }

          switch (buttonState) {
            case 0:
              animateButton();
              break;
            case 2:
            case 3:
              setState(() {
                buttonState = 0;
              });
              animateButton();
          }
        },
      ),
    );
  }

  void animateButton() {
    setState(() {
      buttonState = 1;
    });

    _callBack().then((success) {
      if (success) {
        setState(() {
          buttonState = 2;
        });
      } else {
        setState(() {
          buttonState = 3;
        });
      }
    });
  }

  Color getButtonColor() {
    switch (buttonState) {
      case 0:
      case 1:
        return _buttonColor;
      case 2:
        return Colors.lightGreen;
      case 3:
      default:
        return Colors.red;
    }
  }

  Widget buildButtonChild() {
    switch (buttonState) {
      case 1:
        return const SizedBox(
          height: 18,
          child: SpinKitThreeBounce(
            color: Color.fromARGB(150, 255, 255, 255),
            size: 30,
          ),
        );
      case 2:
        return Text(_successText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ));
      case 3:
      case 0:
      default:
        return Text(_buttonText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ));
    }
  }
}
