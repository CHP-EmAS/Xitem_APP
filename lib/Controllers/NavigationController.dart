import 'package:flutter/widgets.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

  Future<dynamic> pushNamed(String routeName, {dynamic arguments}) {
    return navigatorKey.currentState.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushNamedAndRemoveUntil(String routeName, bool Function(Route<dynamic>) function, {dynamic arguments}) {
    return navigatorKey.currentState.pushNamedAndRemoveUntil(routeName, function, arguments: arguments);
  }

  Future<dynamic> popAndPushNamed(String routeName, {Object arguments, Object result}) {
    return navigatorKey.currentState.popAndPushNamed(routeName, arguments: arguments, result: result);
  }

  bool pop<T extends Object>([T result]) {
    if (navigatorKey.currentState.canPop()) {
      navigatorKey.currentState.pop(result);
      return true;
    }
    return false;
  }
}
