import 'dart:math';

/// Minimal color utilities for theme derivation.
///
/// Provides basic color manipulation without external dependencies.
class ColorUtils {
  ColorUtils._();

  /// Parse hex string (#RRGGBB or #RGB) to RGB tuple.
  ///
  /// Supports formats: #RRGGBB, #RGB, RRGGBB, RGB
  ///
  /// Example:
  /// ```dart
  /// ColorUtils.parseHex('#ff0000'); // (255, 0, 0)
  /// ColorUtils.parseHex('#f00');    // (255, 0, 0)
  /// ```
  static (int r, int g, int b) parseHex(String hex) {
    hex = hex.replaceAll('#', '');

    // Expand shorthand (#RGB → #RRGGBB)
    if (hex.length == 3) {
      hex = hex.split('').map((c) => c + c).join();
    }

    if (hex.length != 6) {
      throw ArgumentError('Invalid hex color: $hex');
    }

    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);

    return (r, g, b);
  }

  /// Convert RGB values to hex string.
  ///
  /// Example:
  /// ```dart
  /// ColorUtils.toHex(255, 0, 0); // '#ff0000'
  /// ```
  static String toHex(int r, int g, int b) {
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  /// Lighten color by interpolating toward white.
  ///
  /// [amount] should be between 0.0 (no change) and 1.0 (white).
  ///
  /// Example:
  /// ```dart
  /// ColorUtils.lighten('#808080', 0.5); // Lighter gray
  /// ```
  static String lighten(String hex, double amount) {
    final (r, g, b) = parseHex(hex);

    // Interpolate toward white (255, 255, 255)
    final nr = (r + (255 - r) * amount).round().clamp(0, 255);
    final ng = (g + (255 - g) * amount).round().clamp(0, 255);
    final nb = (b + (255 - b) * amount).round().clamp(0, 255);

    return toHex(nr, ng, nb);
  }

  /// Darken color by interpolating toward black.
  ///
  /// [amount] should be between 0.0 (no change) and 1.0 (black).
  ///
  /// Example:
  /// ```dart
  /// ColorUtils.darken('#808080', 0.5); // Darker gray
  /// ```
  static String darken(String hex, double amount) {
    final (r, g, b) = parseHex(hex);

    // Interpolate toward black (0, 0, 0)
    final nr = (r * (1 - amount)).round().clamp(0, 255);
    final ng = (g * (1 - amount)).round().clamp(0, 255);
    final nb = (b * (1 - amount)).round().clamp(0, 255);

    return toHex(nr, ng, nb);
  }

  /// Calculate relative luminance using WCAG formula.
  ///
  /// Returns value between 0.0 (black) and 1.0 (white).
  ///
  /// Used for contrast ratio calculations.
  static double luminance(String hex) {
    final (r, g, b) = parseHex(hex);

    // Normalize and apply sRGB gamma correction
    double normalize(int val) {
      final v = val / 255.0;
      return v <= 0.03928
          ? v / 12.92
          : pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * normalize(r) +
        0.7152 * normalize(g) +
        0.0722 * normalize(b);
  }

  /// Choose contrasting text color (light or dark) based on background.
  ///
  /// Uses WCAG luminance threshold (0.5) to determine readability.
  ///
  /// Example:
  /// ```dart
  /// ColorUtils.contrastColor('#ffffff'); // '#000000' (dark on light)
  /// ColorUtils.contrastColor('#000000'); // '#ffffff' (light on dark)
  /// ```
  static String contrastColor(
    String bgHex, {
    String light = '#ffffff',
    String dark = '#000000',
  }) {
    return luminance(bgHex) > 0.5 ? dark : light;
  }
}
