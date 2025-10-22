import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart'
    as core
    show extractHeroAndContent, heroAnywherePattern, isValidHeroTag;

/// Extracts CSS class tags from markdown text for Hero animations.
///
/// CSS class tags like `{.heading}`, `{.subheading}`, `{.animate}` are:
/// 1. Extracted and returned as the `tag` for use in Hero animations
/// 2. Stripped from the `content` that gets rendered
///
/// **Important**: CSS class tags do NOT apply custom Mix styles to the text.
/// They are used exclusively for Hero animation identifiers during slide
/// transitions. To apply custom styling, use:
/// - `SlideStyle` configurations in `DeckOptions`
/// - Named slide styles via frontmatter (e.g., `style: hero`)
/// - Direct Mix styling in widget configurations
///
/// Examples:
/// ```dart
/// getTagAndContent('# Title {.heading}')
/// // Returns: (tag: 'heading', content: '# Title')
///
/// getTagAndContent('Regular text')
/// // Returns: (tag: null, content: 'Regular text')
/// ```
///
/// Returns a record with:
/// - `tag`: The CSS class name (without the dot) if found, null otherwise
/// - `content`: The text with CSS class tag removed and trimmed
({String? tag, String content}) getTagAndContent(String text) {
  final result = core.extractHeroAndContent(text);

  if (result.tag == null) {
    final trimmed = text.trim();
    final match = core.heroAnywherePattern.firstMatch(trimmed);
    final extractedTag = match?.group(1)?.trim();

    if (extractedTag != null && !core.isValidHeroTag(extractedTag)) {
      assert(() {
        debugPrint('Ignored invalid hero tag "$extractedTag" in "$trimmed"');
        return true;
      }());
    }
  }

  return result;
}

/// Re-exported convenience wrapper so existing imports keep working.
bool isValidHeroTag(String value) => core.isValidHeroTag(value);

String lerpString(String start, String end, double t) {
  // Clamp t between 0 and 1
  t = t.clamp(0.0, 1.0);
  const epsilon = 1e-6;

  final commonPrefixLen = start.commonPrefixLength(end);
  final startSuffix = start.substring(commonPrefixLen);
  final endSuffix = end.substring(commonPrefixLen);

  final result = StringBuffer();
  result.write(end.substring(0, commonPrefixLen));

  if (t <= 0.5) {
    final progress = t / 0.5;
    final startLength = startSuffix.length;
    var numCharsToShow = startLength -
        ((progress * startLength).floor()); // remove characters monotonically
    if ((1 - progress) <= epsilon) {
      numCharsToShow = 0;
    }
    numCharsToShow = math.max(0, math.min(startLength, numCharsToShow));
    if (numCharsToShow > 0) {
      result.write(startSuffix.substring(0, numCharsToShow));
    }
  } else {
    final progress = (t - 0.5) / 0.5;
    final endLength = endSuffix.length;
    var numCharsToShow =
        (progress * endLength).floor(); // add characters monotonically
    if (progress >= 1 - epsilon) {
      numCharsToShow = endLength;
    }
    numCharsToShow = math.max(0, math.min(endLength, numCharsToShow));
    if (numCharsToShow > 0) {
      result.write(endSuffix.substring(0, numCharsToShow));
    }
  }

  return result.toString();
}

extension on String {
  int commonPrefixLength(String other) {
    final len = math.min(length, other.length);
    for (int i = 0; i < len; i++) {
      if (this[i] != other[i]) {
        return i;
      }
    }
    return len;
  }
}

List<TextSpan> lerpTextSpans(
  List<TextSpan> start,
  List<TextSpan> end,
  double t,
) {
  final maxLines = math.max(start.length, end.length);
  List<TextSpan> interpolatedSpans = [];

  for (int i = 0; i < maxLines; i++) {
    final startSpan = i < start.length ? start[i] : const TextSpan(text: '');
    final endSpan = i < end.length ? end[i] : const TextSpan(text: '');

    if (startSpan.text == null && endSpan.text == null) {
      // if chilrens are not null recursive
      if (startSpan.children != null && endSpan.children != null) {
        if (startSpan.children!.isEmpty && endSpan.children!.isEmpty) {
          continue;
        }
        final children = lerpTextSpans(
          startSpan.children! as List<TextSpan>,
          endSpan.children! as List<TextSpan>,
          t,
        );
        final interpolatedSpan = TextSpan(
          children: children,
          style: TextStyle.lerp(startSpan.style, endSpan.style, t),
        );
        interpolatedSpans.add(interpolatedSpan);
        continue;
      }
    }

    final interpolatedText = lerpString(
      startSpan.text ?? '',
      endSpan.text ?? '',
      t,
    );
    final interpolatedStyle = TextStyle.lerp(startSpan.style, endSpan.style, t);

    final interpolatedSpan = TextSpan(
      text: interpolatedText,
      style: interpolatedStyle,
    );

    interpolatedSpans.add(interpolatedSpan);
  }

  return interpolatedSpans;
}
