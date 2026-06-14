class Invoice {
  final String id;
  final String saleId;
  final String branchId;
  final String customerId;
  final String invoiceNumber;
  final String status; // unpaid/paid/overdue
  final DateTime? dueDate;
  final String? notes;
  final DateTime? paidAt;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.saleId,
    required this.branchId,
    required this.customerId,
    required this.invoiceNumber,
    required this.status,
    this.dueDate,
    this.notes,
    this.paidAt,
    required this.createdAt,
  });

  factory Invoice.fromRow(Map<String, dynamic> row) {
    return Invoice(
      id: row['id'] as String,
      saleId: row['sale_id'] as String,
      branchId: row['branch_id'] as String,
      customerId: row['customer_id'] as String,
      invoiceNumber: row['invoice_number'] as String,
      status: row['status'] as String? ?? 'unpaid',
      dueDate: row['due_date'] != null
          ? DateTime.parse(row['due_date'] as String).toLocal()
          : null,
      notes: row['notes'] as String?,
      paidAt: row['paid_at'] != null
          ? DateTime.parse(row['paid_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'sale_id': saleId,
      'branch_id': branchId,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'status': status,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'notes': notes,
      'paid_at': paidAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
