class SupplierPayment {
  final int id;
  final String supplierId;
  final String currencyId;
  final String referenceNumber;
  final String paidAmount;
  final String transferDate;
  final String isPushed;
  final SupplierInfo supplier;
  final CurrencyInfo currency;

  SupplierPayment({
    required this.id,
    required this.supplierId,
    required this.currencyId,
    required this.referenceNumber,
    required this.paidAmount,
    required this.transferDate,
    required this.isPushed,
    required this.supplier,
    required this.currency,
  });

  factory SupplierPayment.fromJson(Map<String, dynamic> json) {
    return SupplierPayment(
      id: json['id'] as int,
      supplierId: json['supplier_id'] as String? ?? '',
      currencyId: json['currency_id'] as String? ?? '',
      referenceNumber: json['referenceNumber'] as String? ?? '',
      paidAmount: json['paidAmount'] as String? ?? '0.00',
      transferDate: json['transferDate'] as String? ?? '',
      isPushed: json['isPushed'] as String? ?? '0',
      supplier: SupplierInfo.fromJson(json['supplier'] as Map<String, dynamic>),
      currency: CurrencyInfo.fromJson(json['currency'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'currency_id': currencyId,
      'referenceNumber': referenceNumber,
      'paidAmount': paidAmount,
      'transferDate': transferDate,
      'isPushed': isPushed,
      'supplier': supplier.toJson(),
      'currency': currency.toJson(),
    };
  }

  SupplierPayment copyWith({
    int? id,
    String? supplierId,
    String? currencyId,
    String? referenceNumber,
    String? paidAmount,
    String? transferDate,
    String? isPushed,
    SupplierInfo? supplier,
    CurrencyInfo? currency,
  }) {
    return SupplierPayment(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      currencyId: currencyId ?? this.currencyId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paidAmount: paidAmount ?? this.paidAmount,
      transferDate: transferDate ?? this.transferDate,
      isPushed: isPushed ?? this.isPushed,
      supplier: supplier ?? this.supplier,
      currency: currency ?? this.currency,
    );
  }
}

class SupplierInfo {
  final int id;
  final String name;

  SupplierInfo({required this.id, required this.name});

  factory SupplierInfo.fromJson(Map<String, dynamic> json) {
    return SupplierInfo(
      id: json['id'] as int,
      name: json['Name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Name': name};
  }
}

class CurrencyInfo {
  final int id;
  final String name;

  CurrencyInfo({required this.id, required this.name});

  factory CurrencyInfo.fromJson(Map<String, dynamic> json) {
    return CurrencyInfo(
      id: json['id'] as int,
      name: json['Name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Name': name};
  }
}
