import 'package:flutter/material.dart';
import '../models/stop.dart';

class StopSearchDelegate extends SearchDelegate<Stop?> {
  final List<Stop> stops;

  StopSearchDelegate(this.stops);

  // Placeholder text in the search bar
  @override
  String get searchFieldLabel => 'Αναζήτηση στάσης...';

  // The 'Clear' button on the right side of the search bar
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  // The 'Back' button on the left side of the search bar
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Return null if the user cancels
      },
    );
  }

  // Show the results when the user submits the search
  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestionsList();
  }

  // Show live suggestions as the user types
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestionsList();
  }

  // Helper method to remove Greek diacritics (tonous)
  String _removeDiacritics(String input) {
    const withDiacritics = 'άέήίϊΐόύϋΰώΆΈΉΊΪΌΎΫΏ';
    const withoutDiacritics = 'αεηιιιουυυωΑΕΗΙΙΟΥΥΩ';

    String result = input;
    for (int i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result;
  }

  // Helper method to filter and display the stops
  Widget _buildSuggestionsList() {
    // Normalize query (lowercase and no accents)
    final normalizedQuery = _removeDiacritics(query.toLowerCase());

    // Filter stops based on normalized text
    final suggestions = stops.where((stop) {
      final normalizedStopName = _removeDiacritics(stop.name.toLowerCase());
      return normalizedStopName.contains(normalizedQuery);
    }).toList();

    if (suggestions.isEmpty) {
      return const Center(
        child: Text("Δεν βρέθηκε στάση.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final stop = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.place, color: Colors.blueGrey),
          title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            close(context, stop); // Send the selected stop back to HomeScreen
          },
        );
      },
    );
  }
}