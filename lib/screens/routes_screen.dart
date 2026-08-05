import 'package:flutter/material.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Δρομολόγια'),
      ),
      // A simple list view to scroll through the route categories
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 3, // Change this to match your actual number of route categories
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            elevation: 2,
            child: ExpansionTile(
              leading: const Icon(Icons.directions_bus),
              title: Text('Κατηγορία / Προορισμός ${index + 1}'),
              children: [
                // Inside the expansion tile, list the specific routes or timetables
                ListTile(
                  title: const Text('Διαδρομή 1 (π.χ. Αφετηρία - Τέρμα)'),
                  subtitle: const Text('Δευτέρα - Παρασκευή: 08:00, 14:30'),
                  onTap: () {
                    // TODO: Open detailed view or map if needed
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Διαδρομή 2 (π.χ. Τέρμα - Αφετηρία)'),
                  subtitle: const Text('Σαββατοκύριακο: 09:00, 15:00'),
                  onTap: () {
                    // TODO: Open detailed view or map if needed
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}