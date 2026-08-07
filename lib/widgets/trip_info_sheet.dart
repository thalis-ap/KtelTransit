import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/stop.dart';
import '../models/osrm_trip.dart';
import '../utilities/time_format.dart';

class TripInfoSheet extends StatelessWidget {
  final Stop startStop;
  final Stop destinationStop;
  final List<OsrmTrip>? trips;
  final int? selectedTripIndex;
  final DateTime selectedSearchTime;
  final List<Stop> allStops;

  // Callbacks to interact with the HomeScreen state
  final VoidCallback onBackToAllTrips;
  final VoidCallback onClose;
  final VoidCallback onChangeTime;
  final Function(int index, OsrmTrip trip) onTripSelected;

  const TripInfoSheet({
    super.key,
    required this.startStop,
    required this.destinationStop,
    required this.trips,
    required this.selectedTripIndex,
    required this.selectedSearchTime,
    required this.allStops,
    required this.onBackToAllTrips,
    required this.onClose,
    required this.onChangeTime,
    required this.onTripSelected,
  });

  /// DRAFT function to estimate the fare between 2 stops
  double _estimateFare(Stop start, Stop dest) {
    final distanceCalc = const Distance();
    final meters = distanceCalc(
      LatLng(start.latitude, start.longitude),
      LatLng(dest.latitude, dest.longitude),
    );

    final km = meters / 1000;

    if (km <= 14) return 2.2;

    double calculatedPrice = 2.20 + ((km - 14) * 0.137);
    if (calculatedPrice > 4.20) calculatedPrice = 4.20;

    return (calculatedPrice * 10).round() / 10.0;
  }

  /// Returns a string formatted version of the estimated fare (double?)
  /// It also handles null values by returning -€.
  String _estimatedFareAsString(double? estimatedFare) {
    return estimatedFare == null ? "-€" : "${estimatedFare.toStringAsFixed(2)}€";
  }

  /// Returns a widget that contains a single trip's details
  /// If extra flag is true, then additional info such as ticket analysis
  /// are provided
  Widget _buildTripDetails(OsrmTrip osrmTrip, {bool extra = false}) {
    int totalMins = osrmTrip.estimatedDuration;
    String totalStr = totalMins >= 60
        ? "${totalMins ~/ 60}ω ${totalMins % 60}λ"
        : "$totalMinsλ";

    if (osrmTrip.isTransfer) {
      final Stop localTransferStop = allStops.firstWhere(
            (s) => s.name == osrmTrip.transferStopName,
      );

      double? fare1 = _estimateFare(startStop, localTransferStop);
      double? fare2 = _estimateFare(localTransferStop, destinationStop);
      double? estimatedFare = fare1 + fare2;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ΜΕΤΕΠΙΒΙΒΑΣΗ",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.confirmation_num_outlined, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    _estimatedFareAsString(estimatedFare),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    totalStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            osrmTrip.routeName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Αναχώρηση από ${startStop.name}:",
                  style: TextStyle(color: Colors.grey.shade900, fontSize: 14),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedString(osrmTrip.startDepartureDateTime),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.circle_outlined, size: 10, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Άφιξη σε ${osrmTrip.transferStopName}:",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedString(osrmTrip.transferArrivalDateTime!),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  "Αναμονή: ${TimeFormat.waitTimeToFormattedString(osrmTrip.transferDepartureDateTime!, osrmTrip.transferArrivalDateTime!)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.circle_outlined, size: 10, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Αναχώρηση από ${osrmTrip.transferStopName}:",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedString(osrmTrip.transferDepartureDateTime!),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Εκτιμώμενη άφιξη σε ${destinationStop.name}:",
                  style: TextStyle(color: Colors.grey.shade900, fontSize: 14),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedString(osrmTrip.destArrivalDateTime),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (extra)
            Column(
              children: [
                const Divider(height: 30),
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          "Ανάλυση κόστους",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "1. ${osrmTrip.originStopName} - ${osrmTrip.transferStopName}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.confirmation_num_outlined, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              _estimatedFareAsString(fare1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "2. ${osrmTrip.transferStopName} - ${osrmTrip.destinationStopName}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.confirmation_num_outlined, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              _estimatedFareAsString(fare2),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Συνολικό κόστος εισιτηρίων"),
                        Row(
                          children: [
                            Icon(Icons.confirmation_num_outlined, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              _estimatedFareAsString(estimatedFare),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
        ],
      );
    } else {
      double estimatedFare = _estimateFare(startStop, destinationStop);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  osrmTrip.routeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.confirmation_num_outlined, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    _estimatedFareAsString(estimatedFare),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    totalStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!osrmTrip.isStartAlsoOrigin) ...[
            Row(
              children: [
                const Icon(Icons.circle_outlined, size: 10, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Αναχώρηση από ${osrmTrip.originStopName}:",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
                Text(
                  TimeFormat.dateTimeToFormattedString(osrmTrip.originDepartureDateTime),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  osrmTrip.isStartAlsoOrigin
                      ? "Αναχώρηση από ${startStop.name}:"
                      : "Εκτιμώμενη άφιξη σε ${startStop.name}:",
                  style: TextStyle(color: Colors.grey.shade900, fontSize: 14),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedString(osrmTrip.startDepartureDateTime),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Εκτιμώμενη άφιξη σε ${destinationStop.name}:",
                  style: TextStyle(color: Colors.grey.shade900, fontSize: 14),
                ),
              ),
              Text(
                TimeFormat.dateTimeToFormattedString(osrmTrip.destArrivalDateTime),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (extra)
            Column(
              children: [
                const Divider(height: 30),
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          "Ανάλυση κόστους",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${osrmTrip.originStopName} - ${osrmTrip.destinationStopName}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.confirmation_num_outlined, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              _estimatedFareAsString(estimatedFare),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Συνολικό κόστος εισιτηρίων"),
                        Row(
                          children: [
                            Icon(Icons.confirmation_num_outlined, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              _estimatedFareAsString(estimatedFare),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.10,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.45],
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.only(
            top: 12.0,
            left: 24.0,
            right: 24.0,
            bottom: 16.0,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (selectedTripIndex != null && trips != null)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: onBackToAllTrips,
                              icon: const Icon(Icons.arrow_back, size: 20),
                              label: const Text(
                                "Όλα τα δρομολόγια",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: onClose,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: _buildTripDetails(
                            trips![selectedTripIndex!],
                            extra: true,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule, color: Colors.blueGrey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Αναχώρηση: ${selectedSearchTime.day.toString().padLeft(2, '0')}/${selectedSearchTime.month.toString().padLeft(2, '0')} - ${selectedSearchTime.hour.toString().padLeft(2, '0')}:${selectedSearchTime.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: onChangeTime,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue.shade50,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text(
                                  "ΑΛΛΑΓΗ",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        trips != null
                            ? Builder(
                          builder: (context) {
                            final foundDate = trips!.first.originDepartureDateTime;
                            final dateChanged =
                                foundDate.year != selectedSearchTime.year ||
                                    foundDate.month != selectedSearchTime.month ||
                                    foundDate.day != selectedSearchTime.day;
                            final now = DateTime.now();
                            final isToday =
                                foundDate.year == now.year &&
                                    foundDate.month == now.month &&
                                    foundDate.day == now.day;
                            final displayDate = isToday
                                ? "Σήμερα"
                                : "${foundDate.day.toString().padLeft(2, '0')}/${foundDate.month.toString().padLeft(2, '0')}/${foundDate.year}";

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (dateChanged) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.orange.shade800,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Δεν βρέθηκαν δρομολόγια για την επιλεγμένη ημερομηνία. Εμφάνιση επόμενων διαθέσιμων.",
                                            style: TextStyle(
                                              color: Colors.orange.shade900,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                Text(
                                  "Δρομολόγια για: $displayDate",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue.shade100),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(12),
                                    itemCount: trips!.length,
                                    separatorBuilder: (context, index) => const Divider(height: 24),
                                    itemBuilder: (context, index) {
                                      final trip = trips![index];
                                      bool isPast = false;
                                      if (isToday) {
                                        if (trip.startDepartureDateTime.isBefore(now)) {
                                          isPast = true;
                                        }
                                      }
                                      return Opacity(
                                        opacity: isPast ? 0.5 : 1.0,
                                        child: InkWell(
                                          onTap: isPast ? null : () => onTripSelected(index, trip),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: Stack(
                                              children: [
                                                _buildTripDetails(trip),
                                                if (isPast)
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.shade100,
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.red.shade300),
                                                      ),
                                                      child: Text(
                                                        "Αναχώρησε",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.red.shade800,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                            : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Δεν βρέθηκαν δρομολόγια για αυτή τη διαδρομή.",
                                  style: TextStyle(color: Colors.orange.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}