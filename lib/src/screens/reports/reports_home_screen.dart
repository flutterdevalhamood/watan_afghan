import 'package:flutter/material.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Report Type',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose from the available reports below',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  ReportTile(
                    title: 'Sales Report',
                    icon: Icons.trending_up,
                    color: Colors.green,
                    onTap: () {
                      NavigationService().pushNavigation(
                        Screenroutes.salesReportScreen,
                      );
                    },
                  ),
                  ReportTile(
                    title: 'Purchase Report',
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                    onTap: () {
                      NavigationService().pushNavigation(
                        Screenroutes.purchaseReportScreen,
                      );
                    },
                  ),
                  ReportTile(
                    title: 'Expense Report',
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                    onTap: () {
                      NavigationService().pushNavigation(
                        Screenroutes.expenseReportScreen,
                      );
                    },
                  ),
                  ReportTile(
                    title: 'Landscape Expense Report',
                    icon: Icons.landscape,
                    color: Colors.purple,
                    onTap:
                        () => _navigateToReport(
                          context,
                          'Landscape Expense Report',
                        ),
                  ),
                  ReportTile(
                    title: 'Cash Report',
                    icon: Icons.account_balance_wallet,
                    color: Colors.teal,
                    onTap: () {
                      NavigationService().pushNavigation(
                        Screenroutes.cashReportScreen,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReport(BuildContext context, String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $reportType...'),
        backgroundColor: Colors.indigo[600],
        duration: const Duration(seconds: 2),
      ),
    );
    // Add your navigation logic here
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ReportDetailScreen(reportType: reportType)));
  }
}

class ReportTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ReportTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Report',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
