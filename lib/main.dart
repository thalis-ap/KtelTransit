import 'package:flutter/material.dart';
import 'package:ktel_transit/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lefkada Transit',
      // This is your centralized stylesheet!
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Enables the sleek, modern Material 3 defaults

        // Global Button Style
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Premium rounded buttons globally
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),

        // Global Text Styles
        textTheme: TextTheme(
          // Used for main titles (like the Stop Name)
          titleLarge: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          // Used for small header text (like "UPCOMING DEPARTURES")
          labelSmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
