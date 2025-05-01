import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/widgets/drawer_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _AccountDashboardState();
}

class _AccountDashboardState extends State<DashboardScreen> {
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

  // Hardcoded data - to be replaced with API data
  final String accountName = "Y Account";
  final double totalBalanceAED = 45872.63;

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
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Currency Breakdown Section
                const Text(
                  'Currency Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Currency Table
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      //Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
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

                      //Table Rows
                      ...currencyBalances.map((balance) {
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

                      //Summary footer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
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
                ),

                const SizedBox(height: 20),

                // Actions Row
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
