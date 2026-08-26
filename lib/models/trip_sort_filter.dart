enum SortCriterion {
  transferCount,
  walkingTime,
  cost,
  totalDuration,
  tripDuration,
  arrivalTime,
  departureTime,
}

enum SortDirection {
  ascending,
  descending,
}

class TripSortFilter {
  final SortCriterion sortBy;
  final SortDirection sortDirection;
  final bool includeWalking;
  final bool includeTransfers;
  final bool includeDirect;

  const TripSortFilter({
    this.sortBy = SortCriterion.arrivalTime,
    this.sortDirection = SortDirection.ascending,
    this.includeWalking = true,
    this.includeTransfers = true,
    this.includeDirect = true,
  });

  TripSortFilter copyWith({
    SortCriterion? sortBy,
    SortDirection? sortDirection,
    bool? includeWalking,
    bool? includeTransfers,
    bool? includeDirect,
  }) {
    return TripSortFilter(
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      includeWalking: includeWalking ?? this.includeWalking,
      includeTransfers: includeTransfers ?? this.includeTransfers,
      includeDirect: includeDirect ?? this.includeDirect,
    );
  }
}