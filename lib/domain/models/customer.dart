class Customer {
  final String id;
  final String organisationId;
  final String name;
  final String phone;
  final String? companyName;
  final String? address;
  final String? email;
  final int loyaltyPoints;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.organisationId,
    required this.name,
    required this.phone,
    this.companyName,
    this.address,
    this.email,
    this.loyaltyPoints = 0,
    required this.createdAt,
  });

  factory Customer.fromRow(Map<String, dynamic> row) {
    return Customer(
      id: row['id'] as String,
      organisationId: row['organisation_id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String,
      companyName: row['company_name'] as String?,
      address: row['address'] as String?,
      email: row['email'] as String?,
      loyaltyPoints: row['loyalty_points'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'organisation_id': organisationId,
      'name': name,
      'phone': phone,
      'company_name': companyName,
      'address': address,
      'email': email,
      'loyalty_points': loyaltyPoints,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
