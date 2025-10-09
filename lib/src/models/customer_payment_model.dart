class CustomerPayment {
  final int id;
  final String customerId;
  final String currencyId;
  final String referenceNumber;
  final String paidAmount;
  final String transferDate;
  final String isPushed;
  final CustomerInfo customer;
  final CurrencyInfo currency;

  CustomerPayment({
    required this.id,
    required this.customerId,
    required this.currencyId,
    required this.referenceNumber,
    required this.paidAmount,
    required this.transferDate,
    required this.isPushed,
    required this.customer,
    required this.currency,
  });

  factory CustomerPayment.fromJson(Map<String, dynamic> json) {
    return CustomerPayment(
      id: json['id'] as int,
      customerId: json['customer_id'] as String? ?? '',
      currencyId: json['currency_id'] as String? ?? '',
      referenceNumber: json['referenceNumber'] as String? ?? '',
      paidAmount: json['paidAmount'] as String? ?? '0.00',
      transferDate: json['transferDate'] as String? ?? '',
      isPushed: json['isPushed'] as String? ?? '0',
      customer: CustomerInfo.fromJson(json['customer'] as Map<String, dynamic>),
      currency: CurrencyInfo.fromJson(json['currency'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'currency_id': currencyId,
      'referenceNumber': referenceNumber,
      'paidAmount': paidAmount,
      'transferDate': transferDate,
      'isPushed': isPushed,
      'customer': customer.toJson(),
      'currency': currency.toJson(),
    };
  }

  CustomerPayment copyWith({
    int? id,
    String? customerId,
    String? currencyId,
    String? referenceNumber,
    String? paidAmount,
    String? transferDate,
    String? isPushed,
    CustomerInfo? customer,
    CurrencyInfo? currency,
  }) {
    return CustomerPayment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      currencyId: currencyId ?? this.currencyId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paidAmount: paidAmount ?? this.paidAmount,
      transferDate: transferDate ?? this.transferDate,
      isPushed: isPushed ?? this.isPushed,
      customer: customer ?? this.customer,
      currency: currency ?? this.currency,
    );
  }
}

class CustomerInfo {
  final int id;
  final String name;

  CustomerInfo({required this.id, required this.name});

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
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

class CustomerPaymentDetailResponse {
  final int statusCode;
  final String message;
  final bool isSuccess;
  final CustomerPaymentDetail data;

  CustomerPaymentDetailResponse({
    required this.statusCode,
    required this.message,
    required this.isSuccess,
    required this.data,
  });

  factory CustomerPaymentDetailResponse.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentDetailResponse(
      statusCode: json['StatusCode'] as int,
      message: json['Message'] as String? ?? '',
      isSuccess: json['IsSuccess'] as bool? ?? false,
      data: CustomerPaymentDetail.fromJson(
        json['Data'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'StatusCode': statusCode,
      'Message': message,
      'IsSuccess': isSuccess,
      'Data': data.toJson(),
    };
  }
}

class CustomerPaymentDetail {
  final String customerName;
  final String paymentDate;
  final String paymentType;
  final String referenceNumber;
  final String? description;
  final String amount;
  final String createdBy;
  final String createdAt;
  final List<PaymentDetail> details;
  final List<PaymentImage> images; // <-- FIXED here

  CustomerPaymentDetail({
    required this.customerName,
    required this.paymentDate,
    required this.paymentType,
    required this.referenceNumber,
    required this.description,
    required this.amount,
    required this.createdBy,
    required this.createdAt,
    required this.details,
    required this.images,
  });

  factory CustomerPaymentDetail.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentDetail(
      customerName: json['customer_name'] as String? ?? '',
      paymentDate: json['payment_date'] as String? ?? '',
      paymentType: json['payment_type'] as String? ?? '',
      referenceNumber: json['reference_number'] as String? ?? '',
      description: json['description']?.toString(),
      amount: json['amount'] as String? ?? '0.00',
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      details:
          (json['details'] as List<dynamic>? ?? [])
              .map((e) => PaymentDetail.fromJson(e as Map<String, dynamic>))
              .toList(),
      images:
          (json['images'] as List<dynamic>? ?? [])
              .map((e) => PaymentImage.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName,
      'payment_date': paymentDate,
      'payment_type': paymentType,
      'reference_number': referenceNumber,
      'description': description,
      'amount': amount,
      'created_by': createdBy,
      'created_at': createdAt,
      'details': details.map((e) => e.toJson()).toList(),
      'images': images.map((e) => e.toJson()).toList(),
    };
  }
}

class PaymentDetail {
  final String? invoiceId;
  final String? invoiceNumber;
  final String? appliedAmount;

  PaymentDetail({this.invoiceId, this.invoiceNumber, this.appliedAmount});

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      invoiceId: json['invoice_id']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      appliedAmount: json['applied_amount']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'invoice_number': invoiceNumber,
      'applied_amount': appliedAmount,
    };
  }
}

class PaymentImage {
  final String title;
  final String url;

  PaymentImage({required this.title, required this.url});

  factory PaymentImage.fromJson(Map<String, dynamic> json) {
    return PaymentImage(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'url': url};
  }
}
