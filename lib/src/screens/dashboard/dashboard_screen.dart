import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/dashboard_controller.dart';
import 'package:sample/src/screens/dashboard/bank_details_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/currency_utils.dart';
import 'package:sample/src/util/snack.dart';
import 'package:sample/src/widgets/drawer_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF818CF8);

  final String accountName = "Y Account";
  final DateTime currentMonth = DateTime.now();
  final DateTime lastMonth = DateTime.now().subtract(const Duration(days: 30));

  // Expense data (all zeros for current month as shown in the image)
  final List<double> dailyExpenses = List.generate(31, (index) => 0.0);

  bool _isSalesExpanded = true;
  bool _isPurchaseExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardController>(
        context,
        listen: false,
      ).getInvestorBaseData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Consumer<DashboardController>(
        builder: (context, dashboardController, child) {
          return Scaffold(
            drawer: DrawerWidget(),
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: const Text(
                'Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            body:
                dashboardController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : dashboardController.errorMessage != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dashboardController.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              dashboardController.getInvestorBaseData();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh:
                          () => dashboardController.getInvestorBaseData(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Welcome Section
                            _buildWelcomeSection(),

                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Quick Actions Section
                                  _buildQuickActionsSection(),

                                  const SizedBox(height: 24),

                                  // Accounts Overview (Cash on Hand & Bank)
                                  _buildAccountsOverviewSection(
                                    dashboardController,
                                  ),

                                  const SizedBox(height: 24),

                                  // Currency Breakdown Cards (Investor Payable only)
                                  _buildInvestorPayableSection(
                                    dashboardController,
                                  ),

                                  const SizedBox(height: 24),

                                  // Sales Monitor Section
                                  _buildExpandableSection(
                                    title: "Sales Monitor (Last Month)",
                                    isExpanded: _isSalesExpanded,
                                    onTap: () {
                                      setState(() {
                                        _isSalesExpanded = !_isSalesExpanded;
                                      });
                                    },
                                    child: _buildExpenseMonitorContent(),
                                  ),

                                  const SizedBox(height: 16),

                                  // Purchase Monitor Section
                                  _buildExpandableSection(
                                    title: "Purchase Monitor (Last Month)",
                                    isExpanded: _isPurchaseExpanded,
                                    onTap: () {
                                      setState(() {
                                        _isPurchaseExpanded =
                                            !_isPurchaseExpanded;
                                      });
                                    },
                                    child: _buildExpenseMonitorContent(),
                                  ),

                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary,
      // decoration: BoxDecoration(
      //   gradient: LinearGradient(
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //     colors: [primaryColor, secondaryColor],
      //   ),
      // ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s your business overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final quickActions = [
      {
        'title': 'Contacts',
        'icon': Icons.contact_page_outlined,
        'color': Colors.blue,
        'route': Screenroutes.contactsScreen,
      },
      {
        'title': 'Purchases',
        'icon': Icons.shopping_bag_outlined,
        'color': Colors.orange,
        'route': Screenroutes.purchaseListScreen,
      },
      {
        'title': 'Sales',
        'icon': Icons.shop_outlined,
        'color': Colors.green,
        'route': Screenroutes.salesListScreen,
      },
      {
        'title': 'Expenses',
        'icon': Icons.money_off_outlined,
        'color': Colors.red,
        'route': Screenroutes.expenseListScreen,
      },
      {
        'title': 'Financial\nTransactions',
        'icon': Icons.monetization_on_outlined,
        'color': Colors.purple,
        'route': Screenroutes.financialTransactions,
      },
      {
        'title': 'Reports',
        'icon': Icons.analytics_outlined,
        'color': Colors.teal,
        'route': Screenroutes.reportsHomeScreen,
      },
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: quickActions.length,
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return _buildQuickActionCard(
                  title: action['title'] as String,
                  icon: action['icon'] as IconData,
                  color: action['color'] as Color,
                  onTap: () {
                    NavigationService().pushNavigation(
                      action['route'] as String,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsOverviewSection(DashboardController controller) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Accounts Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAccountCard(
                    title: 'Cash in Hand',
                    data: controller.cashOnHand,
                    icon: Icons.payments_outlined,
                    color: Colors.green,
                    onTap: null, // Not clickable
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAccountCard(
                    title: 'Cash in Bank',
                    data: controller.amountInBank,
                    icon: Icons.account_balance_outlined,
                    color: Colors.blue,
                    onTap: () => _showBankAccountsDialog(controller),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard({
    required String title,
    required Map<String, dynamic>? data,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    double totalAmount = 0.0;
    if (data != null && data.isNotEmpty) {
      data.forEach((currency, amount) {
        final double amountValue = (amount is int) ? amount.toDouble() : amount;
        totalAmount += amountValue;
      });
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(data?.length ?? 0)} currencies',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankAccountsDialog(DashboardController controller) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bank Accounts'),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  controller.amountInBank != null &&
                          controller.amountInBank!.isNotEmpty
                      ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.amountInBank!.length,
                        itemBuilder: (context, index) {
                          final entry =
                              controller.amountInBank!.entries.toList()[index];
                          final currency = entry.key;
                          final amount = entry.value;
                          final double amountValue =
                              (amount is int) ? amount.toDouble() : amount;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: Text(
                                getCurrencyFlag(currency),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            title: Text(getCurrencyName(currency)),
                            subtitle: Text(currency),
                            trailing: Text(
                              formatCurrency(amountValue, currency),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToBankDetails(
                                currency,
                                amountValue,
                                controller,
                              );
                            },
                          );
                        },
                      )
                      : const Text('No bank account data available'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildInvestorPayableSection(DashboardController controller) {
    final Map<String, dynamic>? data = controller.investorPayable;
    if (data == null || data.isEmpty) return const SizedBox.shrink();

    final List<CurrencyBalance> currencyBalances = [];
    data.forEach((currency, amount) {
      final double amountValue = (amount is int) ? amount.toDouble() : amount;
      currencyBalances.add(
        CurrencyBalance(
          currency: getCurrencyName(currency),
          amount: amountValue,
          code: currency,
          flag: getCurrencyFlag(currency),
          color: getCurrencyColor(currency),
        ),
      );
    });

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Text(
                  'Investor Payable',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.05)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Currency',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  'Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...currencyBalances.map((balance) {
            final bool isNegative = balance.amount < 0;
            final double absAmount = balance.amount.abs();

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: balance.color.withOpacity(0.1),
                  child: Text(
                    balance.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                title: Text(
                  balance.currency,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  balance.code,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                trailing: Text(
                  isNegative
                      ? "-${formatCurrency(absAmount, balance.code)}"
                      : formatCurrency(balance.amount, balance.code),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isNegative ? Colors.red : null,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _navigateToBankDetails(
    String currency,
    double amount,
    DashboardController controller,
  ) {
    if (controller.allBankAccounts != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => BankDetailsScreen(
                currency: currency,
                amount: amount,
                bankAccounts: controller.allBankAccounts!,
              ),
        ),
      );
    } else {
      showErrorSnack('Bank account data not available');
    }
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseMonitorContent() {
    double sum = dailyExpenses.fold(0, (prev, curr) => prev + curr);
    double average = sum / dailyExpenses.length;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Month (${DateFormat('MMMM yyyy').format(currentMonth)})',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // SUM and AVE row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                label: 'SUM',
                value: sum,
                color: Colors.blue.shade700,
              ),
              _buildSummaryItem(
                label: 'AVE',
                value: average,
                color: Colors.green.shade700,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Daily expense grid
          _buildDailyExpenseGrid(),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyExpenseGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: List.generate(
              7, // Show 7 days per row for better mobile viewing
              (index) => Expanded(
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Data rows (split into 5 rows of 7 days, with the remainder in the last row)
        for (int row = 0; row < 5; row++)
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: List.generate(7, (col) {
                final dayIndex = row * 7 + col;
                // Only show cells up to 31 days
                if (dayIndex < 31) {
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          dailyExpenses[dayIndex].toString(),
                          style: TextStyle(
                            color:
                                dailyExpenses[dayIndex] > 0
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade600,
                            fontWeight:
                                dailyExpenses[dayIndex] > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  // Empty cell for days beyond 31
                  return const Expanded(child: SizedBox());
                }
              }),
            ),
          ),
      ],
    );
  }

  String formatCurrency(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      symbol: getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}

class CurrencyBalance {
  final String currency;
  final double amount;
  final String code;
  final String flag;
  final Color color;

  CurrencyBalance({
    required this.currency,
    required this.amount,
    required this.code,
    required this.flag,
    required this.color,
  });
}

enum TransactionType { sales, purchase }
