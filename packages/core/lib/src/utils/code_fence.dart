final _codeFenceLinePattern = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');

/// Returns fence marker details for markdown code-fence-like lines.
///
/// Supports both backtick (```) and tilde (~~~) fences with at least 3
/// characters, including up to 3 leading spaces.
({String marker, String rest})? parseCodeFenceLine(String line) {
  final match = _codeFenceLinePattern.firstMatch(line);
  if (match == null) return null;

  return (marker: match.group(1)!, rest: match.group(2) ?? '');
}

/// Returns true if a fence line can close a currently opened block.
bool canCloseCodeFence({
  required String marker,
  required int minLength,
  required String line,
}) {
  final fenceLine = parseCodeFenceLine(line);
  if (fenceLine == null) return false;

  final closingMarker = fenceLine.marker;
  if (closingMarker[0] != marker[0]) return false;
  if (fenceLine.rest.trim().isNotEmpty) return false;

  return closingMarker.length >= minLength;
}
