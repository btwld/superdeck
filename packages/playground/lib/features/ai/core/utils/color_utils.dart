import 'dart:developer' as developer;
import 'dart:ui';

/// Result of parsing a hex color string.
typedef ColorParseResult = ({Color color, bool isValid});

/// Default fallback color when parsing fails.
const _fallbackGray = Color(0xFF808080);

/// Parses a hex color string and returns both the color and validity status.
///
/// Supports both 6-digit (RGB) and 8-digit (ARGB) hex strings.
/// The '#' prefix is optional.
///
/// Returns a [ColorParseResult] with:
/// - `color`: The parsed color, or fallback gray if invalid
/// - `isValid`: Whether the hex string was successfully parsed
///
/// Examples:
/// ```dart
/// parseHexColor('#FF5733')  // (color: Color(0xFFFF5733), isValid: true)
/// parseHexColor('FF5733')   // (color: Color(0xFFFF5733), isValid: true)
/// parseHexColor('80FF5733') // (color: Color(0x80FF5733), isValid: true)
/// parseHexColor('invalid')  // (color: Color(0xFF808080), isValid: false)
/// ```
ColorParseResult parseHexColor(String hex) {
  try {
    hex = hex.replaceFirst('#', '').toUpperCase();
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) {
      throw FormatException('Invalid hex color length: $hex');
    }
    return (color: Color(int.parse(hex, radix: 16)), isValid: true);
  } catch (e) {
    developer.log('Invalid hex color: $hex', name: 'ColorUtils', error: e);
    return (color: _fallbackGray, isValid: false);
  }
}

/// Convenience wrapper that returns only the color.
/// Use [parseHexColor] if you need to check validity.
Color hexToColor(String hex) => parseHexColor(hex).color;

/// Formats [color] as an opaque, uppercase `#RRGGBB` hex string.
///
/// Alpha is intentionally dropped — the playground's color controls are
/// opaque-only. The result round-trips through [parseHexColor].
///
/// ```dart
/// colorToHex(const Color(0xFF0485F7)) // '#0485F7'
/// colorToHex(const Color(0x800485F7)) // '#0485F7' (alpha dropped)
/// ```
String colorToHex(Color color) {
  String channel(double value) =>
      (value * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}'
      .toUpperCase();
}
