import 'package:flutter/material.dart';

class ColorUtils {
  /// Parses a GTFS hex string (e.g., "0056A3") into a Flutter Color.
  /// Returns null if the string is empty or invalid.
  static Color? fromHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;

    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff'); // Add opacity if missing
    buffer.write(hexString.replaceFirst('#', '')); // Strip # if present

    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// The "Glowing Trick": Mathematically adjusts lightness based on the theme.
  static Color adaptToTheme(Color baseColor, Brightness brightness) {
    final hsl = HSLColor.fromColor(baseColor);

    if (brightness == Brightness.dark) {
      // Dark mode: Bump lightness by 15% to make it glow against dark tiles
      return hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    }
    // else {
    //   // Light mode: Darken by 10% so pastels don't wash out on light streets
    //   return hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();
    // }
    return baseColor;
  }
}