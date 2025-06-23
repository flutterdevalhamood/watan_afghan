class SupplierAdvance {
  final int id;
  final String supplierId;
  final String currencyId;
  final String receiptNumber;
  final String amount;
  final String transferDate;
  final String isPushed;
  final Supplier supplier;
  final Currency currency;

  SupplierAdvance({
    required this.id,
    required this.supplierId,
    required this.currencyId,
    required this.receiptNumber,
    required this.amount,
    required this.transferDate,
    required this.isPushed,
    required this.supplier,
    required this.currency,
  });

  factory SupplierAdvance.fromJson(Map<String, dynamic> json) {
    return SupplierAdvance(
      id: json['id'] ?? 0,
      supplierId: json['supplier_id']?.toString() ?? '',
      currencyId: json['currency_id']?.toString() ?? '',
      receiptNumber: json['receiptNumber'] ?? '',
      amount: json['Amount'] ?? '0.00',
      transferDate: json['TransferDate'] ?? '',
      isPushed: json['isPushed']?.toString() ?? '0',
      supplier: Supplier.fromJson(json['supplier'] ?? {}),
      currency: Currency.fromJson(json['currency'] ?? {}),
    );
  }

  // Helper getters
  String get formattedAmount => '${currency.name} $amount';

  DateTime get transferDateParsed {
    try {
      return DateTime.parse(transferDate);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedDate {
    try {
      final date = transferDateParsed;
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return transferDate;
    }
  }

  bool get isPushedBool => isPushed == '1';
}

class Supplier {
  final int id;
  final String name;

  Supplier({required this.id, required this.name});

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? 0,
      name: json['Name'] ?? 'Unknown Supplier',
    );
  }
}

class Currency {
  final int id;
  final String name;

  Currency({required this.id, required this.name});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(id: json['id'] ?? 0, name: json['Name'] ?? 'USD');
  }
}
