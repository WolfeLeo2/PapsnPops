import 'promotion.dart';

class AppliedPromotion {
  final Promotion promotion;
  final String variantId;
  final int discountAmount;

  AppliedPromotion({
    required this.promotion,
    required this.variantId,
    required this.discountAmount,
  });
}
