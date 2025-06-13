class Sales {
  final int id;
  final String invoiceNumber;
  final String customerId;
  final String saleDate;
  final String totalAmount;
  final String currencyId;
  final Customer customer;
  final Currency currency;

  Sales({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.saleDate,
    required this.totalAmount,
    required this.currencyId,
    required this.customer,
    required this.currency,
  });

  // Getter for InvoiceNumber to match your controller's search logic
  String get InvoiceNumber => invoiceNumber;

  factory Sales.fromJson(Map<String, dynamic> json) {
    return Sales(
      id: json['id'] ?? 0,
      invoiceNumber: json['InvoiceNumber'] ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      saleDate: json['sale_date'] ?? '',
      totalAmount: json['total_amount'] ?? '0.00',
      currencyId: json['currency_id']?.toString() ?? '',
      customer: Customer.fromJson(json['customer'] ?? {}),
      currency: Currency.fromJson(json['currency'] ?? {}),
    );
  }
}

class Customer {
  final int id;
  final String name;

  Customer({required this.id, required this.name});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }
}

class Currency {
  final int id;
  final String name;

  Currency({required this.id, required this.name});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }
}
