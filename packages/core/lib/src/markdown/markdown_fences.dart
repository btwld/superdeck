/// Parse-phase fenced code blocks.
///
/// SuperDeck hides structural syntax (`---` slide splits and `@` directives)
/// inside fenced code. Slide-split, directive tokenization, and serialize-escape
/// must all call [fencedCodeRanges] so they cannot drift.
///
/// A fence opens on a line that, after optional leading whitespace, starts
/// with three or more backticks or tildes. A backtick opener cannot contain
/// more backticks in its info string (so ` ```dart {.hero}` opens and
/// ` ``` `` ` does not). A closer is a later line whose marker uses the same
/// character and is at least as long — SuperDeck decks close fences with
/// ` ```{.code}` (an info string on the closer), so info does not block a
/// close. An unclosed fence extends to the end of the text.
List<({int start, int end})> fencedCodeRanges(String text) {
  final ranges = <({int start, int end})>[];
  String? openChar;
  var openLength = 0;
  var openStart = 0;

  _forEachLine(text, (start, end, next, line) {
    final fence = _readFenceLine(line);
    if (openChar == null) {
      if (fence != null && fence.canOpen) {
        openChar = fence.character;
        openLength = fence.length;
        openStart = start;
      }
      return;
    }

    if (fence != null &&
        fence.character == openChar &&
        fence.length >= openLength) {
      ranges.add((start: openStart, end: next));
      openChar = null;
    }
  });

  if (openChar != null) {
    ranges.add((start: openStart, end: text.length));
  }

  return ranges;
}

/// Whether [offset] sits inside one of [ranges] (`start <= offset < end`).
bool isInsideFencedCode(int offset, List<({int start, int end})> ranges) {
  for (final range in ranges) {
    if (offset >= range.start && offset < range.end) return true;
  }
  return false;
}

void _forEachLine(
  String text,
  void Function(int start, int end, int next, String line) visit,
) {
  var i = 0;
  while (i < text.length) {
    final start = i;
    while (i < text.length) {
      final unit = text.codeUnitAt(i);
      if (unit == 0x0A || unit == 0x0D) break;
      i++;
    }
    final end = i;
    if (i < text.length) {
      if (text.codeUnitAt(i) == 0x0D &&
          i + 1 < text.length &&
          text.codeUnitAt(i + 1) == 0x0A) {
        i += 2;
      } else {
        i += 1;
      }
    }
    visit(start, end, i, text.substring(start, end));
  }
}

({String character, int length, bool canOpen})? _readFenceLine(String line) {
  var i = 0;
  while (i < line.length) {
    final unit = line.codeUnitAt(i);
    if (unit != 0x20 && unit != 0x09) break;
    i++;
  }
  if (i >= line.length) return null;

  final markerUnit = line.codeUnitAt(i);
  if (markerUnit != 0x60 && markerUnit != 0x7E) return null;

  var length = 0;
  while (i < line.length && line.codeUnitAt(i) == markerUnit) {
    length++;
    i++;
  }
  if (length < 3) return null;

  final info = line.substring(i);
  final character = String.fromCharCode(markerUnit);
  final canOpen = character == '~' || !info.contains('`');

  return (character: character, length: length, canOpen: canOpen);
}
