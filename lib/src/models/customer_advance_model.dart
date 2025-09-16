class CustomerAdvance {
  final int id;
  final String customerId;
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
  final Customer? customer;
  final Currency? currency;
  final User? user;
  final List<CustomerAdvanceDetail> details;

  CustomerAdvance({
    required this.id,
    required this.customerId,
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
    this.customer,
    this.currency,
    this.user,
    this.details = const [],
  });

  factory CustomerAdvance.fromJson(Map<String, dynamic> json) {
    return CustomerAdvance(
      id: json['id'] ?? 0,
      customerId: json['customer_id']?.toString() ?? '',
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
      customer:
          json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      currency:
          json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      details:
          (json['customer_advance_detail'] as List<dynamic>?)
              ?.map((detail) => CustomerAdvanceDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
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
      'customer': customer?.toJson(),
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
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return transferDate;
    }
  }

  bool get isPushedBool => isPushed == '1';
}

class CustomerAdvanceDetail {
  final int id;
  final String customerAdvanceId;
  final String amount;
  final String description;
  final String createdAt;
  final String? referenceNumber;

  CustomerAdvanceDetail({
    required this.id,
    required this.customerAdvanceId,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.referenceNumber,
  });

  factory CustomerAdvanceDetail.fromJson(Map<String, dynamic> json) {
    return CustomerAdvanceDetail(
      id: json['id'] ?? 0,
      customerAdvanceId: json['customer_advance_id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_advance_id': customerAdvanceId,
      'amount': amount,
      'description': description,
      'created_at': createdAt,
      'referenceNumber': referenceNumber,
    };
  }
}

// Reusing your existing models (unchanged)
class Customer {
  final int id;
  final String name;

  Customer({required this.id, required this.name});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(id: json['id'] ?? 0, name: json['Name']?.toString() ?? '');
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

class CustomerAdvanceWithDetails {
  final CustomerAdvance customerAdvance;
  final List<CustomerAdvanceDetail> details;

  CustomerAdvanceWithDetails({
    required this.customerAdvance,
    required this.details,
  });

  factory CustomerAdvanceWithDetails.fromJson(Map<String, dynamic> json) {
    return CustomerAdvanceWithDetails(
      customerAdvance: CustomerAdvance.fromJson(json['customer_advance']),
      details:
          (json['customer_advance_detail'] as List)
              .map((item) => CustomerAdvanceDetail.fromJson(item))
              .toList(),
    );
  }
}
