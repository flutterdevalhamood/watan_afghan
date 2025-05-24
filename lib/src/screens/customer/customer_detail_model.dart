class CustomerDetail {
  final int id;
  final String name;
  final String representative;
  final String companyTypeId;
  final String registrationDate;
  final String paymentTypeId;
  final String mobile;
  final String phone;
  final String email;
  final String address;
  final String regionId;
  final String postCode;
  final String latitude;
  final String longitude;
  final String? nationalIdNumber;
  final String businessLicenseFile;
  final String nationalIdFrontImage;
  final String nationalIdBackImage;
  final DateTime createdAt;
  final String userId;
  final String openingBalance;
  final String openingBalanceAsOfDate;
  final User user;
  final PaymentType paymentType;
  final CompanyType companyType;
  final Region region;

  CustomerDetail({
    required this.id,
    required this.name,
    required this.representative,
    required this.companyTypeId,
    required this.registrationDate,
    required this.paymentTypeId,
    required this.mobile,
    required this.phone,
    required this.email,
    required this.address,
    required this.regionId,
    required this.postCode,
    required this.latitude,
    required this.longitude,
    this.nationalIdNumber,
    required this.businessLicenseFile,
    required this.nationalIdFrontImage,
    required this.nationalIdBackImage,
    required this.createdAt,
    required this.userId,
    required this.openingBalance,
    required this.openingBalanceAsOfDate,
    required this.user,
    required this.paymentType,
    required this.companyType,
    required this.region,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      id: json['id'] ?? 0,
      name: json['Name'] ?? '',
      representative: json['Representative'] ?? '',
      companyTypeId: json['company_type_id'] ?? '',
      registrationDate: json['registrationDate'] ?? '',
      paymentTypeId: json['payment_type_id'] ?? '',
      mobile: json['Mobile'] ?? '',
      phone: json['Phone'] ?? '',
      email: json['Email'] ?? '',
      address: json['Address'] ?? '',
      regionId: json['region_id'] ?? '',
      postCode: json['postCode'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      nationalIdNumber: json['national_id_number'],
      businessLicenseFile: json['business_license_file'] ?? '',
      nationalIdFrontImage: json['national_id_front_image'] ?? '',
      nationalIdBackImage: json['national_id_back_image'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      userId: json['user_id']?.toString() ?? '',
      openingBalance: json['openingBalance'] ?? '0.00',
      openingBalanceAsOfDate: json['openingBalanceAsOfDate'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      paymentType: PaymentType.fromJson(json['payment_type'] ?? {}),
      companyType: CompanyType.fromJson(json['company_type'] ?? {}),
      region: Region.fromJson(json['region'] ?? {}),
    );
  }
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class PaymentType {
  final int id;
  final String name;

  PaymentType({required this.id, required this.name});

  factory PaymentType.fromJson(Map<String, dynamic> json) {
    return PaymentType(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }
}

class CompanyType {
  final int id;
  final String name;

  CompanyType({required this.id, required this.name});

  factory CompanyType.fromJson(Map<String, dynamic> json) {
    return CompanyType(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }
}

class Region {
  final int id;
  final String name;

  Region({required this.id, required this.name});

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(id: json['id'] ?? 0, name: json['Name'] ?? '');
  }
}

// Customer Model
class Customer {
  final int id;
  final String name;
  final String mobile;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['Name'] ?? '',
      mobile: json['Mobile'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
