/// Helper class for payment-related utilities
class PaymentHelpers {
  /// Format amount to 2 decimal places
  static String formatAmount(String amount) {
    try {
      final double value = double.parse(amount);
      return value.toStringAsFixed(2);
    } catch (e) {
      return amount;
    }
  }

  /// Format date string to dd/MM/yyyy
  static String formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Calculate total from list of amounts
  static double calculateTotal(List<String> amounts) {
    double total = 0.0;
    for (var amount in amounts) {
      total += double.tryParse(amount) ?? 0.0;
    }
    return total;
  }

  /// Check if payment type requires bank details
  static bool requiresBankDetails(String? paymentType) {
    return paymentType == 'Cheque' || paymentType == 'Bank Transfer';
  }

  /// Validate paying amount against payable amount
  static String? validatePayingAmount({
    required double payingAmount,
    required double payableAmount,
    required bool hasSelectedInvoices,
  }) {
    if (payingAmount <= 0) {
      return 'Paying amount must be greater than zero';
    }

    if (hasSelectedInvoices && payingAmount > payableAmount) {
      return 'Paying amount cannot exceed total payable amount';
    }

    return null;
  }
}
