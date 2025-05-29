class Supplier {
  final int id;
  final String name;
  final String mobile;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    required this.mobile,
    required this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? 0,
      name: json['Name'] ?? '',
      mobile: json['Mobile'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
