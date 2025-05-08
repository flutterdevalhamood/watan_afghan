import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/widgets/drawer_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _FinancialDashboardState();
}

class _FinancialDashboardState extends State<DashboardScreen> {
  Future<bool> _onWillPop() async {
    bool? shouldLogout = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout ?? false) {
      Navigator.of(context).pushReplacementNamed(Screenroutes.login);
      return true;
    }
    return false;
  }

  final String accountName = "Y Account";
  final double totalBalanceAED = 45872.63;
  final DateTime currentMonth = DateTime.now();
  final DateTime lastMonth = DateTime.now().subtract(const Duration(days: 30));

  // Account currency data
  final List<CurrencyBalance> currencyBalances = [
    CurrencyBalance(
      currency: "AED",
      amount: 24500.00,
      code: "AED",
      flag: "🇦🇪",
      color: const Color(0xFF0A6EBD),
    ),
    CurrencyBalance(
      currency: "USD",
      amount: 3250.75,
      code: "USD",
      flag: "🇺🇸",
      color: const Color(0xFF2E8B57),
    ),
    CurrencyBalance(
      currency: "EUR",
      amount: 1785.22,
      code: "EUR",
      flag: "🇪🇺",
      color: const Color(0xFF4169E1),
    ),
    CurrencyBalance(
      currency: "INR",
      amount: 94500.50,
      code: "INR",
      flag: "🇮🇳",
      color: const Color(0xFFFF8C00),
    ),
  ];

  // Expense data (all zeros for current month as shown in the image)
  final List<double> dailyExpenses = List.generate(31, (index) => 0.0);

  // Sample data for sales and purchase reports
  final List<Transaction> salesTransactions = [
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 35)),
      description: 'Client A - Product Sale',
      amount: 1250.00,
      type: TransactionType.sales,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 32)),
      description: 'Client B - Service Fee',
      amount: 850.75,
      type: TransactionType.sales,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 30)),
      description: 'Client C - Subscription',
      amount: 499.99,
      type: TransactionType.sales,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 25)),
      description: 'Client D - Bulk Order',
      amount: 3200.50,
      type: TransactionType.sales,
    ),
  ];

  final List<Transaction> purchaseTransactions = [
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 40)),
      description: 'Vendor A - Office Supplies',
      amount: 325.45,
      type: TransactionType.purchase,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 38)),
      description: 'Vendor B - Equipment',
      amount: 1750.00,
      type: TransactionType.purchase,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 28)),
      description: 'Vendor C - Software License',
      amount: 599.99,
      type: TransactionType.purchase,
    ),
  ];

  bool _isExpenseExpanded = true;
  bool _isSalesExpanded = true;
  bool _isPurchaseExpanded = true;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: DrawerWidget(),
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Account Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Summary Card
                _buildAccountSummaryCard(),

                const SizedBox(height: 24),

                // Currency Breakdown Section
                _buildCurrencyBreakdownCard(),

                const SizedBox(height: 24),

                // Expense Monitor Section
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

                // Sales Report Section
                // _buildExpandableSection(
                //   title: "Sales Report (Last Month)",
                //   isExpanded: _isSalesExpanded,
                //   onTap: () {
                //     setState(() {
                //       _isSalesExpanded = !_isSalesExpanded;
                //     });
                //   },
                // child: _buildTransactionsContent(
                //   transactions: salesTransactions,
                //   totalLabel: 'Total Sales',
                //   iconData: Icons.shopping_cart_outlined,
                //   color: Colors.green.shade600,
                // ),
                // ),
                const SizedBox(height: 16),

                // Purchase Report Section
                // _buildExpandableSection(
                //   title: "Purchase Report (Last Month)",
                //   isExpanded: _isPurchaseExpanded,
                //   onTap: () {
                //     setState(() {
                //       _isPurchaseExpanded = !_isPurchaseExpanded;
                //     });
                //   },
                // child: _buildTransactionsContent(
                //   transactions: purchaseTransactions,
                //   totalLabel: 'Total Purchases',
                //   iconData: Icons.shopping_bag_outlined,
                //   color: Colors.blue.shade600,
                // ),
                // ),
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
  }

  Widget _buildAccountSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  accountName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Color(0xFF0A6EBD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Total Balance',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(totalBalanceAED, 'AED'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A6EBD),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyBreakdownCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'Currency Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Currency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A6EBD),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A6EBD),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...currencyBalances.map((balance) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: Text(
                    formatCurrency(balance.amount, balance.code),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),

          // Summary footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total (in AED)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatCurrency(totalBalanceAED, 'AED'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A6EBD),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  // Widget _buildTransactionsContent({
  //   required List<Transaction> transactions,
  //   required String totalLabel,
  //   required IconData iconData,
  //   required Color color,
  // }) {
  //   // Calculate total
  //   double total = transactions.fold(
  //     0,
  //     (prev, transaction) => prev + transaction.amount,
  //   );
  //
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Period: ${DateFormat('d MMM').format(lastMonth)} - ${DateFormat('d MMM yyyy').format(currentMonth)}',
  //           style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
  //         ),
  //         const SizedBox(height: 16),
  //
  //         // Transactions list
  //         ...transactions.map(
  //           (transaction) => _buildTransactionItem(
  //             transaction,
  //             iconData: iconData,
  //             color: color,
  //           ),
  //         ),
  //
  //         const SizedBox(height: 16),
  //         const Divider(thickness: 1),
  //
  //         // Total row
  //         Padding(
  //           padding: const EdgeInsets.symmetric(vertical: 10),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 totalLabel,
  //                 style: const TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //               Text(
  //                 NumberFormat.currency(
  //                   symbol: '\$',
  //                   decimalDigits: 2,
  //                 ).format(total),
  //                 style: TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 18,
  //                   color: color,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTransactionItem(
    Transaction transaction, {
    required IconData iconData,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(transaction.date),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 2,
            ).format(transaction.amount),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
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

  String getCurrencySymbol(String code) {
    switch (code) {
      case 'AED':
        return 'AED ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'INR':
        return '₹';
      default:
        return '';
    }
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

class Transaction {
  final DateTime date;
  final String description;
  final double amount;
  final TransactionType type;

  Transaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
  });
}
