// Main response model
class SalesResponse {
  final int statusCode;
  final String message;
  final bool isSuccess;
  final SalesData? data;

  SalesResponse({
    required this.statusCode,
    required this.message,
    required this.isSuccess,
    this.data,
  });

  factory SalesResponse.fromJson(Map<String, dynamic> json) {
    return SalesResponse(
      statusCode: json['StatusCode'] ?? 0,
      message: json['Message'] ?? '',
      isSuccess: json['IsSuccess'] ?? false,
      data: json['Data'] != null ? SalesData.fromJson(json['Data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'StatusCode': statusCode,
      'Message': message,
      'IsSuccess': isSuccess,
      'Data': data?.toJson(),
    };
  }
}

// Sales data model
class SalesData {
  final Sale? sale;
  final List<SaleDetail> saleDetail;

  SalesData({this.sale, required this.saleDetail});

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      sale: json['sale'] != null ? Sale.fromJson(json['sale']) : null,
      saleDetail:
          json['sale_detail'] != null
              ? (json['sale_detail'] as List)
                  .map((item) => SaleDetail.fromJson(item))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sale': sale?.toJson(),
      'sale_detail': saleDetail.map((item) => item.toJson()).toList(),
    };
  }
}

// Sale model
class Sale {
  final int id;
  final String customerId;
  final String currencyId;
  final String userId;
  final String invoiceNumber;
  final String saleDate;
  final String totalAmount;
  final String? description;
  final String paidBalance;
  final String remainingBalance;
  final String createdAt;
  final Customer? customer;
  final Currency? currency;
  final User? user;

  Sale({
    required this.id,
    required this.customerId,
    required this.currencyId,
    required this.userId,
    required this.invoiceNumber,
    required this.saleDate,
    required this.totalAmount,
    this.description,
    required this.paidBalance,
    required this.remainingBalance,
    required this.createdAt,
    this.customer,
    this.currency,
    this.user,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] ?? 0,
      customerId: json['customer_id']?.toString() ?? '',
      currencyId: json['currency_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      invoiceNumber: json['InvoiceNumber'] ?? '',
      saleDate: json['sale_date'] ?? '',
      totalAmount: json['total_amount']?.toString() ?? '',
      description: json['Description'],
      paidBalance: json['paidBalance']?.toString() ?? '',
      remainingBalance: json['remainingBalance']?.toString() ?? '',
      createdAt: json['created_at'] ?? '',
      customer:
          json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      currency:
          json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'currency_id': currencyId,
      'user_id': userId,
      'InvoiceNumber': invoiceNumber,
      'sale_date': saleDate,
      'total_amount': totalAmount,
      'Description': description,
      'paidBalance': paidBalance,
      'remainingBalance': remainingBalance,
      'created_at': createdAt,
      'customer': customer?.toJson(),
      'currency': currency?.toJson(),
      'user': user?.toJson(),
    };
  }
}

// Customer model
class Customer {
  final int id;
  final String name;

  Customer({required this.id, required this.name});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Name': name};
  }
}

// Currency model
class Currency {
  final int id;
  final String name;

  Currency({required this.id, required this.name});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Name': name};
  }
}

// User model
class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] ?? 0, name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

// Sale detail model
class SaleDetail {
  final int id;
  final String saleId;
  final String productId;
  final String unitId;
  final String qty;
  final String cost;
  final String taxPer;
  final String amount;
  final Product? product;
  final Unit? unit;

  SaleDetail({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.unitId,
    required this.qty,
    required this.cost,
    required this.taxPer,
    required this.amount,
    this.product,
    this.unit,
  });

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    return SaleDetail(
      id: json['id'] ?? 0,
      saleId: json['sale_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      unitId: json['unit_id']?.toString() ?? '',
      qty: json['qty']?.toString() ?? '',
      cost: json['cost']?.toString() ?? '',
      taxPer: json['tax_per']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'unit_id': unitId,
      'qty': qty,
      'cost': cost,
      'tax_per': taxPer,
      'amount': amount,
      'product': product?.toJson(),
      'unit': unit?.toJson(),
    };
  }
}

// Product model
class Product {
  final int id;
  final String name;

  Product({required this.id, required this.name});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Name': name};
  }
}

// Unit model
class Unit {
  final int id;
  final String name;

  Unit({required this.id, required this.name});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Name': name};
  }
}
