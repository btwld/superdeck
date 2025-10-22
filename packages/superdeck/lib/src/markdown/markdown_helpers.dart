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

class LerpStringResult {
  const LerpStringResult({
    required this.text,
    this.fadingChar,
    this.fadeOpacity = 0.0,
    this.isFadingOut = false,
  });

  /// Text that is fully visible at the given [t].
  final String text;

  /// Optional single character that is currently mid-transition.
  final String? fadingChar;

  /// Opacity to apply to [fadingChar]. Expected to be in the range [0, 1].
  final double fadeOpacity;

  /// Indicates whether the fading character belongs to the outgoing string.
  final bool isFadingOut;

  bool get hasFadingChar => fadingChar != null && fadeOpacity > 0.0;
}

LerpStringResult lerpStringWithFade(String start, String end, double t) {
  t = t.clamp(0.0, 1.0);
  const epsilon = 1e-6;

  final commonPrefixLen = start.commonPrefixLength(end);
  final startSuffix = start.substring(commonPrefixLen);
  final endSuffix = end.substring(commonPrefixLen);

  final buffer = StringBuffer()..write(end.substring(0, commonPrefixLen));

  String? fadingChar;
  double fadeOpacity = 0.0;
  bool isFadingOut = false;

  if (t <= 0.5) {
    final progress = t / 0.5;
    final startLength = startSuffix.length;
    if (startLength > 0) {
      final scaled = (progress * startLength).clamp(
        0.0,
        startLength.toDouble(),
      );
      final removed = scaled.floor();
      final fractional = scaled - removed;

      final remaining = math.max(0, startLength - removed);

      if (remaining > 0) {
        final shouldTreatAsZero = fractional <= epsilon;
        final shouldTreatAsOne = fractional >= 1 - epsilon;

        if (shouldTreatAsZero || shouldTreatAsOne) {
          final count = shouldTreatAsOne
              ? math.max(0, remaining - 1)
              : remaining;
          if (count > 0) {
            buffer.write(startSuffix.substring(0, count));
          }
        } else {
          final committedCount = math.max(0, remaining - 1);
          if (committedCount > 0) {
            buffer.write(startSuffix.substring(0, committedCount));
          }
          fadingChar = startSuffix.substring(
            committedCount,
            committedCount + 1,
          );
          fadeOpacity = 1.0 - fractional;
          isFadingOut = true;
        }
      }
    }
  } else {
    final progress = (t - 0.5) / 0.5;
    final endLength = endSuffix.length;
    if (endLength > 0) {
      final scaled = (progress * endLength).clamp(0.0, endLength.toDouble());
      var committedCount = math.min(scaled.floor(), endLength);
      final fractional = scaled - committedCount;

      if (fractional >= 1 - epsilon && committedCount < endLength) {
        committedCount += 1;
      }

      if (committedCount > 0) {
        buffer.write(endSuffix.substring(0, committedCount));
      }

      if (committedCount < endLength) {
        final fadeFraction = fractional.clamp(0.0, 1.0);
        if (fadeFraction > epsilon) {
          fadingChar = endSuffix.substring(committedCount, committedCount + 1);
          fadeOpacity = fadeFraction;
        }
      }
    }
  }

  return LerpStringResult(
    text: buffer.toString(),
    fadingChar: fadingChar,
    fadeOpacity: fadeOpacity,
    isFadingOut: isFadingOut,
  );
}

String lerpString(String start, String end, double t) =>
    lerpStringWithFade(start, end, t).text;

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
