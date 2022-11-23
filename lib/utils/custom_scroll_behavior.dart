import 'package:de/Controllers/ThemeController.dart';
import 'package:flutter/material.dart';

class CustomScrollBehavior extends ScrollBehavior {
  CustomScrollBehavior(this._showLeading, this._showTrailing);

  final bool _showLeading;
  final bool _showTrailing;

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return GlowingOverscrollIndicator(
      showLeading: _showLeading,
      showTrailing: _showTrailing,
      child: child,
      axisDirection: axisDirection,
      color: ThemeController.activeTheme().globalAccentColor,
    );
  }
}
