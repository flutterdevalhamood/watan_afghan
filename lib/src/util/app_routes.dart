import 'package:flutter/material.dart';

import '../constants/string_constants.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';

class Screenroutes {
  static final RouteObserver<PageRoute> routeobserver =
      RouteObserver<PageRoute>();

  static const String login = "login";
  static const String dashboard = "DashBoard";

  static Route<dynamic>? routes(RouteSettings settings) {
    StringConstants.currentRoute = settings.name ?? "";

    switch (settings.name) {
      case Screenroutes.login:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.login),
          builder: (BuildContext context) {
            return const LoginScreen();
          },
        );
      case Screenroutes.dashboard:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.dashboard),
          builder: (BuildContext context) {
            return DashboardScreen();
          },
        );
    }
    return null;
  }
}
