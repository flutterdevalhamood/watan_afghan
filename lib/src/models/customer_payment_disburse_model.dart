class CustomerInvoiceForDistributionResponse {
  final int statusCode;
  final String message;
  final bool isSuccess;
  final List<CustomerInvoiceForDistribution> data;

  CustomerInvoiceForDistributionResponse({
    required this.statusCode,
    required this.message,
    required this.isSuccess,
    required this.data,
  });

  factory CustomerInvoiceForDistributionResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CustomerInvoiceForDistributionResponse(
      statusCode: json['StatusCode'] ?? 0,
      message: json['Message'] ?? '',
      isSuccess: json['IsSuccess'] ?? false,
      data:
          (json['Data'] as List<dynamic>?)
              ?.map((e) => CustomerInvoiceForDistribution.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'StatusCode': statusCode,
      'Message': message,
      'IsSuccess': isSuccess,
      'Data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class CustomerInvoiceForDistribution {
  final int id;
  final String customerId;
  final String currencyId;
  final String invoiceNumber;
  final String purchaseDate;
  final String totalAmount;
  final String paidBalance;
  final String remainingBalance;
  final Currency currency;

  CustomerInvoiceForDistribution({
    required this.id,
    required this.customerId,
    required this.currencyId,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.totalAmount,
    required this.paidBalance,
    required this.remainingBalance,
    required this.currency,
  });

  factory CustomerInvoiceForDistribution.fromJson(Map<String, dynamic> json) {
    return CustomerInvoiceForDistribution(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? '',
      currencyId: json['currency_id'] ?? '',
      invoiceNumber: json['InvoiceNumber'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      totalAmount: json['total_amount'] ?? '0.00',
      paidBalance: json['paidBalance'] ?? '0.00',
      remainingBalance: json['remainingBalance'] ?? '0.00',
      currency: Currency.fromJson(json['currency'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'currency_id': currencyId,
      'InvoiceNumber': invoiceNumber,
      'purchase_date': purchaseDate,
      'total_amount': totalAmount,
      'paidBalance': paidBalance,
      'remainingBalance': remainingBalance,
      'currency': currency.toJson(),
    };
  }
}

class Currency {
  final int id;
  final String name;
  final String isBase;

  Currency({required this.id, required this.name, required this.isBase});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'] ?? 0,
      name: json['Name'] ?? '',
      isBase: json['isBase'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Name': name, 'isBase': isBase};
  }
}
