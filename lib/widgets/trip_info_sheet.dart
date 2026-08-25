import 'package:flutter/material.dart';
import 'package:ktel_transit/models/map_point.dart';
import 'package:ktel_transit/models/routing_trip.dart';
import 'package:ktel_transit/services/connection_service.dart';
import 'package:ktel_transit/services/sheet_manager_service.dart';
import 'package:ktel_transit/services/trip_filter_service.dart';
import 'package:ktel_transit/widgets/time_selection_bar.dart';
import 'package:ktel_transit/widgets/trip_extended_details_card.dart';
import 'package:ktel_transit/widgets/trip_groups_view.dart';
import 'package:ktel_transit/widgets/trips_loading_skeleton.dart';
import 'package:ktel_transit/widgets/trips_warning_banner.dart';
import '../l10n/app_localizations.dart';
import '../models/stop.dart';
import 'offline_banner.dart';

class TripInfoSheet extends StatelessWidget {
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
  final Function(int index, RoutingTrip trip) onTripSelected;

  final connectionService = ConnectionService();

  // Snap points, kept in one place so header-drag snapping matches the
  // sheet's own min/max/snapSizes configuration.
  static const List<double> _snapPoints = [
    SheetSizes.low,
    SheetSizes.middle,
    SheetSizes.high,
  ];

  TripInfoSheet({
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
  });

  /// Builds the header widget of the trip info sheet title, date picker + close button
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
              l10n.availableRoutes, // add this key to your l10n files
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TimeSelectionBar(
          selectedSearchTime: selectedSearchTime,
          onChangeTime: onChangeTime,
          onResetTime: onResetTime,
        ),
      ],
    );
  }

  /// Builds the widget that shows up after selecting a trip
  /// Back button and details card for this widget
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
            routingTrip: trips![selectedTripIndex!],
            selectedDepartureTime: selectedSearchTime,
          ),
        ),
      ],
    );
  }

  /// Build the trip sheet, loading or not
  Widget _buildTripsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const TripsLoadingSkeleton();
    }
    // Completely empty trips not even pure walking
    if (trips == null || trips!.isEmpty) {
      return TripWarningBanner(
        message: l10n.noTripsForRoute,
        icon: Icons.warning_rounded,
        isCompact: false,
      );
    }

    final groups = TripFilterService.filterAndGroupTrips(
      trips!,
      selectedSearchTime,
      DateTime.now(),
    );

    return TripGroupsView(
      groups: groups,
      selectedDepartureTime: selectedSearchTime,
      isLoading: isLoading,
      onTripSelected: (trip) {
        final originalIndex = trips!.indexWhere((t) => t == trip);
        if (originalIndex != -1) {
          onTripSelected(originalIndex, trip);
        }
      },
    );
  }

  /// Manually resizes the sheet while the user drags on the fixed header
  /// (title/close button/time bar), since that area sits outside the
  /// scrollable that normally drives DraggableScrollableSheet's gestures.
  void _handleHeaderDragUpdate(
    DragUpdateDetails details,
    double availableHeight,
  ) {
    if (!controller.isAttached) return;
    final delta = details.primaryDelta! / availableHeight;
    final newSize = (controller.size - delta).clamp(
      SheetSizes.low,
      SheetSizes.high,
    );
    controller.jumpTo(newSize);
  }

  /// On release, snap to the nearest configured sheet size — mirroring the
  /// snap behavior DraggableScrollableSheet provides natively for drags
  /// that originate inside the scrollable body.
  void _handleHeaderDragEnd(DragEndDetails details, double availableHeight) {
    if (!controller.isAttached) return;
    final currentSize = controller.size;
    final velocity = details.velocity.pixelsPerSecond.dy / availableHeight;

    double target;
    if (velocity.abs() > 1.0) {
      // Fast fling: jump to the next snap point in that direction.
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

    controller.animateTo(
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
    final l10n = AppLocalizations.of(context)!;
    bool previousConnectionStatus = connectionService.isConnected;

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: SheetSizes.middle,
      minChildSize: SheetSizes.low,
      maxChildSize: SheetSizes.high,
      snap: true,
      snapSizes: const [SheetSizes.middle],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [BoxShadow(blurRadius: 15, spreadRadius: 2)],
          ),
          child: ListenableBuilder(
            listenable: connectionService,
            builder: (context, _) {
              // Refresh the trips only if the connection status changed to true
              if (previousConnectionStatus != connectionService.isConnected && connectionService.isConnected) {
                onRetryConnection();
                previousConnectionStatus = connectionService.isConnected;
              }
              return AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final bool showConnectionBanner =
                      (startPoint is! Stop || destinationPoint is! Stop) &&
                      !connectionService.isConnected;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Fixed header: handle, title, close button, time bar ---
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
                              // Sheet handle
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

                              if (selectedTripIndex == null)
                                _buildHeader(context)
                              else
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: onBackToAllTrips,
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        size: 20,
                                      ),
                                      label: Text(
                                        l10n.allTrips,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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

                      // --- Offline Banner (shows only when offline) ---
                      if (showConnectionBanner)

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8.0,
                          ),
                          child: OfflineBanner(
                            onRetry: onRetryConnection,

                          ),
                        ),

                      // --- Scrollable body: trip list or selected trip details ---
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
                              if (selectedTripIndex != null && trips != null)
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
