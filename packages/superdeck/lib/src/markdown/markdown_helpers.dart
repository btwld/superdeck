import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:superdeck_core/superdeck_core.dart'
    as core
    show extractHeroAndContent, heroAnywherePattern, isValidHeroTag;

/// Extracts the first valid CSS class tag and returns (tag, contentWithoutTag).
/// Skips creating a hero tag when the remaining content is empty.
({String? tag, String content}) getTagAndContent(String text) {
  final result = core.extractHeroAndContent(text);

  // Best-effort warning on invalid tags found anywhere.
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

  // If content is empty after stripping, don't expose a hero tag to avoid duplicates.
  if (result.content.trim().isEmpty) {
    return (tag: null, content: '');
  }

  return result;
}

/// Re-exported convenience wrapper so existing imports keep working.
bool isValidHeroTag(String value) => core.isValidHeroTag(value);

class LerpStringResult {
  const LerpStringResult({
    required this.text, // fully visible prefix
    this.fadingChar, // single grapheme (may be null)
    this.fadeOpacity = 0.0, // 0..1 opacity for fadingChar
    this.isFadingOut = false, // phase flag
    this.ghostSuffix = '', // zero-opacity suffix to pin layout
  });

  final String text;
  final String? fadingChar;
  final double fadeOpacity;
  final bool isFadingOut;

  /// Remainder drawn with alpha=0 to keep wrapping stable.
  /// By rendering the full final string with invisible characters, we reserve
  /// the correct line-wrapping layout even during transitions, preventing the
  /// "last word flicker" bug where text position shifts as characters fade in.
  final String ghostSuffix;

  bool get hasFadingChar => fadingChar != null && fadeOpacity > 0.0;
}

/// Grapheme-safe, layout-stable string interpolation with a ghost suffix.
///
/// - First half (t<0.5): fade out the start suffix (left→right)
/// - Second half (t>0.5): fade in the end suffix (left→right)
/// - Always returns:
///   * `text` (committed prefix),
///   * optional `fadingChar` + `fadeOpacity`,
///   * `ghostSuffix` (alpha=0) so total width is stable per phase.
///
LerpStringResult lerpStringWithFade(String start, String end, double t) {
  t = t.clamp(0.0, 1.0);

  // Split by grapheme, not code-units.
  final startG = start.characters.toList();
  final endG = end.characters.toList();

  // Common prefix length by grapheme.
  int common = 0;
  final minLen = math.min(startG.length, endG.length);
  while (common < minLen && startG[common] == endG[common]) {
    common++;
  }

  final startSuffix = startG.sublist(common);
  final endSuffix = endG.sublist(common);

  // Base prefix is always from the END string to avoid tiny font metric drifts.
  // Using the end string ensures the final rendered layout matches what will be
  // displayed when t=1.0, preventing subtle positioning shifts during the final
  // frames of the transition animation.
  final prefix = endG.take(common).join();

  String committed = prefix;
  String? fadingChar;
  double fadeOpacity = 0.0;
  bool isFadingOut = false;
  List<String> ghostSuffixG = const <String>[];

  if (t < 0.5 && startSuffix.isNotEmpty) {
    final p = t * 2.0; // 0..1 in fade-out
    final remainingExact = startSuffix.length * (1.0 - p);
    final remaining = remainingExact.floor();
    final frac = remainingExact - remaining; // 0..1 (for the next char)

    if (remaining > 0) {
      committed += startSuffix.take(remaining).join();
    }
    if (remaining < startSuffix.length) {
      fadingChar = startSuffix[remaining];
      fadeOpacity = frac; // 0..1
      isFadingOut = true;
      // Reserve width for the rest of the start string after the fading grapheme.
      ghostSuffixG = startSuffix.skip(remaining + 1).toList();
    } else {
      // No fading; ghost the empty remainder.
      ghostSuffixG = const <String>[];
    }
  } else if (t > 0.5 && endSuffix.isNotEmpty) {
    final p = (t - 0.5) * 2.0; // 0..1 in fade-in
    final addedExact = endSuffix.length * p;
    final added = addedExact.floor();
    final frac = addedExact - added;

    if (added > 0) {
      committed += endSuffix.take(added).join();
    }
    if (added < endSuffix.length && frac > 0.0) {
      fadingChar = endSuffix[added];
      fadeOpacity = frac; // 0..1
      isFadingOut = false;
      // Reserve width for what remains in the end string after the fading grapheme.
      ghostSuffixG = endSuffix.skip(added + 1).toList();
    } else {
      ghostSuffixG = endSuffix
          .skip(added)
          .toList(); // alpha=0 keeps final width stable at the tail end
    }
  } else if (t == 0.5 && endSuffix.isNotEmpty) {
    // Middle: nothing committed beyond prefix; show first end grapheme at 0 opacity.
    fadingChar = endSuffix.first;
    fadeOpacity = 0.0;
    isFadingOut = false;
    ghostSuffixG = endSuffix.skip(1).toList();
  }

  String? takeNextGhostGrapheme() {
    if (ghostSuffixG.isEmpty) {
      return null;
    }
    final next = ghostSuffixG.first;
    ghostSuffixG = ghostSuffixG.sublist(1);
    return next;
  }

  // If the fading char is whitespace, commit it immediately but continue fading
  // the next grapheme so animation time isn't lost to invisible characters.
  while (fadingChar != null && fadingChar.trim().isEmpty) {
    committed += fadingChar;
    final replacement = takeNextGhostGrapheme();
    if (replacement == null) {
      fadingChar = null;
      fadeOpacity = 0.0;
      break;
    }
    fadingChar = replacement;
  }

  return LerpStringResult(
    text: committed,
    fadingChar: fadingChar,
    fadeOpacity: fadeOpacity.clamp(0.0, 1.0),
    isFadingOut: isFadingOut,
    ghostSuffix: ghostSuffixG.join(),
  );
}

String lerpString(String start, String end, double t) =>
    lerpStringWithFade(start, end, t).text;
