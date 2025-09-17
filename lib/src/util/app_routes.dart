import 'package:flutter/material.dart';
import 'package:sample/src/screens/change_password_screen.dart';
import 'package:sample/src/screens/contacts/contactsScreen.dart';
import 'package:sample/src/screens/currencyConversions/currency_conversion_data_screen.dart';
import 'package:sample/src/screens/currencyConversions/currency_conversion_detail_screen.dart';
import 'package:sample/src/screens/currencyConversions/currency_conversion_list_screen.dart';
import 'package:sample/src/screens/customer/customer_data_screen.dart';
import 'package:sample/src/screens/customer/customer_list_screen.dart';
import 'package:sample/src/screens/customerAdvance/customer_advance_data_screen.dart';
import 'package:sample/src/screens/customerAdvance/customer_advance_list_screen.dart';
import 'package:sample/src/screens/expenses/expense_data_screen.dart';
import 'package:sample/src/screens/expenses/expense_list_screen.dart';
import 'package:sample/src/screens/financialTransactions/financial_transactions_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_data_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_detail_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_reports_screen.dart';
import 'package:sample/src/screens/investorTransactions/investor_transaction_screen.dart';
import 'package:sample/src/screens/master/master_screen.dart';
import 'package:sample/src/screens/products/product_edit_screen.dart';
import 'package:sample/src/screens/products/product_list_screen.dart';
import 'package:sample/src/screens/products/product_registration_screen.dart';
import 'package:sample/src/screens/profile_update_screen.dart';
import 'package:sample/src/screens/purchases/purchase_list_screen.dart';
import 'package:sample/src/screens/purchases/purchase_screen.dart';
import 'package:sample/src/screens/reports/cash_report_screen.dart';
import 'package:sample/src/screens/reports/current_stock_report_screen.dart';
import 'package:sample/src/screens/reports/customer_statement_screen.dart';
import 'package:sample/src/screens/reports/expense_report_screen.dart';
import 'package:sample/src/screens/reports/landscape_report_screen.dart';
import 'package:sample/src/screens/reports/purchase_report_screen.dart';
import 'package:sample/src/screens/reports/reports_home_screen.dart';
import 'package:sample/src/screens/reports/sales_report_screen.dart';
import 'package:sample/src/screens/reports/supplier_statement_screen.dart';
import 'package:sample/src/screens/sales/sales_list_screen.dart';
import 'package:sample/src/screens/sales/sales_screen.dart';
import 'package:sample/src/screens/supplier/supplier_data_screen.dart';
import 'package:sample/src/screens/supplier/supplier_list_screen.dart';
import 'package:sample/src/screens/supplierAdvance/supplier_advance_data_screen.dart';
import 'package:sample/src/screens/supplierAdvance/supplier_advance_list_screen.dart';
import 'package:sample/src/screens/supplierAdvance/supplier_advance_update_screen.dart';
import 'package:sample/src/screens/units/unit_list_screen.dart';
import 'package:sample/src/screens/units/unit_registration_screen.dart';
import 'package:sample/src/screens/units/unit_update_screen.dart';

import '../constants/string_constants.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/login_screen.dart';

class Screenroutes {
  static final RouteObserver<PageRoute> routeobserver =
      RouteObserver<PageRoute>();

  static const String login = "login";
  static const String dashboard = "DashBoard";
  static const String expenseScreen = "expenseScreen";
  static const String financialTransactions = "financialTransactions";

  static const String changePassword = "changePassword";
  static const String userUpdateScreen = "userUpdateScreen";
  static const String profileUpdateScreen = "profileUpdateScreen";

  static const String bankDetailsScreen = "bankDetailsScreen";

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
  static const String masterScreen = "masterScreen";

  //expenses
  static const String expenseListScreen = "expenseListScreen";
  static const String expenseDataScreen = "expenseDataScreen";
  static const String expenseDetailScreen = "expenseDetailScreen";

  //product
  static const String productList = "productList";
  static const String productRegistration = "productRegistration";
  static const String productEdit = "productEdit";

  //unit
  static const String unitList = "unitList";
  static const String unitRegistration = "unitRegistration";
  static const String unitEdit = "unitEdit";

  //purchase
  static const String purchaseListScreen = "purchaseListScreen";
  static const String purchaseRegistration = "purchaseRegistration";

  //sales
  static const String salesListScreen = "salesListScreen";
  static const String salesRegistration = "salesRegistration";

  //reports
  static const String reportsHomeScreen = "reportsHomeScreen";
  static const String salesReportScreen = "salesReportScreen";
  static const String purchaseReportScreen = "purchaseReportScreen";
  static const String expenseReportScreen = "expenseReportScreen";
  static const String landscapeExpenseReportScreen =
      "landscapeExpenseReportScreen";
  static const String cashReportScreen = "cashReportScreen";

  //statements
  static const String customerStatementScreen = "customerStatementScreen";
  static const String supplierStatementScreen = "supplierStatementScreen";

  static const String currentStockReportScreen = "currentStockReportScreen";

  //supplieradvance
  static const String supplierAdvanceListScreen = "supplierAdvanceListScreen";
  static const String supplierAdvanceDataScreen = "supplierAdvanceDataScreen";
  static const String supplierAdvanceUpdateScreen =
      "supplierAdvanceUpdateScreen";

  //customeradvance
  static const String customerAdvanceListScreen = "customerAdvanceListScreen";
  static const String customerAdvanceDataScreen = "customerAdvanceDataScreen";
  static const String customerAdvanceUpdateScreen =
      "customerAdvanceUpdateScreen";

  static Route<dynamic>? routes(RouteSettings settings) {
    StringConstants.currentRoute = settings.name ?? "";

    switch (settings.name) {
      case Screenroutes.login:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.login),
          builder: (BuildContext context) {
            return LoginScreen();
          },
        );
      case Screenroutes.dashboard:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.dashboard),
          builder: (BuildContext context) {
            return DashboardScreen();
          },
        );

      // case Screenroutes.bankDetailsScreen:
      //   final data = settings.arguments as Map<String, dynamic>?;
      //   return MaterialPageRoute(
      //     settings: const RouteSettings(name: Screenroutes.bankDetailsScreen),
      //     builder: (BuildContext context) {
      //       return BankDetailsScreen(
      //
      //       );
      //     },
      //   );

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
            return SupplierDataScreen();
          },
        );

      case Screenroutes.contactsScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.contactsScreen),
          builder: (BuildContext context) {
            return ContactsScreen();
          },
        );

      case Screenroutes.expenseListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.expenseListScreen),
          builder: (BuildContext context) {
            return ExpenseListScreen();
          },
        );

      case Screenroutes.expenseDataScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.expenseDataScreen),
          builder: (BuildContext context) {
            return ExpenseScreen();
          },
        );

      case Screenroutes.masterScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.masterScreen),
          builder: (BuildContext context) {
            return MasterScreen();
          },
        );

      //product
      case Screenroutes.productList:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.productList),
          builder: (BuildContext context) {
            return ProductListScreen();
          },
        );

      case Screenroutes.productRegistration:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.productRegistration),
          builder: (BuildContext context) {
            return ProductRegistrationScreen();
          },
        );

      case Screenroutes.productEdit:
        final product = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.productEdit),
          builder: (BuildContext context) {
            return EditProductScreen(data: product ?? {});
          },
        );

      case Screenroutes.unitList:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.unitList),
          builder: (BuildContext context) {
            return UnitListScreen();
          },
        );

      case Screenroutes.unitRegistration:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.unitRegistration),
          builder: (BuildContext context) {
            return UnitRegistrationScreen();
          },
        );

      case Screenroutes.unitEdit:
        final product = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.unitEdit),
          builder: (BuildContext context) {
            return UnitUpdateScreen(data: product ?? {});
          },
        );

      case Screenroutes.purchaseListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.purchaseListScreen),
          builder: (BuildContext context) {
            return PurchaseListScreen();
          },
        );

      case Screenroutes.purchaseRegistration:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.purchaseRegistration,
          ),
          builder: (BuildContext context) {
            return PurchaseScreen();
          },
        );

      case Screenroutes.salesListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.salesListScreen),
          builder: (BuildContext context) {
            return SalesListScreen();
          },
        );

      case Screenroutes.salesRegistration:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.salesRegistration),
          builder: (BuildContext context) {
            return SalesScreen();
          },
        );

      case Screenroutes.reportsHomeScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.reportsHomeScreen),
          builder: (BuildContext context) {
            return ReportsHomeScreen();
          },
        );

      case Screenroutes.salesReportScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.salesReportScreen),
          builder: (BuildContext context) {
            return SalesReportScreen();
          },
        );
      case Screenroutes.purchaseReportScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.purchaseReportScreen,
          ),
          builder: (BuildContext context) {
            return PurchaseReportScreen();
          },
        );

      case Screenroutes.expenseReportScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.expenseReportScreen),
          builder: (BuildContext context) {
            return ExpenseReportScreen();
          },
        );

      case Screenroutes.landscapeExpenseReportScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.landscapeExpenseReportScreen,
          ),
          builder: (BuildContext context) {
            return LandscapeReportScreen();
          },
        );

      case Screenroutes.customerStatementScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.customerStatementScreen,
          ),
          builder: (BuildContext context) {
            return CustomerStatementScreen();
          },
        );

      case Screenroutes.supplierStatementScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.supplierStatementScreen,
          ),
          builder: (BuildContext context) {
            return SupplierStatementScreen();
          },
        );

      case Screenroutes.cashReportScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.cashReportScreen),
          builder: (BuildContext context) {
            return CashReportScreen();
          },
        );

      case Screenroutes.currentStockReportScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.currentStockReportScreen,
          ),
          builder: (BuildContext context) {
            return CurrentStockReportScreen();
          },
        );

      case Screenroutes.supplierAdvanceListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.supplierAdvanceListScreen,
          ),
          builder: (BuildContext context) {
            return SupplierAdvanceListScreen();
          },
        );

      case Screenroutes.supplierAdvanceDataScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.supplierAdvanceDataScreen,
          ),
          builder: (BuildContext context) {
            return SupplierAdvanceDataScreen();
          },
        );

      case Screenroutes.supplierAdvanceUpdateScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.supplierAdvanceUpdateScreen,
          ),
          builder: (BuildContext context) {
            return SupplierAdvanceUpdateScreen();
          },
        );

      case Screenroutes.customerAdvanceListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.customerAdvanceListScreen,
          ),
          builder: (BuildContext context) {
            return CustomerAdvanceListScreen();
          },
        );

      case Screenroutes.customerAdvanceDataScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.customerAdvanceDataScreen,
          ),
          builder: (BuildContext context) {
            return CustomerAdvanceDataScreen();
          },
        );

      // case Screenroutes.customerAdvanceUpdateScreen:
      //   return MaterialPageRoute(
      //     settings: const RouteSettings(
      //       name: Screenroutes.customerAdvanceUpdateScreen,
      //     ),
      //     builder: (BuildContext context) {
      //       return customerAdvanceUpdateScreen();
      //     },
      //   );
    }
    return null;
  }
}
