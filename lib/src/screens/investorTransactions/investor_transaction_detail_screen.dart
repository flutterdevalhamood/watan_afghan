import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/investor_transaction_controller.dart';

class InvestorTransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction;

  const InvestorTransactionDetailScreen({super.key, required this.transaction});

  @override
  State<InvestorTransactionDetailScreen> createState() =>
      _InvestorTransactionDetailScreenState();
}

class _InvestorTransactionDetailScreenState
    extends State<InvestorTransactionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<InvestorTransactionController>(
        context,
        listen: false,
      );
      controller.id = widget.transaction?['id'];
      controller.getInvestorTransactionDetail();
    });
  }

  String _getTransactionTypeText(String type) {
    switch (type) {
      case '1':
        return 'Deposit';
      case '2':
        return 'Withdrawal';
      default:
        return 'Unknown';
    }
  }

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case '1':
        return Colors.green;
      case '2':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        // systemOverlayStyle: const SystemUiOverlayStyle(
        //   statusBarColor: Colors.transparent,
        //   statusBarIconBrightness: Brightness.dark,
        // ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF222B45)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<InvestorTransactionController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${controller.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      controller.getInvestorTransactionDetail();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (controller.transactionData == null ||
              controller.transactionData!.isEmpty) {
            return const Center(
              child: Text(
                'No transaction details found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final transaction = controller.transactionData![0];
          final transactionType = transaction['transaction_type'] as String;
          final typeText = _getTransactionTypeText(transactionType);
          final typeColor = _getTransactionTypeColor(transactionType);
          final amount = double.parse(transaction['totalAmount']);
          final formattedAmount = NumberFormat.currency(
            symbol: transaction['currency']['Name'],
          ).format(amount);

          // Format the transfer date
          final transferDate =
              transaction['transferDate'] != null
                  ? DateFormat(
                    'MMM dd, yyyy',
                  ).format(DateTime.parse(transaction['transferDate']))
                  : 'N/A';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTransactionHeader(
                    transaction,
                    typeText,
                    typeColor,
                    formattedAmount,
                  ),
                  const SizedBox(height: 24),
                  _buildTransactionDetails(transaction, transferDate),
                  const SizedBox(height: 24),
                  _buildAdditionalInfo(transaction),
                  const SizedBox(height: 24),
                  if (transaction['Description'] != null)
                    _buildDescriptionSection(transaction['Description']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionHeader(
    Map<String, dynamic> transaction,
    String typeText,
    Color typeColor,
    String formattedAmount,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                typeText == 'Deposit'
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: typeColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              formattedAmount,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                typeText,
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(
    Map<String, dynamic> transaction,
    String transferDate,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222B45),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              'Investor',
              transaction['investor']['Name'],
              Icons.person,
            ),
            const Divider(height: 30),
            _buildDetailRow(
              'Reference Number',
              transaction['referenceNumber'],
              Icons.receipt_long,
            ),
            const Divider(height: 30),
            _buildDetailRow(
              'Transaction ID',
              '#${transaction['id']}',
              Icons.tag,
            ),
            const Divider(height: 30),
            _buildDetailRow('Date', transferDate, Icons.calendar_today),
            const Divider(height: 30),
            _buildDetailRow(
              'Payment Method',
              transaction['payment_type']?.toString().toUpperCase() ?? 'N/A',
              Icons.payment,
            ),
            if (transaction['accountNumber'] != null) ...[
              const Divider(height: 30),
              _buildDetailRow(
                'Account Number',
                transaction['accountNumber'],
                Icons.account_balance,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(Map<String, dynamic> transaction) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222B45),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              'Currency',
              transaction['currency']['Name'],
              Icons.monetization_on,
            ),
            const Divider(height: 30),
            _buildDetailRow(
              'Person Name',
              transaction['PersonName'] ?? 'N/A',
              Icons.person_outline,
            ),
            const Divider(height: 30),
            _buildDetailRow(
              'Processed By',
              transaction['user']['name'],
              Icons.badge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222B45),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF8F9BB3),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF8F9BB3), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF8F9BB3)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF222B45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
