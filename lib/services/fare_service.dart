import 'package:ktel_transit/models/fare_leg_rules.dart';
import '../models/fare_media.dart';
import '../models/fare_product.dart';
import '../models/fare_transfer_rules.dart';
import 'fare_catalog_service.dart';

class FareService {
  /// Finds all valid fare options for a specific leg between two stops.
  /// This is the connection point between a trip's leg and the fare computing
  /// service. Callers needing to know their fare options should call this
  /// function.
  static List<FareProductOption> getOptionsForLeg({
    required String originStopId,
    required String destinationStopId,
    required Map<String, List<FareLegRule>> rulesByNetworkId,
    required List<FareProduct> allProducts,
    required List<FareMedia> allMedia,
    String? riderCategoryId,
    // Add fare_rules logic here if your KTEL uses them
  }) {
    // In the simplest KTEL case, we might just have a list of products.
    // Map media for quick lookup
    FareMedia? mediaLookup(String id) => allMedia.cast<FareMedia?>().firstWhere(
      (m) => m?.fareMediaId == id,
      orElse: () => null,
    );

    // Find only the product ids that refer to this route (network)
    final Set<String> productIds = {};
    for (final entry in rulesByNetworkId.entries) {
      final rules = entry.value;
      final fareProductIds = rules.map((r) => r.fareProductId).toList();
      productIds.addAll(fareProductIds);
    }

    // In case no products are found, return everything (only possible from missing data)
    final candidates = productIds.isEmpty
        ? allProducts
        : allProducts
              .where((p) => productIds.contains(p.fareProductId))
              .toList();

    // For now, filter products that apply to this specific route/leg
    return FareCatalogService.groupProducts(
      candidates,
      mediaLookup: mediaLookup,
      riderCategoryId: riderCategoryId,
    ).expand((group) => group.options).toList();
  }

  /// Similarly to getOptionsForLeg, this function will find product options
  /// that apply for the whole trip. This means that any item from the list
  /// returned is a product option that covers ALL legs' fares. For example
  /// if a ktel agency supports daily tickets or monthly passes, any transfer
  /// trip should return both options.
  /// The [perLegOptions] list includes the options for each leg.
  /// The unification of the products into groups of options is made possible
  /// by first intersecting the options of each leg to see whether there
  /// is any product that covers ALL legs. If there exists such product
  /// we use legRules for this product and transfer rules to see if it can
  /// actually cover all the legs, since they might belong to different
  /// networks, or they might be too many for a single product to cover them
  /// all.
  /// NOTE: We make an assumption that there will either be a product for ALL
  /// legs or only one per leg. In a scenario of 3 or more legs which is
  /// almost impossible in the real world there could be a case where 2 of those
  /// legs can be combined to use 1 product and the 3rd leg to use another one.
  /// In that case the algorithm below will simply return 3 separate products
  /// which is NOT the best option.
  static List<FareProductOption> getOptionsForTrip({
    required List<List<FareProductOption>> perLegOptions,
    required Map<String, List<FareLegRule>> legRulesByProductId,
    required List<FareTransferRule> transferRules,
  }) {
    if (perLegOptions.isEmpty) return const [];

    final numLegs = perLegOptions.length;
    if (numLegs == 1) return perLegOptions.first;

    // Find products that appear on every leg (intersection of all legs' options)
    final candidates = perLegOptions.first
        .map((o) => o.product.fareProductId)
        .toSet();
    for (var i = 1; i < numLegs; i++) {
      candidates.retainAll(
        perLegOptions[i].map((o) => o.product.fareProductId).toSet(),
      );
    }

    // Keep only those whose leg group can chain through the whole journey (i.e.
    // the ones that can hold up to the legs' different networks, time limits)
    final List<FareProductOption> unified = [];
    for (final productId in candidates) {
      // Find the rules for the specific product we are examining
      final rules = legRulesByProductId[productId] ?? const [];

      // Find the leg groups that correspond to these rules
      final legGroups = rules
          .map((r) => r.legGroupId)
          .whereType<String>()
          .toSet();
      if (legGroups.isEmpty) continue;

      // Find if any leg group covers the whole trip
      final covers = legGroups.any(
        (lg) => _legGroupCoversTrip(
          legGroup: lg,
          numLegs: numLegs,
          transferRules: transferRules,
        ),
      );
      if (!covers) continue;

      // Return every media/category variant of this product from leg 1.
      // The rider buys once, at the start stop, so leg 1's media list is the
      // right one to surface.
      unified.addAll(
        perLegOptions.first.where((o) => o.product.fareProductId == productId),
      );
    }
    return unified;
  }

  /// Returns if a leg group can cover the entire trip. For that to happen
  /// the transfer rule must have its fromLegGroupId equal to the toLegGroupId,
  /// and a sufficient transferCount. For example if transferCount is 1 but we
  /// have to cover 3 legs then we cannot cover the whole trip.
  static bool _legGroupCoversTrip({
    required String legGroup,
    required int numLegs,
    required List<FareTransferRule> transferRules,
  }) {
    if (numLegs <= 1) return true;
    for (final rule in transferRules) {
      if (rule.fromLegGroupId != legGroup) continue;
      if (rule.toLegGroupId != legGroup) continue;
      final count = rule.transferCount;
      if (count == null) continue;
      if (count == -1) return true;
      if (count >= numLegs - 1) return true;
    }
    return false;
  }
}
