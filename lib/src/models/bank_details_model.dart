// Create a new file: bank_details_model.dart
class BankDetailsModel {
  final String currency;
  final double amount;
  final List<Map<String, dynamic>> bankAccounts;
  final String sectionTitle;
  final String? sourceScreen;

  BankDetailsModel({
    required this.currency,
    required this.amount,
    required this.bankAccounts,
    required this.sectionTitle,
    this.sourceScreen,
  });

  // Factory constructor for creating from dashboard data
  factory BankDetailsModel.fromDashboard({
    required String currency,
    required double amount,
    required List<Map<String, dynamic>> allBankAccounts,
    String? sourceScreen,
  }) {
    return BankDetailsModel(
      currency: currency,
      amount: amount,
      bankAccounts: allBankAccounts,
      sectionTitle: 'Amount in Bank',
      sourceScreen: sourceScreen ?? 'dashboard',
    );
  }

  // Factory constructor for creating from other screens (if needed in future)
  factory BankDetailsModel.fromTransfer({
    required String currency,
    required double amount,
    required List<Map<String, dynamic>> allBankAccounts,
  }) {
    return BankDetailsModel(
      currency: currency,
      amount: amount,
      bankAccounts: allBankAccounts,
      sectionTitle: 'Transfer Details',
      sourceScreen: 'transfer',
    );
  }

  // Get filtered bank accounts for this currency
  List<Map<String, dynamic>> get filteredBankAccounts {
    return bankAccounts.where((account) {
      return account['currency']['Name'] == currency;
    }).toList();
  }

  // Get total balance for this currency from all accounts
  double get totalAccountBalance {
    return filteredBankAccounts.fold(0.0, (sum, account) {
      return sum + ((account['currunt_balance'] ?? 0).toDouble());
    });
  }

  // Check if this currency has any bank accounts
  bool get hasAccounts {
    return filteredBankAccounts.isNotEmpty;
  }

  // Get account count for this currency
  int get accountCount {
    return filteredBankAccounts.length;
  }

  // Convert to map for logging or debugging
  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'amount': amount,
      'sectionTitle': sectionTitle,
      'sourceScreen': sourceScreen,
      'accountCount': accountCount,
      'hasAccounts': hasAccounts,
    };
  }
}
