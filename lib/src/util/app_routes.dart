import 'package:flutter/material.dart';
import 'package:sample/src/screens/change_password_screen.dart';
import 'package:sample/src/screens/expenses/expense_screen.dart';
import 'package:sample/src/screens/financialTransactions/financial_transactions_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_data_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_detail_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_reports_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_screen.dart';
import 'package:sample/src/screens/profile_update_screen.dart';
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

  static const String changePassword = "changePassword";
  static const String userUpdateScreen = "userUpdateScreen";
  static const String profileUpdateScreen = "profileUpdateScreen";

  //investortransaction
  static const String investorTransactionScreen = "investorTransactionScreen";
  static const String investorTransactionDetailScreen =
      "investorTransactionDetailScreen";
  static const String investorTransactionDataScreen =
      "investorTransactionDataScreen";
  static const String investorTransactionReportsScreen =
      "investorTransactionReportsScreen";

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

      case Screenroutes.changePassword:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.changePassword),
          builder: (BuildContext context) {
            return ChangePasswordScreen();
          },
        );

      case Screenroutes.userUpdateScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.userUpdateScreen),
          builder: (BuildContext context) {
            return ChangePasswordScreen();
          },
        );

      case Screenroutes.profileUpdateScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.profileUpdateScreen),
          builder: (BuildContext context) {
            return ProfileUpdateScreen();
          },
        );

      case Screenroutes.profileUpdateScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.profileUpdateScreen),
          builder: (BuildContext context) {
            return ProfileUpdateScreen();
          },
        );

      case Screenroutes.investorTransactionScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.investorTransactionScreen,
          ),
          builder: (BuildContext context) {
            return InvestorTransactionScreen();
          },
        );

      case Screenroutes.investorTransactionDetailScreen:
        final data = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.investorTransactionDetailScreen,
          ),
          builder: (BuildContext context) {
            return InvestorTransactionDetailScreen(transaction: data);
          },
        );

      case Screenroutes.investorTransactionDataScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.investorTransactionDataScreen,
          ),
          builder: (BuildContext context) {
            return InvestorTransactionDataScreen();
          },
        );

      case Screenroutes.investorTransactionReportsScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.investorTransactionReportsScreen,
          ),
          builder: (BuildContext context) {
            return InvestorTransactionReportScreen();
          },
        );
    }
    return null;
  }
}
