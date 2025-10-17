import 'package:markdown/markdown.dart' as md;

/// Utilities for parsing `{.hero}` style class markers that drive SuperDeck
/// hero animations. The helpers centralize the logic so both the core parser
/// and the Flutter renderer stay in sync.
///
/// Hero tags follow a constrained subset of CSS class rules:
/// - Optional leading single hyphen.
/// - Otherwise must start with a letter or underscore.
/// - Remaining characters may be letters, digits, underscores, or hyphens.
/// - Identifiers starting with `--` are rejected (CSS custom properties).

/// Strips a trailing hero marker from [content].
///
/// Returns a record containing:
/// - `text`: the original text with the marker removed and trailing
///   whitespace trimmed.
/// - `hero`: the first valid hero tag found, or `null` if none.
({String text, String? hero}) stripTrailingHeroMarker(String content) {
  final match = heroTrailingPattern.firstMatch(content);
  if (match == null) {
    return (text: content, hero: null);
  }

  final classes = match.group(1) ?? '';
  final hero = _extractFirstHero(classes);
  final cleanText = content.substring(0, match.start).trimRight();

  return (text: cleanText, hero: hero);
}

/// Scans [source] starting at [start] for a leading hero marker (`{.tag}`).
///
/// Returns a record containing the detected [hero] (or `null` if none) and the
/// total [length] of the slice that should be consumed from the parser when a
/// hero is found. The consumed length includes surrounding whitespace so no
/// extra cleanup is required by callers.
({String? hero, int length}) scanLeadingHeroMarker(String source, int start) {
  final totalLength = source.length;
  var pos = start;

  while (pos < totalLength) {
    final ch = source.codeUnitAt(pos);
    if (ch == 0x20 || ch == 0x09) {
      pos++;
      continue;
    }
    break;
  }

  if (pos >= totalLength || source.codeUnitAt(pos) != 0x7B /* { */ ) {
    return (hero: null, length: 0);
  }

  final braceStart = pos;
  pos++; // Skip '{'

  while (pos < totalLength && source.codeUnitAt(pos) != 0x7D /* } */ ) {
    pos++;
  }

  if (pos >= totalLength) {
    return (hero: null, length: 0);
  }

  final braceEnd = pos + 1; // include '}'
  final hero = _extractFirstHero(
    source.substring(braceStart + 1, braceEnd - 1),
  );
  if (hero == null) {
    return (hero: null, length: 0);
  }

  pos = braceEnd;
  while (pos < totalLength) {
    final ch = source.codeUnitAt(pos);
    if (ch == 0x20 || ch == 0x09) {
      pos++;
    } else {
      break;
    }
  }

  return (hero: hero, length: pos - start);
}

/// Consumes a leading hero marker (`{.tag}`) from the inline [parser].
///
/// If a valid hero tag is found the parser is advanced past the marker and the
/// tag value is returned. Otherwise `null` is returned and the parser position
/// is left untouched.
String? consumeLeadingHeroMarker(md.InlineParser parser) {
  final (:hero, :length) = scanLeadingHeroMarker(parser.source, parser.pos);
  if (hero == null || length == 0) {
    return null;
  }

  parser.consume(length);
  parser.start = parser.pos;

  return hero;
}

/// Consumes a hero marker that may follow an inline node such as an image.
///
/// PARSER POSITION MANAGEMENT:
/// This function is called from InlineSyntax.close(), which is called by the
/// markdown parser when the closing ']' of link/image text is matched.
///
/// After close() returns, the parent InlineParser unconditionally calls
/// advanceBy(1) to skip the ']' character. To prevent buffer overflow when
/// hero markers appear at the end of the input string:
/// 1. We consume the delimiter + hero marker
/// 2. We rewind by 1 position
/// 3. Parent's advanceBy(1) moves us to the correct final position
///
/// Returns the hero tag if found, null otherwise. If null, parser position
/// is restored to its original state.
String? consumeTrailingHeroForInlineNode(md.InlineParser parser) {
  final originalPos = parser.pos;
  final originalStart = parser.start;

  if (parser.pos < parser.source.length) {
    final current = parser.source.codeUnitAt(parser.pos);
    if (current == 0x29 /* ) */ || current == 0x5D /* ] */ ) {
      parser.advanceBy(1);
    }
  }

  final marker = scanLeadingHeroMarker(parser.source, parser.pos);
  final hero = marker.hero;
  final length = marker.length;

  if (hero == null || length == 0) {
    parser.pos = originalPos;
    parser.start = originalStart;
    return null;
  }

  // Consume the hero marker
  parser.consume(length);

  // CRITICAL FIX: Rewind by 1 because parent InlineParser will call advanceBy(1)
  // to skip the closing ']' bracket. Without this, parser position goes out of bounds
  // when hero markers appear at the end of the input string.
  parser.advanceBy(-1);

  // Update start to current position
  parser.start = parser.pos;

  return hero;
}

/// Extracts the first hero identifier from a fenced code block line.
///
/// Example: `````dart {.hero}```` → `hero`.
String? extractHeroFromFenceInfo(String line) {
  final match = heroFenceInfoPattern.firstMatch(line.trimRight());
  if (match == null) {
    return null;
  }

  final info = (match.group(2) ?? '').trim();
  final braceMatch = heroBracesPattern.firstMatch(info);
  if (braceMatch == null) {
    return null;
  }

  return _extractFirstHero(braceMatch.group(1) ?? '');
}

/// Extracts the first valid hero tag from arbitrary [text], stripping any
/// `{.tag}` segments from the returned content. Used for plain text nodes.
({String? tag, String content}) extractHeroAndContent(String text) {
  final trimmed = text.trim();
  final match = heroAnywherePattern.firstMatch(trimmed);
  final extractedTag = match?.group(1)?.trim();
  final tag = (extractedTag != null && isValidHeroTag(extractedTag))
      ? extractedTag
      : null;

  var content = trimmed.replaceAll(heroAnyBracePattern, '').trim();
  content = content.replaceAll('```', '');

  return (tag: tag, content: content);
}

/// Returns `true` when [value] is safe to use as a hero tag identifier.
bool isValidHeroTag(String value) =>
    value.isNotEmpty &&
    !value.startsWith('--') &&
    heroValidIdentifierPattern.hasMatch(value);

/// Returns the first valid hero tag present in [classList], or `null` if none.
String? firstHeroTagInClassList(String classList) =>
    _extractFirstHero(classList);

// Classes that should be ignored as hero tags
const Set<String> _ignoredHeroClasses = {'no-select'};

String? _extractFirstHero(String classList) {
  final candidates = classList
      .split(RegExp(r'\s+'))
      .map((token) => token.startsWith('.') ? token.substring(1) : token)
      .where((token) => token.isNotEmpty);

  for (final candidate in candidates) {
    if (_ignoredHeroClasses.contains(candidate)) {
      continue;
    }
    if (isValidHeroTag(candidate)) {
      return candidate;
    }
  }
  return null;
}

/// Matches `{.class}` markers at the end of a line.
final RegExp heroTrailingPattern = RegExp(
  r'\{\s*((?:\.[^\s}]+(?:\s+\.[^\s}]+)*)?)\s*\}\s*$',
);

/// Matches `{.class}` markers at the start of a string.
final RegExp heroLeadingPattern = RegExp(
  r'^\s*\{\s*((?:\.[^\s}]+(?:\s+\.[^\s}]+)*)?)\s*\}',
);

/// Matches fence opener with optional info string.
final RegExp heroFenceInfoPattern = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');

/// Matches content inside braces.
final RegExp heroBracesPattern = RegExp(r'\{([^}]*)\}');

/// Matches `{.class}` anywhere in a string.
final RegExp heroAnywherePattern = RegExp(
  r'{\.([_a-zA-Z][_a-zA-Z0-9-]*)}',
  multiLine: true,
);

/// Matches `{.anything}` for removal.
final RegExp heroAnyBracePattern = RegExp(r'\{\.[^}]*\}', multiLine: true);

/// Valid CSS identifier subset used for hero tags.
final RegExp heroValidIdentifierPattern = RegExp(
  r'^-?[_a-zA-Z][_a-zA-Z0-9-]*$',
);
