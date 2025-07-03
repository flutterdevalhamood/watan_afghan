import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/dashboard_controller.dart';
import 'package:sample/src/util/currency_utils.dart';
import 'package:sample/src/widgets/drawer_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Future<bool> _onWillPop() async {
  //   bool? shouldLogout = await showDialog(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text('Logout'),
  //           content: const Text('Are you sure you want to logout?'),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(false),
  //               child: const Text('Cancel'),
  //             ),
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(true),
  //               child: const Text(
  //                 'Logout',
  //                 style: TextStyle(color: Colors.red),
  //               ),
  //             ),
  //           ],
  //         ),
  //   );
  //
  //   if (shouldLogout ?? false) {
  //     Navigator.of(context).pushReplacementNamed(Screenroutes.login);
  //     return true;
  //   }
  //   return false;
  // }

  final String accountName = "Y Account";
  final DateTime currentMonth = DateTime.now();
  final DateTime lastMonth = DateTime.now().subtract(const Duration(days: 30));

  // Expense data (all zeros for current month as shown in the image)
  final List<double> dailyExpenses = List.generate(31, (index) => 0.0);

  bool _isExpenseExpanded = true;
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
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: const Text('Account Dashboard'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // // Financial Overview Cards
                              // _buildFinancialOverviewSection(
                              //   dashboardController,
                              // ),
                              //
                              // const SizedBox(height: 24),

                              // Currency Breakdown Cards
                              _buildCurrencyBreakdownSection(
                                dashboardController,
                              ),

                              const SizedBox(height: 24),

                              // Sales Monitor Section
                              _buildExpandableSection(
                                title: "Sales Monitor(Last Month)",
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
                                title: "Purchase Monitor(Last Month)",
                                isExpanded: _isPurchaseExpanded,
                                onTap: () {
                                  setState(() {
                                    _isPurchaseExpanded = !_isPurchaseExpanded;
                                  });
                                },
                                child: _buildExpenseMonitorContent(),
                              ),

                              const SizedBox(height: 24),

                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.sync_alt,
                                    label: 'Transfer',
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 16),
                                  _buildActionButton(
                                    icon: Icons.history,
                                    label: 'History',
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 16),
                                  _buildActionButton(
                                    icon: Icons.download,
                                    label: 'Export',
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildCurrencyBreakdownSection(DashboardController controller) {
    List<Map<String, dynamic>> sections = [
      {
        "title": "Cash on Hand",
        "data": controller.cashOnHand,
        "icon": Icons.payments_outlined,
        "color": Colors.green,
      },
      {
        "title": "Amount in Bank",
        "data": controller.amountInBank,
        "icon": Icons.account_balance_outlined,
        "color": Colors.blue,
      },
      {
        "title": "Investor Payable",
        "data": controller.investorPayable,
        "icon": Icons.person_outline,
        "color": Colors.orange,
      },
    ];

    return Column(
      children:
          sections.map((section) {
            final Map<String, dynamic>? data = section["data"];
            if (data == null || data.isEmpty) return const SizedBox.shrink();

            final List<CurrencyBalance> currencyBalances = [];
            double sectionTotal = 0.0;

            data.forEach((currency, amount) {
              // Convert to double in case it's an integer in the JSON
              final double amountValue =
                  (amount is int) ? amount.toDouble() : amount;
              sectionTotal += amountValue;

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
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (section["color"] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            section["icon"] as IconData,
                            color: section["color"] as Color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          section["title"] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.05),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A6EBD),
                          ),
                        ),
                        Text(
                          'Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A6EBD),
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
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
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
                      ),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade700,
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
      padding: const EdgeInsets.all(16.0),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
