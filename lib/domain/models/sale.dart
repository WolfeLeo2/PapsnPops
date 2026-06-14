import 'dart:convert';

class Sale {
  final String id;
  final String branchId;
  final String cashierId;
  final String? staffId;
  final String? customerId;
  final String paymentMethod;
  final String? paymentReference;
  final int subtotal;
  final int discountAmount;
  final int total;
  final List<String>? promotionIds;
  final bool isVoided;
  final String? voidedBy;
  final DateTime? voidedAt;
  final String source;
  final String? tabId;
  final DateTime createdAt;

  Sale({
    required this.id,
    required this.branchId,
    required this.cashierId,
    this.staffId,
    this.customerId,
    required this.paymentMethod,
    this.paymentReference,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    this.promotionIds,
    required this.isVoided,
    this.voidedBy,
    this.voidedAt,
    required this.source,
    this.tabId,
    required this.createdAt,
  });

  factory Sale.fromRow(Map<String, dynamic> row) {
    List<String>? promotionIds;
    final promoRaw = row['promotion_ids'];
    if (promoRaw is String) {
      try {
        final decoded = jsonDecode(promoRaw);
        if (decoded is List) {
          promotionIds = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // ignore
      }
    } else if (promoRaw is List) {
      promotionIds = promoRaw.map((e) => e.toString()).toList();
    }

    return Sale(
      id: row['id'] as String,
      branchId: row['branch_id'] as String,
      cashierId: row['cashier_id'] as String,
      staffId: row['staff_id'] as String?,
      customerId: row['customer_id'] as String?,
      paymentMethod: row['payment_method'] as String,
      paymentReference: row['payment_reference'] as String?,
      subtotal: row['subtotal'] as int? ?? 0,
      discountAmount: row['discount_amount'] as int? ?? 0,
      total: row['total'] as int? ?? 0,
      promotionIds: promotionIds,
      isVoided: (row['is_voided'] as int? ?? 0) == 1,
      voidedBy: row['voided_by'] as String?,
      voidedAt: row['voided_at'] != null
          ? DateTime.parse(row['voided_at'] as String).toLocal()
          : null,
      source: row['source'] as String? ?? 'pos',
      tabId: row['tab_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'branch_id': branchId,
      'cashier_id': cashierId,
      'staff_id': staffId?.isEmpty == true ? null : staffId,
      'customer_id': customerId?.isEmpty == true ? null : customerId,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference?.isEmpty == true ? null : paymentReference,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'total': total,
      'promotion_ids': (promotionIds != null && promotionIds!.isNotEmpty) ? jsonEncode(promotionIds) : null,
      'is_voided': isVoided ? 1 : 0,
      'voided_by': voidedBy?.isEmpty == true ? null : voidedBy,
      'voided_at': voidedAt?.toUtc().toIso8601String(),
      'source': source,
      'tab_id': tabId?.isEmpty == true ? null : tabId,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
