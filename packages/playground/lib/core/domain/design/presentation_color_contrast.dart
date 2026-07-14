import 'dart:math' as math;

/// WCAG contrast ratio for two `#RRGGBB` or `#AARRGGBB` colors.
double calculatePresentationContrast(String foreground, String background) {
  final first = _relativeLuminance(foreground);
  final second = _relativeLuminance(background);
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;

  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final rgb = normalized.length == 8 ? normalized.substring(2) : normalized;
  final channels = [0, 2, 4].map((start) {
    final value = int.parse(rgb.substring(start, start + 2), radix: 16) / 255;

    return value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }).toList();

  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}
