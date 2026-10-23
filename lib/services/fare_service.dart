import '../models/fare_media.dart';
import '../models/fare_product.dart';
import 'fare_catalog_service.dart';

class FareService {
  /// Finds all valid fare options for a specific leg between two stops.
  static List<FareProductOption> getOptionsForLeg({
    required String originStopId,
    required String destinationStopId,
    required List<FareProduct> allProducts,
    required List<FareMedia> allMedia,
    String? riderCategoryId,
    // Add fare_rules logic here if your KTEL uses them
  }) {
    // In the simplest KTEL case, we might just have a list of products.
    // Map media for quick lookup
    FareMedia? mediaLookup(String id) =>
        allMedia.cast<FareMedia?>().firstWhere((m) => m?.fareMediaId == id, orElse: () => null);

    // For now, filter products that apply to this specific route/leg
    // (This logic will expand when you get real fare_rules.txt data)
    return FareCatalogService.groupProducts(
      allProducts,
      mediaLookup: mediaLookup,
      riderCategoryId: riderCategoryId,
    ).expand((group) => group.options).toList();
  }

  static String fareAsString(double? fare) {
    return fare != null ? "${fare.toStringAsFixed(2)}€" : "-€";
  }

  static String formatPrice(double amount, String currency) {
    final symbol = currency == 'EUR' ? '€' : currency;
    return "${amount.toStringAsFixed(2)}$symbol";
  }
}
