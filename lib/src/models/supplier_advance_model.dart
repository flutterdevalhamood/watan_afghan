class SupplierAdvance {
  final int id;
  final String supplierId;
  final String currencyId;
  final String receiptNumber;
  final String amount;
  final String transferDate;
  final String paymentType;
  final String? receiverName;
  final String? description;
  final String spentBalance;
  final String remainingBalance;
  final String isPushed;
  final String createdAt;
  final Supplier? supplier;
  final Currency? currency;
  final User? user;
  final List<SupplierAdvanceDetail> details;

  SupplierAdvance({
    required this.id,
    required this.supplierId,
    required this.currencyId,
    required this.receiptNumber,
    required this.amount,
    required this.transferDate,
    required this.paymentType,
    this.receiverName,
    this.description,
    this.spentBalance = '0.00',
    this.remainingBalance = '0.00',
    this.isPushed = '0',
    this.createdAt = '',
    this.supplier,
    this.currency,
    this.user,
    this.details = const [],
  });

  factory SupplierAdvance.fromJson(Map<String, dynamic> json) {
    return SupplierAdvance(
      id: json['id'] ?? 0,
      supplierId: json['supplier_id']?.toString() ?? '',
      currencyId: json['currency_id']?.toString() ?? '',
      receiptNumber: json['receiptNumber']?.toString() ?? '',
      amount: json['Amount']?.toString() ?? '0.00',
      transferDate: json['TransferDate']?.toString() ?? '',
      paymentType: json['paymentType']?.toString() ?? '',
      receiverName: json['receiverName']?.toString(),
      description: json['Description']?.toString(),
      spentBalance: json['spentBalance']?.toString() ?? '0.00',
      remainingBalance: json['remainingBalance']?.toString() ?? '0.00',
      isPushed: json['isPushed']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      supplier:
          json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
      currency:
          json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      details:
          (json['supplier_advance_detail'] as List<dynamic>?)
              ?.map((detail) => SupplierAdvanceDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'currency_id': currencyId,
      'receiptNumber': receiptNumber,
      'Amount': amount,
      'TransferDate': transferDate,
      'paymentType': paymentType,
      'receiverName': receiverName,
      'Description': description,
      'spentBalance': spentBalance,
      'remainingBalance': remainingBalance,
      'isPushed': isPushed,
      'created_at': createdAt,
      'supplier': supplier?.toJson(),
      'currency': currency?.toJson(),
      'user': user?.toJson(),
      'supplier_advance_detail':
          details.map((detail) => detail.toJson()).toList(),
    };
  }

  // Convenience getters for backward compatibility
  String get ReceiptNumber => receiptNumber;
  String get TransferDate => transferDate;
  String get Amount => amount;
  String get Description => description ?? '';
  String get RemainingBalance => remainingBalance;
  String get SpentBalance => spentBalance;

  // Helper methods
  String get formattedAmount => '${currency?.Name ?? ''} $amount';

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
      return '${date.year}/${date.month}/${date.day}/';
    } catch (e) {
      return transferDate;
    }
  }

  bool get isPushedBool => isPushed == '1';
}

class SupplierAdvanceDetail {
  final int id;
  final String supplierAdvanceId;
  final String amount;
  final String description;
  final String createdAt;
  final String? referenceNumber;

  SupplierAdvanceDetail({
    required this.id,
    required this.supplierAdvanceId,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.referenceNumber,
  });

  factory SupplierAdvanceDetail.fromJson(Map<String, dynamic> json) {
    return SupplierAdvanceDetail(
      id: json['id'] ?? 0,
      supplierAdvanceId: json['supplier_advance_id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_advance_id': supplierAdvanceId,
      'amount': amount,
      'description': description,
      'created_at': createdAt,
      'referenceNumber': referenceNumber,
    };
  }
}

// Reusing your existing models (unchanged)
class Supplier {
  final int id;
  final String name;

  Supplier({required this.id, required this.name});

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(id: json['id'] ?? 0, name: json['Name']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Name': name};
  }

  String get Name => name;
}

class Currency {
  final int id;
  final String name;

  Currency({required this.id, required this.name});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(id: json['id'] ?? 0, name: json['Name']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Name': name};
  }

  String get Name => name;
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] ?? 0, name: json['name']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class SupplierAdvanceWithDetails {
  final SupplierAdvance supplierAdvance;
  final List<SupplierAdvanceDetail> details;

  SupplierAdvanceWithDetails({
    required this.supplierAdvance,
    required this.details,
  });

  factory SupplierAdvanceWithDetails.fromJson(Map<String, dynamic> json) {
    return SupplierAdvanceWithDetails(
      supplierAdvance: SupplierAdvance.fromJson(json['supplier_advance']),
      details:
          (json['supplier_advance_detail'] as List)
              .map((item) => SupplierAdvanceDetail.fromJson(item))
              .toList(),
    );
  }
}
