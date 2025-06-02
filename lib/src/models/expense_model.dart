class Expense {
  final int id;
  final String supplierId;
  final String referenceNumber;
  final String expenseDate;
  final String grandTotal;
  final String currencyId;
  final String createdAt;
  final Supplier supplier;
  final Currency currency;

  Expense({
    required this.id,
    required this.supplierId,
    required this.referenceNumber,
    required this.expenseDate,
    required this.grandTotal,
    required this.currencyId,
    required this.createdAt,
    required this.supplier,
    required this.currency,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? 0,
      supplierId: json['supplier_id']?.toString() ?? '',
      referenceNumber: json['referenceNumber'] ?? '',
      expenseDate: json['expenseDate'] ?? '',
      grandTotal: json['grandTotal']?.toString() ?? '0.00',
      currencyId: json['currency_id']?.toString() ?? '',
      createdAt: json['created_at'] ?? '',
      supplier: Supplier.fromJson(json['supplier'] ?? {}),
      currency: Currency.fromJson(json['currency'] ?? {}),
    );
  }

  // Helper method to format date
  String get formattedDate {
    try {
      final date = DateTime.parse(expenseDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return expenseDate;
    }
  }

  // Helper method to format amount with currency
  String get formattedAmount {
    return '${currency.name} $grandTotal';
  }
}

// Detailed expense model for the detail screen
class ExpenseDetail {
  final int id;
  final String supplierId;
  final String referenceNumber;
  final String expenseDate;
  final String subTotal;
  final String totalVat;
  final String grandTotal;
  final String currencyId;
  final String userId;
  final String employeeId;
  final String paymentType;
  final String createdAt;
  final User user;
  final List<ExpenseDetailItem> expenseDetails;
  final Supplier supplier;
  final Currency currency;
  final Employee? employee;
  final List<ExpenseImage> expenseImages;

  ExpenseDetail({
    required this.id,
    required this.supplierId,
    required this.referenceNumber,
    required this.expenseDate,
    required this.subTotal,
    required this.totalVat,
    required this.grandTotal,
    required this.currencyId,
    required this.userId,
    required this.employeeId,
    required this.paymentType,
    required this.createdAt,
    required this.user,
    required this.expenseDetails,
    required this.supplier,
    required this.currency,
    this.employee,
    required this.expenseImages,
  });

  factory ExpenseDetail.fromJson(Map<String, dynamic> json) {
    return ExpenseDetail(
      id: json['id'] ?? 0,
      supplierId: json['supplier_id']?.toString() ?? '',
      referenceNumber: json['referenceNumber'] ?? '',
      expenseDate: json['expenseDate'] ?? '',
      subTotal: json['subTotal']?.toString() ?? '0.00',
      totalVat: json['totalVat']?.toString() ?? '0.00',
      grandTotal: json['grandTotal']?.toString() ?? '0.00',
      currencyId: json['currency_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      paymentType: json['payment_type'] ?? '',
      createdAt: json['created_at'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      expenseDetails:
          (json['expense_details'] as List<dynamic>? ?? [])
              .map((item) => ExpenseDetailItem.fromJson(item))
              .toList(),
      supplier: Supplier.fromJson(json['supplier'] ?? {}),
      currency: Currency.fromJson(json['currency'] ?? {}),
      employee:
          json['employee'] != null ? Employee.fromJson(json['employee']) : null,
      expenseImages:
          (json['expense_images'] as List<dynamic>? ?? [])
              .map((item) => ExpenseImage.fromJson(item))
              .toList(),
    );
  }

  // Helper methods
  String get formattedDate {
    try {
      final date = DateTime.parse(expenseDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return expenseDate;
    }
  }

  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }

  String get formattedSubTotal => '${currency.name} $subTotal';
  String get formattedTotalVat => '${currency.name} $totalVat';
  String get formattedGrandTotal => '${currency.name} $grandTotal';
  String get formattedPaymentType => paymentType.toUpperCase();
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] ?? 0, name: json['name'] ?? 'Unknown User');
  }
}

class ExpenseDetailItem {
  final int id;
  final String expenseId;
  final String expenseCategoryId;
  final String description;
  final ExpenseCategory expenseCategory;

  ExpenseDetailItem({
    required this.id,
    required this.expenseId,
    required this.expenseCategoryId,
    required this.description,
    required this.expenseCategory,
  });

  factory ExpenseDetailItem.fromJson(Map<String, dynamic> json) {
    return ExpenseDetailItem(
      id: json['id'] ?? 0,
      expenseId: json['expense_id']?.toString() ?? '',
      expenseCategoryId: json['expense_category_id']?.toString() ?? '',
      description: json['Description'] ?? '',
      expenseCategory: ExpenseCategory.fromJson(json['expense_category'] ?? {}),
    );
  }
}

class ExpenseCategory {
  final int id;
  final String name;

  ExpenseCategory({required this.id, required this.name});

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] ?? 0,
      name: json['Name'] ?? 'Unknown Category',
    );
  }
}

class Employee {
  final int id;
  final String name;

  Employee({required this.id, required this.name});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Employee',
    );
  }
}

class ExpenseImage {
  final int id;
  final String imageUrl;
  final String imageName;

  ExpenseImage({
    required this.id,
    required this.imageUrl,
    required this.imageName,
  });

  factory ExpenseImage.fromJson(Map<String, dynamic> json) {
    return ExpenseImage(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      imageName: json['image_name'] ?? '',
    );
  }
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
