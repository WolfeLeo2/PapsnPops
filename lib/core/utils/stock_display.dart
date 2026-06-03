import '../../domain/models/product.dart';
import '../../domain/models/product_variant.dart';

class StockDisplay {
  static String format(
    Product product,
    int rawQuantity,
    List<ProductVariant> variants,
  ) {
    if (product.baseUnit == 'piece') {
      if (variants.length == 1) {
        return '$rawQuantity in stock';
      } else {
        // e.g. 120 Single Bottles
        final base = variants.firstWhere(
          (v) => v.conversionFactor == 1,
          orElse: () => variants.first,
        );
        return '$rawQuantity ${base.name}s';
      }
    } else {
      // By volume
      if (product.containerSize == null || product.containerName == null) {
        return '$rawQuantity ml';
      }

      final containerSize = product.containerSize!;
      final fullContainers = rawQuantity ~/ containerSize;
      final remainderMl = rawQuantity % containerSize;

      if (remainderMl == 0) {
        return '$fullContainers ${product.containerName}s';
      } else {
        // find smallest serving
        final servings = variants
            .where((v) => v.conversionFactor < containerSize)
            .toList();
        if (servings.isEmpty) {
          return fullContainers > 0
              ? '$fullContainers ${product.containerName}s, ${remainderMl}ml left'
              : '${remainderMl}ml left';
        }
        servings.sort(
          (a, b) => a.conversionFactor.compareTo(b.conversionFactor),
        );
        final smallest = servings.first;
        final remainderInSmallest = remainderMl ~/ smallest.conversionFactor;

        if (fullContainers > 0) {
          return '$fullContainers ${product.containerName}s, $remainderInSmallest ${smallest.name}s left';
        } else {
          return '$remainderInSmallest ${smallest.name}s left';
        }
      }
    }
  }

  static double toContainers(int rawQuantity, int containerSize) {
    return rawQuantity / containerSize;
  }

  static int fromContainers(double containers, int containerSize) {
    return (containers * containerSize).round();
  }

  static String formatVariantStock(int rawQuantity, ProductVariant variant) {
    final amount = rawQuantity ~/ variant.conversionFactor;
    return '$amount ${variant.name}${amount == 1 ? '' : 's'}';
  }
}
