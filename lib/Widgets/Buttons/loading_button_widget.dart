import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingButton extends StatefulWidget {
  LoadingButton(this._buttonText, this._successText, this._buttonColor, this._callBack);

  final String _buttonText;
  final String _successText;
  final Color _buttonColor;
  final Function _callBack;

  @override
  _LoadingButtonState createState() => _LoadingButtonState(_buttonText, _successText, _buttonColor, _callBack);
}

class _LoadingButtonState extends State<LoadingButton> with SingleTickerProviderStateMixin {
  int buttonState = 0;

  String _buttonText = "";
  String _successText = "";
  Color _buttonColor = Colors.amber;
  Function _callBack;

  _LoadingButtonState(String buttonText, String successText, Color buttonColor, Function callBack) {
    _buttonText = buttonText;
    _successText = successText;
    _buttonColor = buttonColor;
    _callBack = callBack;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      color: getButtonColor(),
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
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
        return SizedBox(
          height: 18,
          child: SpinKitThreeBounce(
            color: Color.fromARGB(150, 255, 255, 255),
            size: 30,
          ),
        );
      case 2:
        return Text(_successText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ));
      case 3:
      case 0:
      default:
        return Text(_buttonText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ));
    }
  }
}
