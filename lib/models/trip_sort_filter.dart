enum SortCriterion {
  transferCount,
  walkingTime,
  cost,
  totalDuration,
  tripDuration,
  waitTimeDuration,
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
  final bool noPureWalking;

  final bool includeDirectOnly;

  const TripSortFilter({
    this.sortBy = SortCriterion.arrivalTime,
    this.sortDirection = SortDirection.ascending,
    this.noPureWalking = false,
    this.includeDirectOnly = false,
  });

  TripSortFilter copyWith({
    SortCriterion? sortBy,
    SortDirection? sortDirection,
    bool? dontIncludeWalking,
    bool? includeDirectOnly,
  }) {
    return TripSortFilter(
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      noPureWalking: dontIncludeWalking ?? this.noPureWalking,
      includeDirectOnly: includeDirectOnly ?? this.includeDirectOnly,
    );
  }
}