import 'package:flutter/material.dart';
import 'package:sample/src/screens/change_password_screen.dart';
import 'package:sample/src/screens/contacts/contactsScreen.dart';
import 'package:sample/src/screens/currencyConversions/currency_conversion_data_screen.dart';
import 'package:sample/src/screens/currencyConversions/currency_conversion_detail_screen.dart';
import 'package:sample/src/screens/currencyConversions/currency_conversion_list_screen.dart';
import 'package:sample/src/screens/customer/customer_data_screen.dart';
import 'package:sample/src/screens/customer/customer_list_screen.dart';
import 'package:sample/src/screens/expenses/expense_screen.dart';
import 'package:sample/src/screens/financialTransactions/financial_transactions_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_data_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_detail_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_reports_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_screen.dart';
import 'package:sample/src/screens/profile_update_screen.dart';
import 'package:sample/src/screens/purchases/purchase_screen.dart';
import 'package:sample/src/screens/sales/sales_screen.dart';
import 'package:sample/src/screens/supplier/supplier_list_screen.dart';

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

  //currencyconversion
  static const String currencyConversionScreen = "currencyConversionScreen";
  static const String currencyConversionDataScreen =
      "currencyConversionDataScreen";
  static const String currencyConversionDetailScreen =
      "currencyConversionDetailScreen";

  //customer
  static const String customerListScreen = "customerListScreen";
  static const String customerDataScreen = "customerDataScreen";
  static const String customerDetailScreen = "customerDetailScreen";

  //supplier
  static const String supplierListScreen = "supplierListScreen";
  static const String supplierDataScreen = "supplierDataScreen";
  static const String supplierDetailScreen = "supplierDetailScreen";

  static const String contactsScreen = "contactsScreen";

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

      case Screenroutes.currencyConversionScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.currencyConversionScreen,
          ),
          builder: (BuildContext context) {
            return CurrencyConversionListScreen();
          },
        );
      case Screenroutes.currencyConversionDataScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.currencyConversionDataScreen,
          ),
          builder: (BuildContext context) {
            return CurrencyConversionDataScreen();
          },
        );
      case Screenroutes.currencyConversionDetailScreen:
        final conversionId = settings.arguments as int?;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.currencyConversionDetailScreen,
          ),
          builder: (BuildContext context) {
            return CurrencyConversionDetailScreen(id: conversionId);
          },
        );

      //customer
      case Screenroutes.customerListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.customerListScreen),
          builder: (BuildContext context) {
            return CustomerListScreen();
          },
        );

      case Screenroutes.customerDataScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.customerDataScreen),
          builder: (BuildContext context) {
            return CustomerDataScreen();
          },
        );

      case Screenroutes.supplierListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.supplierListScreen),
          builder: (BuildContext context) {
            return SupplierListScreen();
          },
        );

      case Screenroutes.supplierDataScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.supplierDataScreen),
          builder: (BuildContext context) {
            return SupplierListScreen();
          },
        );

      case Screenroutes.contactsScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.contactsScreen),
          builder: (BuildContext context) {
            return ContactsScreen();
          },
        );
    }
    return null;
  }
}
