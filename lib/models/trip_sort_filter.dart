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
  final bool dontIncludeWalking;
  final bool includeDirectOnly;

  const TripSortFilter({
    this.sortBy = SortCriterion.arrivalTime,
    this.sortDirection = SortDirection.ascending,
    this.dontIncludeWalking = false,
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
      dontIncludeWalking: dontIncludeWalking ?? this.dontIncludeWalking,
      includeDirectOnly: includeDirectOnly ?? this.includeDirectOnly,
    );
  }
}