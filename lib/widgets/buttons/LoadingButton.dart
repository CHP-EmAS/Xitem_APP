import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingButton extends StatefulWidget {
  const LoadingButton({super.key, required this.buttonText, required this.successText, required this.buttonColor, required this.callBack});

  final String buttonText;
  final String successText;
  final Color buttonColor;
  final Function callBack;

  @override
  State<StatefulWidget> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> with SingleTickerProviderStateMixin {
  int buttonState = 0;

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

    widget.callBack().then((success) {
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
        return widget.buttonColor;
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
        return Text(widget.successText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ));
      case 3:
      case 0:
      default:
        return Text(widget.buttonText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ));
    }
  }
}
