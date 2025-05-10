import 'package:flutter/material.dart';
import 'package:sample/src/screens/expenses/expense_screen.dart';
import 'package:sample/src/screens/financialTransactions/financial_transactions_screen.dart';
import 'package:sample/src/screens/purchases/purchase_screen.dart';
import 'package:sample/src/screens/sales/sales_screen.dart';

import '../constants/string_constants.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';

class Screenroutes {
  static final RouteObserver<PageRoute> routeobserver =
      RouteObserver<PageRoute>();

  static const String login = "login";
  static const String dashboard = "DashBoard";
  static const String salesScreen = "salesScreen";
  static const String purchaseScreen = "purchaseScreen";
  static const String expenseScreen = "expenseScreen";
  static const String financialTransactions = "financialTransactions";

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
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.dashboard),
          builder: (BuildContext context) {
            return DashboardScreen();
          },
        );

      case Screenroutes.salesScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.salesScreen),
          builder: (BuildContext context) {
            return SalesScreen();
          },
        );

      case Screenroutes.purchaseScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.purchaseScreen),
          builder: (BuildContext context) {
            return PurchaseScreen();
          },
        );

      case Screenroutes.expenseScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.expenseScreen),
          builder: (BuildContext context) {
            return ExpenseScreen();
          },
        );

      case Screenroutes.financialTransactions:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.financialTransactions,
          ),
          builder: (BuildContext context) {
            return FinancialTransactionsScreen();
          },
        );
    }
    return null;
  }
}
