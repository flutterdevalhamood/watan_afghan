import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sample/src/screens/currencyConversions/conversion_summary_card.dart';
import 'package:sample/src/screens/currencyConversions/currency_conversion_detail_screen.dart';

class ConversionDetailContent extends StatelessWidget {
  final Map<String, dynamic>? data;

  const ConversionDetailContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final fromCurrency = data?['from_currency']['Name'];
    final toCurrency = data?['to_currency']['Name'];
    final fromAmount = double.parse(data?['from_amount']);
    final toAmount = double.parse(data?['to_amount']);
    final conversionRate = double.parse(data?['conversion_rate']);
    final referenceNumber = data?['referenceNumber'];
    final transactionDate = DateTime.parse(data?['transaction_date']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(transactionDate);
    final fromPaymentType = _capitalizeFirstLetter(data?['from_payment_type']);
    final toPaymentType = _capitalizeFirstLetter(data?['to_payment_type']);
    final description = data?['Description'] ?? '';

    // Extract new fields from API response
    final fromBankName =
        data?['from_bank'] != null ? data?['from_bank']?['Name'] : '';
    final toBankName =
        data?['to_bank'] != null ? data?['to_bank']?['Name'] : '';
    final userName = data?['user'] != null ? data?['user']?['name'] : '';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Conversion Summary
            ConversionSummaryCard(
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              fromAmount: fromAmount,
              toAmount: toAmount,
              conversionRate: conversionRate,
            ),

            const SizedBox(height: 24),

            // Transaction Details Section
            const Text(
              'Transaction Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            DetailCard(
              child: Column(
                children: [
                  DetailRow(
                    label: 'Reference Number',
                    value: referenceNumber,
                    isImportant: true,
                  ),
                  const Divider(),
                  DetailRow(label: 'Transaction Date', value: formattedDate),
                  const Divider(),
                  DetailRow(label: 'From Payment Type', value: fromPaymentType),
                  if (data?['from_bank_id'] != "0") ...[
                    const Divider(),
                    DetailRow(label: 'From Bank', value: fromBankName),
                  ],
                  const Divider(),
                  DetailRow(label: 'To Payment Type', value: toPaymentType),
                  if (data?['to_bank_id'] != "0") ...[
                    const Divider(),
                    DetailRow(label: 'To Bank', value: toBankName),
                  ],
                  const Divider(),
                  DetailRow(label: 'Processed By', value: userName),
                  if (description != null && description.isNotEmpty) ...[
                    const Divider(),
                    DetailRow(label: 'Description', value: description),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // User Information Section
            const Text(
              'Conversion Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            DetailCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Processed by $userName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.account_balance, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'From $fromBankName to $toBankName',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Add functionality to download/share receipt
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt downloading...')),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Download Receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
