class Branch {
  final String id;
  final String name;
  final String? location;
  final String? phone;
  final DateTime? createdAt;

  Branch({
    required this.id,
    required this.name,
    this.location,
    this.phone,
    this.createdAt,
  });

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String?,
      phone: map['phone'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
