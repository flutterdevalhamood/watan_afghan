import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/BaseScreen.dart';
import 'package:sample/src/providers/currency_conversion_controller.dart';
import 'package:sample/src/providers/customer_controller.dart';
import 'package:sample/src/providers/dashboard_controller.dart';
import 'package:sample/src/providers/investor_transaction_controller.dart';
import 'package:sample/src/providers/login_controller.dart';
import 'package:sample/src/providers/supplier_controller.dart';
import 'package:sample/src/util/shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/repo/auth_repo.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthRepo.initAuth();
  prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(
          create: (context) => InvestorTransactionController(),
        ),
        ChangeNotifierProvider(
          create: (context) => CurrencyConversionController(),
        ),
        ChangeNotifierProvider(create: (context) => DashboardController()),
        ChangeNotifierProvider(create: (context) => CustomerController()),
        ChangeNotifierProvider(create: (context) => SupplierController()),
      ],
      child: const BaseScreen(),
    ),
  );
}
