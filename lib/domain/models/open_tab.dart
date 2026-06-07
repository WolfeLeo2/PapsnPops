class OpenTab {
  final String id;
  final String branchId;
  final String name;
  final String? phone;
  final String? openedBy;
  final String? customerId;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final String? saleId;

  OpenTab({
    required this.id,
    required this.branchId,
    required this.name,
    this.phone,
    this.openedBy,
    this.customerId,
    required this.isOpen,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.saleId,
  });

  factory OpenTab.fromRow(Map<String, dynamic> row) {
    return OpenTab(
      id: row['id'] as String,
      branchId: row['branch_id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      openedBy: row['opened_by'] as String?,
      customerId: row['customer_id'] as String?,
      isOpen: (row['is_open'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : (row['created_at'] != null
              ? DateTime.parse(row['created_at'] as String)
              : DateTime.now()),
      closedAt: row['closed_at'] != null
          ? DateTime.parse(row['closed_at'] as String)
          : null,
      saleId: row['sale_id'] as String?,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'phone': phone,
      'opened_by': openedBy?.isEmpty == true ? null : openedBy,
      'customer_id': customerId?.isEmpty == true ? null : customerId,
      'is_open': isOpen ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'sale_id': saleId?.isEmpty == true ? null : saleId,
    };
  }
}
