import 'package:flutter/material.dart';
import '../screens/routes_screen.dart';
import '../screens/info_screen.dart';
import '../screens/tickets_screen.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade300),
            child: Column(
              children: [
                const Text(
                  'Τοπικά ΚΤΕΛ',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Expanded(child: Image.asset("assets/icons/appicon.png")),
              ],
            ),
            // TODO add the logo
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Δρομολόγια'),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoutesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Πληροφορίες'),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InfoScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text('Εισιτήρια'),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TicketsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}