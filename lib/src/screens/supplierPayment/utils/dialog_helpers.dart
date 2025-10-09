import 'package:flutter/material.dart';

/// Helper class for showing dialogs
class DialogHelpers {
  /// Show confirmation dialog for payment
  static Future<bool> showPaymentConfirmation({
    required BuildContext context,
    required Map<String, String> paymentDetails,
    int? selectedInvoicesCount,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.save_outlined, color: Color(0xFF26A69A)),
              SizedBox(width: 8),
              Text('Confirm Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to save this payment?',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...paymentDetails.entries
                        .map(
                          (e) => _ConfirmationRow(label: e.key, value: e.value),
                        )
                        .toList()
                        .expand((widget) => [widget, const SizedBox(height: 4)])
                        .toList()
                      ..removeLast(),
                    if (selectedInvoicesCount != null &&
                        selectedInvoicesCount > 0) ...[
                      const SizedBox(height: 4),
                      _ConfirmationRow(
                        label: 'Selected Invoices:',
                        value: '$selectedInvoicesCount',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF26A69A)),
        );
      },
    );
  }

  /// Show date picker
  static Future<DateTime?> showCustomDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF26A69A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

/// Private widget for confirmation row
class _ConfirmationRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmationRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF26A69A),
            ),
          ),
        ),
      ],
    );
  }
}
