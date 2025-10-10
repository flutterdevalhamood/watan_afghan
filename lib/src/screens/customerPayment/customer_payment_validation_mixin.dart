import 'package:sample/src/providers/customer_payment_controller.dart';

/// Mixin for form validation logic
mixin CustomerPaymentValidationMixin {
  // Validation flags - to be implemented by the class using this mixin
  bool get currencyTouched;
  bool get customerTouched;
  bool get paymentTypeTouched;
  bool get bankTouched;
  bool get accountNumberTouched;
  bool get totalPayingTouched;
  bool get paidByTouched;

  // Field values - to be implemented by the class using this mixin
  String? get selectedPaymentType;
  String get accountNumber;
  String get totalPaying;
  String get paidBy;

  String? validateCurrency(CustomerPaymentController controller) {
    if (currencyTouched && controller.selectedCurrencyId == null) {
      return 'Please select a currency';
    }
    return null;
  }

  String? validateCustomer(CustomerPaymentController controller) {
    if (customerTouched && controller.selectedCustomerId == null) {
      return 'Please select a customer';
    }
    return null;
  }

  String? validatePaymentType() {
    if (paymentTypeTouched && selectedPaymentType == null) {
      return 'Please select payment type';
    }
    return null;
  }

  String? validateBank(CustomerPaymentController controller) {
    if ((selectedPaymentType == 'Cheque' ||
            selectedPaymentType == 'Bank Transfer') &&
        bankTouched &&
        controller.selectedBankId == null) {
      return 'Please select a bank';
    }
    return null;
  }

  String? validateAccountNumber() {
    if ((selectedPaymentType == 'Cheque' ||
            selectedPaymentType == 'Bank Transfer') &&
        accountNumberTouched &&
        accountNumber.isEmpty) {
      return 'Please enter account number';
    }
    return null;
  }

  String? validateTotalPaying() {
    if (totalPayingTouched && totalPaying.isEmpty) {
      return 'Please enter paying amount';
    }
    if (totalPayingTouched) {
      final amount = double.tryParse(totalPaying);
      if (amount == null || amount <= 0) {
        return 'Amount must be greater than zero';
      }
    }
    return null;
  }

  String? validatePaidBy() {
    if (paidByTouched && paidBy.isEmpty) {
      return 'Please enter paid by name';
    }
    return null;
  }

  bool validateAllRequiredFields(CustomerPaymentController controller) {
    if (controller.selectedCurrencyId == null) return false;
    if (controller.selectedCustomerId == null) return false;
    if (selectedPaymentType == null) return false;
    if (totalPaying.isEmpty) return false;
    if (paidBy.isEmpty) return false;

    if (selectedPaymentType == 'Cheque' ||
        selectedPaymentType == 'Bank Transfer') {
      if (controller.selectedBankId == null) return false;
      if (accountNumber.isEmpty) return false;
    }

    final payingAmount = double.tryParse(totalPaying);
    if (payingAmount == null || payingAmount <= 0) return false;

    return true;
  }
}
