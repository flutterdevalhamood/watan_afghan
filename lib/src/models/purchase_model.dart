class Purchase {
  final int id;
  final String supplierId;
  final String invoiceNumber;
  final String purchaseDate;
  final String totalAmount;
  final String currencyId;
  final Supplier? supplier;
  final Currency? currency;
  final String? description;
  final String paidBalance;
  final String remainingBalance;
  final String createdAt;
  final String userId;
  final User? user;

  Purchase({
    required this.id,
    required this.supplierId,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.totalAmount,
    required this.currencyId,
    this.supplier,
    this.currency,
    this.description,
    this.paidBalance = '0.00',
    this.remainingBalance = '0.00',
    this.createdAt = '',
    this.userId = '',
    this.user,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] ?? 0,
      supplierId: json['supplier_id']?.toString() ?? '',
      invoiceNumber: json['InvoiceNumber']?.toString() ?? '',
      purchaseDate: json['purchase_date']?.toString() ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0.00',
      currencyId: json['currency_id']?.toString() ?? '',
      supplier:
          json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
      currency:
          json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      description: json['Description']?.toString() ?? '',
      // Added missing fields parsing
      paidBalance: json['paidBalance']?.toString() ?? '0.00',
      remainingBalance: json['remainingBalance']?.toString() ?? '0.00',
      createdAt: json['created_at']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'InvoiceNumber': invoiceNumber,
      'purchase_date': purchaseDate,
      'total_amount': totalAmount,
      'currency_id': currencyId,
      'supplier': supplier?.toJson(),
      'currency': currency?.toJson(),
      'description': description,
      // Added missing fields to JSON
      'paidBalance': paidBalance,
      'remainingBalance': remainingBalance,
      'created_at': createdAt,
      'user_id': userId,
      'user': user?.toJson(),
    };
  }

  // Convenience getters for backward compatibility
  String get InvoiceNumber => invoiceNumber;
  String get purchase_date => purchaseDate;
  String get total_amount => totalAmount;
  String get Description => description ?? '';
}

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

  // Convenience getter for backward compatibility
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

  // Convenience getter for backward compatibility
  String get Name => name;
}

// Added User model for the user field in Purchase
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

class PurchaseDetail {
  final Purchase purchase;
  final List<PurchaseDetailItem> purchaseDetail;

  PurchaseDetail({required this.purchase, required this.purchaseDetail});

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseDetail(
      purchase: Purchase.fromJson(json['purchase']),
      purchaseDetail:
          (json['purchase_detail'] as List)
              .map((item) => PurchaseDetailItem.fromJson(item))
              .toList(),
    );
  }
}

class PurchaseDetailItem {
  final int id;
  final String purchaseId;
  final String productId;
  final String unitId;
  final String qty;
  final String cost;
  final String taxPer;
  final String taxAmount;
  final String amount;
  final Product? product;
  final Unit? unit;

  PurchaseDetailItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.unitId,
    required this.qty,
    required this.cost,
    required this.taxPer,
    required this.taxAmount,
    required this.amount,
    this.product,
    this.unit,
  });

  factory PurchaseDetailItem.fromJson(Map<String, dynamic> json) {
    return PurchaseDetailItem(
      id: json['id'],
      purchaseId: json['purchase_id'].toString(),
      productId: json['product_id'].toString(),
      unitId: json['unit_id'].toString(),
      qty: json['qty'].toString(),
      cost: json['cost'].toString(),
      taxPer: json['tax_per'].toString(),
      taxAmount: json['tax_amount'].toString(),
      amount: json['amount'].toString(),
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
    );
  }
}

class Product {
  final int id;
  final String name;

  Product({required this.id, required this.name});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(id: json['id'], name: json['Name']);
  }

  // Convenience getter for backward compatibility
  String get Name => name;
}

class Unit {
  final int id;
  final String name;

  Unit({required this.id, required this.name});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(id: json['id'], name: json['Name']);
  }

  String get Name => name;
}
