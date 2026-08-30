import 'package:flutter/material.dart';
import 'package:ktel_transit/models/map_point.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/models/trip_sort_filter.dart';
import 'package:ktel_transit/services/connection_service.dart';
import 'package:ktel_transit/services/sheet_manager_service.dart';
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

  static const List<double> _snapPoints = [
    SheetSizes.low,
    SheetSizes.middle,
    SheetSizes.high,
  ];

  @override
  void initState() {
    super.initState();
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
        if (_scrollController != null && _scrollController!.hasClients && _savedScrollOffset > 0) {
          _scrollController!.jumpTo(_savedScrollOffset);
        }
      });
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<TripSortFilter>(
      context: context,
      isScrollControlled: true,
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
    return filter.dontIncludeWalking == true ||
        filter.includeDirectOnly == true;
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
            style: context.textTheme.titleSmall?.copyWith(color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.availableRoutes,
              style: theme.textTheme.titleMedium,
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  size: 22,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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

  void _handleHeaderDragUpdate(DragUpdateDetails details, double availableHeight) {
    if (!widget.controller.isAttached) return;
    final delta = details.primaryDelta! / availableHeight;
    final newSize = (widget.controller.size - delta).clamp(
      SheetSizes.low,
      SheetSizes.high,
    );
    widget.controller.jumpTo(newSize);
  }

  void _handleHeaderDragEnd(DragEndDetails details, double availableHeight) {
    if (!widget.controller.isAttached) return;
    final currentSize = widget.controller.size;
    final velocity = details.velocity.pixelsPerSecond.dy / availableHeight;

    double target;
    if (velocity.abs() > 1.0) {
      if (velocity < 0) {
        target = _snapPoints.firstWhere(
              (s) => s > currentSize + 0.01,
          orElse: () => _snapPoints.last,
        );
      } else {
        target = _snapPoints.lastWhere(
              (s) => s < currentSize - 0.01,
          orElse: () => _snapPoints.first,
        );
      }
    } else {
      target = _snapPoints.reduce(
            (a, b) => (a - currentSize).abs() < (b - currentSize).abs() ? a : b,
      );
    }

    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    bool previousConnectionStatus = connectionService.isConnected;

    return DraggableScrollableSheet(
      controller: widget.controller,
      initialChildSize: SheetSizes.middle,
      minChildSize: SheetSizes.low,
      maxChildSize: SheetSizes.high,
      snap: true,
      snapSizes: const [SheetSizes.middle],
      builder: (context, scrollController) {
        // Store the draggable's scroll controller
        _scrollController = scrollController;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [BoxShadow(blurRadius: 15, spreadRadius: 2)],
          ),
          child: ListenableBuilder(
            listenable: connectionService,
            builder: (context, _) {
              if (previousConnectionStatus != connectionService.isConnected &&
                  connectionService.isConnected) {
                widget.onRetryConnection();
                previousConnectionStatus = connectionService.isConnected;
              }
              return AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  final bool showConnectionBanner =
                      (widget.startPoint is! Stop || widget.destinationPoint is! Stop) &&
                          !connectionService.isConnected;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed header
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) =>
                            _handleHeaderDragUpdate(details, screenHeight),
                        onVerticalDragEnd: (details) =>
                            _handleHeaderDragEnd(details, screenHeight),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 12.0,
                            left: 24.0,
                            right: 24.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 48,
                                  height: 5,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              if (widget.selectedTripIndex == null)
                                _buildHeader(context)
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: widget.onBackToAllTrips,
                                      icon: const Icon(Icons.arrow_back, size: 20),
                                      label: Text(
                                        AppLocalizations.of(context)!.allTrips,
                                        style: context.textTheme.labelLarge?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),

                      if (showConnectionBanner)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8.0,
                          ),
                          child: OfflineBanner(
                            onRetry: widget.onRetryConnection,
                          ),
                        ),

                      // Use the draggable's scrollController
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(
                            left: 24.0,
                            right: 24.0,
                            bottom: 16.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.selectedTripIndex != null && widget.trips != null)
                                _buildSelectedTripWidget(context)
                              else
                                _buildTripsSheet(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}