import 'package:ktel_transit/models/fare_media.dart';
import 'package:ktel_transit/models/fare_product.dart';

/// One price of a product: for a specific media, or for any media.
class FareProductOption {
  final FareProduct product;

  /// The resolved media. Null when the product is valid on any media, or
  /// when it references a media that is not defined in fare_media.txt.
  final FareMedia? media;

  const FareProductOption({required this.product, this.media});
}

/// All the prices of one fare product (same fare_product_id), e.g. a
/// "Single ticket" that costs differently on the driver and on the card.
class FareProductGroup {
  final String fareProductId;
  final String name;
  final List<FareProductOption> options;

  const FareProductGroup({
    required this.fareProductId,
    required this.name,
    required this.options,
  });
}

/// A pure logic service for turning the raw fare products of a region into
/// what the Tickets screen presents.
class FareCatalogService {
  /// Groups [products] by fare_product_id, keeping the order of the file
  /// (both for the groups and for the options inside each group), since the
  /// region author decides the order and the spec has no sort field.
  ///
  /// Discounts (negative amounts) are not something a rider can buy, so they
  /// are left out. When [riderCategoryId] is given, only products of that
  /// category (or products valid for any category) are kept. When it is null
  /// no category filtering is applied.
  static List<FareProductGroup> groupProducts(
      List<FareProduct> products, {
        required FareMedia? Function(String fareMediaId) mediaLookup,
        String? riderCategoryId,
      }) {
    // A map literal keeps insertion order, which is what we want here
    final Map<String, List<FareProduct>> byProductId = {};

    for (final product in products) {
      if (product.isDiscount) continue;

      final bool matchesCategory =
          riderCategoryId == null ||
              product.isValidForAnyRiderCategory ||
              product.riderCategoryId == riderCategoryId;
      if (!matchesCategory) continue;

      byProductId.putIfAbsent(product.fareProductId, () => []).add(product);
    }

    return byProductId.entries.map((entry) {
      return FareProductGroup(
        fareProductId: entry.key,
        name: entry.value.first.name,
        options: entry.value.map((product) {
          final mediaId = product.fareMediaId;
          return FareProductOption(
            product: product,
            media: mediaId == null ? null : mediaLookup(mediaId),
          );
        }).toList(),
      );
    }).toList();
  }
}