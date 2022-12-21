import 'package:xitem/controllers/ThemeController.dart';
import 'package:flutter/material.dart';

class CustomScrollBehavior extends ScrollBehavior {
  const CustomScrollBehavior(this._showLeading, this._showTrailing);

  final bool _showLeading;
  final bool _showTrailing;

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return GlowingOverscrollIndicator(
      showLeading: _showLeading,
      showTrailing: _showTrailing,
      axisDirection: axisDirection,
      color: ThemeController.activeTheme().globalAccentColor,
      child: child,
    );
  }
}
