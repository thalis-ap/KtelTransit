import 'package:flutter/material.dart';
import 'package:ktel_transit/models/map_point.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/models/trip_sort_filter.dart';
import 'package:ktel_transit/services/connection_service.dart';
import 'package:ktel_transit/services/trip_grouping_service.dart';
import 'package:ktel_transit/theme/app_theme.dart';
import 'package:ktel_transit/widgets/time_selection_bar.dart';
import 'package:ktel_transit/widgets/trip_extended_details_card.dart';
import 'package:ktel_transit/widgets/trip_filter_sheet.dart';
import 'package:ktel_transit/widgets/trip_groups_view.dart';
import 'package:ktel_transit/widgets/trip_sort_filter_buttons.dart';
import 'package:ktel_transit/widgets/trip_sort_sheet.dart';
import 'package:ktel_transit/widgets/trips_loading_skeleton.dart';
import 'package:ktel_transit/widgets/trips_warning_banner.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../models/stop.dart';
import 'bottom_sheet_wrapper.dart';
import 'offline_banner.dart';

class TripInfoSheet extends StatefulWidget {
  final bool isLoading;
  final MapPoint startPoint;
  final MapPoint destinationPoint;
  final List<RoutingTrip>? trips;
  final int? selectedTripIndex;
  final DateTime selectedSearchTime;
  final DraggableScrollableController controller;

  final VoidCallback onBackToAllTrips;
  final VoidCallback onClose;
  final VoidCallback onChangeTime, onResetTime;
  final VoidCallback onRetryConnection;
  final Function(int, RoutingTrip) onTripSelected;
  final Function(LatLng, LatLng) onTappedRoutePart;

  final TripSortFilter? sortFilter;
  final ValueChanged<TripSortFilter> onSortFilterApplied;

  const TripInfoSheet({
    super.key,
    required this.isLoading,
    required this.startPoint,
    required this.destinationPoint,
    required this.trips,
    required this.selectedTripIndex,
    required this.selectedSearchTime,
    required this.onBackToAllTrips,
    required this.onClose,
    required this.onChangeTime,
    required this.onResetTime,
    required this.onRetryConnection,
    required this.onTripSelected,
    required this.controller,
    this.sortFilter,
    required this.onSortFilterApplied,
    required this.onTappedRoutePart,
  });

  @override
  State<TripInfoSheet> createState() => _TripInfoSheetState();
}

class _TripInfoSheetState extends State<TripInfoSheet> {
  final connectionService = ConnectionService();
  ScrollController? _scrollController; // from DraggableScrollableSheet builder
  double _savedScrollOffset = 0.0;

  late bool _previousConnectionStatus;

  @override
  void initState() {
    super.initState();
    _previousConnectionStatus = connectionService.isConnected;
    connectionService.addListener(_onConnectionChanged);
  }

  @override
  void dispose() {
    connectionService.removeListener(_onConnectionChanged);
    super.dispose();
  }


  @override
  void didUpdateWidget(TripInfoSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only proceed if the controller is attached and has clients
    if (_scrollController == null || !_scrollController!.hasClients) return;

    final wasSelected = oldWidget.selectedTripIndex != null;
    final isSelected = widget.selectedTripIndex != null;

    // When a trip is SELECTED (went from null to non-null)
    if (!wasSelected && isSelected) {
      // Save current scroll position
      _savedScrollOffset = _scrollController!.offset;
      // Scroll to top after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController != null && _scrollController!.hasClients) {
          _scrollController!.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // When we go BACK to the list (went from non-null to null)
    if (wasSelected && !isSelected) {
      // Restore saved scroll position after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController != null &&
            _scrollController!.hasClients &&
            _savedScrollOffset > 0) {
          _scrollController!.jumpTo(_savedScrollOffset);
        }
      });
    }
  }

  void _onConnectionChanged() {
    final isConnected = connectionService.isConnected;

    // Reconnected after being offline → retry, as a clean event handler
    if (!_previousConnectionStatus && isConnected) {
      widget.onRetryConnection();
    }
    _previousConnectionStatus = isConnected;

    if (mounted) setState(() {});   // triggers the rebuild you lost
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<TripSortFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TripSortSheet(
        currentFilter: widget.sortFilter ?? const TripSortFilter(),
      ),
    ).then((newFilter) {
      if (newFilter != null) {
        widget.onSortFilterApplied(newFilter);
      }
    });
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<TripSortFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TripFilterSheet(
        currentFilter: widget.sortFilter ?? const TripSortFilter(),
      ),
    ).then((newFilter) {
      if (newFilter != null) {
        widget.onSortFilterApplied(newFilter);
      }
    });
  }

  bool _hasActiveFilters(TripSortFilter filter) {
    // Return true if the filters are not in their default value
    return filter.noPureWalking || filter.includeDirectOnly;
  }

  Widget _buildActiveFilterChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            l10n.filtersActive,
            style: context.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the stationary widgets that should always be displayed on top
  /// regardless of the scrolling (Date picker, sort/filter buttons)
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TimeSelectionBar(
          selectedSearchTime: widget.selectedSearchTime,
          onChangeTime: widget.onChangeTime,
          onResetTime: widget.onResetTime,
        ),
        const SizedBox(height: 8),
        TripSortFilterButtons(
          onSortPressed: () => _showSortSheet(context),
          onFilterPressed: () => _showFilterSheet(context),
        ),
        if (widget.sortFilter != null && _hasActiveFilters(widget.sortFilter!))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildActiveFilterChip(context),
          ),
      ],
    );
  }

  Widget _buildSelectedTripWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: ExtendedDetailsCard(
            routingTrip: widget.trips![widget.selectedTripIndex!],
            selectedDepartureTime: widget.selectedSearchTime,
            onTappedRoutePart: widget.onTappedRoutePart,
          ),
        ),
      ],
    );
  }

  Widget _buildTripsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isLoading) {
      return const TripsLoadingSkeleton();
    }

    if (widget.trips == null || widget.trips!.isEmpty) {
      return TripWarningBanner(
        message: l10n.noTripsForRoute,
        icon: Icons.warning_rounded,
        isCompact: false,
      );
    }

    final groups = TripGroupingService.filterAndGroupTrips(
      widget.trips!,
      widget.selectedSearchTime,
      DateTime.now(),
    );

    return TripGroupsView(
      groups: groups,
      selectedDepartureTime: widget.selectedSearchTime,
      isLoading: widget.isLoading,
      onTripSelected: (trip) {
        final originalIndex = widget.trips!.indexWhere((t) => t == trip);
        if (originalIndex != -1) {
          widget.onTripSelected(originalIndex, trip);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isConnected = connectionService.isConnected;
    final bool showConnectionBanner =
        (widget.startPoint is! Stop || widget.destinationPoint is! Stop) &&
        !isConnected;

    final bool viewingTrip = widget.selectedTripIndex != null && widget.trips != null;

    return BottomSheetWrapper(
      onScrollControllerCreated: (c) => _scrollController = c,
      controller: widget.controller,
      onClose: widget.onClose,
      dragHandleEnabled: true,
      title: viewingTrip
          ? TextButton.icon(
        onPressed: widget.onBackToAllTrips,
        icon: const Icon(Icons.arrow_back, size: 20),
        label: Text(
          l10n.allTrips,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
          ),
        ),
      )
          : Text(l10n.availableRoutes, style: theme.textTheme.titleMedium),

      underTitle: [
        if (!viewingTrip) _buildHeader(context),
        if (showConnectionBanner) ...[
          const SizedBox(height: 12),
          OfflineBanner(onRetry: widget.onRetryConnection),
        ],
      ],

      child: viewingTrip
          ? _buildSelectedTripWidget(context)
          : _buildTripsSheet(context),
    );
  }
}
