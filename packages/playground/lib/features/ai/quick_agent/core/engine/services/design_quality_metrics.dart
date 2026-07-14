import 'dart:math' as math;

/// WCAG contrast ratio for two `#RRGGBB` or `#AARRGGBB` colors.
double calculateContrastRatio(String foreground, String background) {
  final first = _relativeLuminance(foreground);
  final second = _relativeLuminance(background);
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Returns the more readable of black or white for [background].
///
/// Generated accent colors are arbitrary, but the foreground placed on an
/// accent is a derived palette value. Choosing the higher-contrast monochrome
/// foreground is deterministic and always provides WCAG AA contrast for normal
/// text, avoiding an unreliable model round trip for color arithmetic.
String mostReadableMonochromeForeground(String background) {
  const black = '#000000';
  const white = '#FFFFFF';
  return calculateContrastRatio(black, background) >=
          calculateContrastRatio(white, background)
      ? black
      : white;
}

/// Maximum visible Markdown characters for a density and composition shape.
///
/// Density expresses desired pacing, while composition caps reflect the actual
/// canvas width available to text. For example, three narrow columns cannot
/// safely consume the same budget as a full-width table.
int visibleCharacterLimit(String density, {String? composition}) {
  final densityLimit = switch (density) {
    'spacious' => 480,
    'compact' => 800,
    _ => 650,
  };
  final compositionLimit = switch (composition) {
    'title' => 250,
    'titleLeft' => 440,
    'twoColumn' => 400,
    'threeColumn' => 480,
    'table' => 620,
    'quote' => 360,
    'metric' => 480,
    'content' => 560,
    'imageLeft' || 'imageRight' => 380,
    'imageFullBleed' => 120,
    'qrcode' => 320,
    'webview' || 'dartpad' || 'custom' => 160,
    _ => densityLimit,
  };
  return math.min(densityLimit, compositionLimit);
}

/// Counts approximate audience-visible characters, excluding Markdown syntax.
int countVisibleMarkdownCharacters(Iterable<String> markdownBlocks) {
  var count = 0;
  for (final markdown in markdownBlocks) {
    count += markdown
        .replaceAll(RegExp(r'[#>*_`|~\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .length;
  }
  return count;
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
