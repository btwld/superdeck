import 'dart:math' as math;

import '../../../../../../core/domain/design/presentation_color_contrast.dart';

/// WCAG contrast ratio for two `#RRGGBB` or `#AARRGGBB` colors.
double calculateContrastRatio(String foreground, String background) {
  return calculatePresentationContrast(foreground, background);
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
    'titleLeft' => 480,
    'twoColumn' => 500,
    'threeColumn' => 480,
    'table' => 620,
    'quote' => 360,
    'metric' => 480,
    'content' => 560,
    'imageLeft' || 'imageRight' => 380,
    'imageFullBleed' => 120,
    'webview' || 'dartpad' || 'custom' => 160,
    _ => densityLimit,
  };
  return math.min(densityLimit, compositionLimit);
}

/// Whether copy exceeds the soft pacing budget enough to risk actual overflow.
///
/// A modest overage remains useful review evidence for the POC. Twice the
/// composition-aware budget is treated as structurally unsafe.
bool isHardContentDensityOverage({
  required int visibleCharacters,
  required int characterLimit,
}) => visibleCharacters > characterLimit * 2;

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
